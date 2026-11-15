import 'package:postgres/postgres.dart' as pg;
import 'package:shared/erros/codigo_erro.dart';

import '../../database/database.dart' show AgendamentoData, AulaData;
import '../../shared/autorizacao/identidade.dart';
import '../../shared/erros/agendamento_exception.dart';
import '../../shared/erros/tradutor_erro_banco.dart';
import '../aulas/aula_service.dart' show exigirAnoDeVigencia;
import 'agendamento_repository.dart';

/// Regras de agendamento: so o aluno reserva e cancela a propria vaga,
/// com janela de 2 horas, lotacao, duplicidade e vigencia.
///
/// Data passada, janela de 2 horas, ano de vigencia e dia civil saem do
/// Postgres (`America/Sao_Paulo`, na mesma consulta que le a aula). O Dart
/// nao converte fuso para essas regras.
class AgendamentoService {
  /// Antecedencia minima, em ambos os sentidos. A regra roda no SQL
  /// (`agendamento_repository.dart`, `_colunasDeRegra`); esta constante e a
  /// referencia dela, usada pelos testes.
  static const Duration antecedenciaMinima = Duration(hours: 2);

  final AgendamentoRepository _repository;

  final DateTime Function() _agora;

  AgendamentoService(this._repository, {DateTime Function()? agora})
    : _agora = agora ?? DateTime.now;

  /// Reserva a vaga. Ordem das checagens (codigos aprovados, nao mudar):
  /// aula inexistente -> inativa -> data passada -> vigencia -> janela ->
  /// duplicidade -> lotacao.
  ///
  /// As regras que nao dependem de vaga rodam ANTES da trava: leitura
  /// simples, sem FOR UPDATE. Quem falha ali nao segura a aula. A trava
  /// (FOR UPDATE) so cobre duplicidade, lotacao e insert. Como a aula pode
  /// mudar enquanto o pedido espera a trava, as regras de aula sao checadas
  /// de novo com a linha travada e o relogio do momento da decisao.
  Future<AgendamentoData> reservar({
    required Identidade identidade,
    required int idAula,
  }) async {
    _exigirAluno(identidade);

    return _repository.transacao(() async {
      final previa = await _repository.buscarAula(idAula);
      if (previa == null) {
        throw const AgendamentoNotFoundException('Aula nao encontrada.');
      }
      _exigirRegrasDaAula(previa.aula, previa.regras);

      final situacao = await _repository.travarSituacaoParaReserva(
        idAula,
        identidade.id,
      );
      if (situacao == null) {
        throw const AgendamentoNotFoundException('Aula nao encontrada.');
      }
      final aula = situacao.aula;
      _exigirRegrasDaAula(aula, situacao.regras);

      // Antes da lotacao: quem ja tem vaga recebe DUPLICADO, nao SEM_VAGAS.
      // Duplicidade e lotacao vem da mesma leitura travada (uma ida).
      final existenteId = situacao.idAgendamentoExistente;
      if (existenteId != null && situacao.statusExistente != 'cancelado') {
        throw const AgendamentoConflictException(
          CodigoErro.agendamentoDuplicado,
        );
      }

      if (situacao.ocupadas >= aula.vagasMaxima) {
        throw const AgendamentoConflictException(CodigoErro.aulaSemVagas);
      }

      final hoje = situacao.regras.hoje;

      // Corrida: a leitura travada pode estar um commit atras. Trigger
      // (GF001, GF002) e unique (uq_agendamento_aluno_aula) decidem com
      // snapshot novo; o codigo sai do tradutor unico, igual a checagem
      // antecipada.
      try {
        if (existenteId != null) {
          return await _repository.reativar(existenteId, dataAgendamento: hoje);
        }
        return await _repository.inserir(
          idAluno: identidade.id,
          idAula: idAula,
          dataAgendamento: hoje,
        );
      } on pg.ServerException catch (e) {
        final codigo = traduzirErroBanco(e);
        if (codigo == null) rethrow;
        throw AgendamentoConflictException(codigo);
      }
    });
  }

  /// Regras de aula que nao dependem de vaga, na ordem aprovada:
  /// inativa -> data passada -> vigencia -> janela. Data passada, ano e
  /// janela vem do Postgres (`regras`), calculados com o fuso de Brasilia.
  void _exigirRegrasDaAula(AulaData aula, RegrasDeTempo regras) {
    if (!aula.status) {
      throw const AgendamentoConflictException(CodigoErro.aulaInativa);
    }
    if (regras.dataPassada) {
      throw const AgendamentoConflictException(CodigoErro.aulaDataPassada);
    }
    // exigirAnoDeVigencia le so `.year`: DateTime.utc(ano) nao converte fuso.
    exigirAnoDeVigencia(aula.data.year, DateTime.utc(regras.anoHoje));
    _exigirAntecedencia(regras);
  }

  /// So o proprio aluno. Ja cancelado devolve o estado atual, sem erro.
  ///
  /// Agendamento de outro aluno responde igual a id inexistente (404, mesma
  /// mensagem): a resposta nao revela que o id existe.
  Future<AgendamentoData> cancelar({
    required Identidade identidade,
    required int idAgendamento,
  }) async {
    _exigirAluno(identidade);

    // Dono checado sem trava: outro aluno nao segura o FOR UPDATE da linha.
    final dono = await _repository.buscarSemTrava(idAgendamento);
    if (dono == null || dono.idAluno != identidade.id) {
      throw const AgendamentoNotFoundException('Agendamento nao encontrado.');
    }

    return _repository.transacao(() async {
      final atual = await _repository.buscarParaAtualizar(idAgendamento);
      if (atual == null || atual.idAluno != identidade.id) {
        throw const AgendamentoNotFoundException('Agendamento nao encontrado.');
      }
      if (atual.status == 'cancelado') return atual;

      final aula = await _repository.buscarAula(atual.idAula);
      if (aula == null) {
        throw const AgendamentoNotFoundException('Aula nao encontrada.');
      }
      _exigirAntecedencia(aula.regras);

      return _repository.cancelar(idAgendamento, agora: _agoraUtc());
    });
  }

  /// Lista so os proprios agendamentos.
  Future<({List<AgendamentoData> itens, int total})> listarDoAluno(
    Identidade identidade, {
    required int limit,
    required int offset,
  }) async {
    _exigirAluno(identidade);

    final itens = await _repository.listarDoAluno(
      idAluno: identidade.id,
      limit: limit,
      offset: offset,
    );
    final total = await _repository.contarDoAluno(identidade.id);
    return (itens: itens, total: total);
  }

  /// Professor e admin nao operam agendamento.
  void _exigirAluno(Identidade identidade) {
    if (identidade.papel != Papel.aluno) throw const AcessoNegado();
  }

  /// Instante do evento (`data_cancelamento`). Nao entra em regra: as regras
  /// de tempo vem do Postgres.
  DateTime _agoraUtc() => _agora().toUtc();

  /// Bloqueia quando faltam menos de 2 horas para o inicio da aula, ou ela ja
  /// comecou. O calculo e do Postgres (`dentroDaJanela`).
  void _exigirAntecedencia(RegrasDeTempo regras) {
    if (regras.dentroDaJanela) {
      throw const AgendamentoConflictException(
        CodigoErro.agendamentoForaDaJanela,
      );
    }
  }
}
