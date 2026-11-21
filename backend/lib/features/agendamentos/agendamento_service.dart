import 'package:postgres/postgres.dart' as pg;
import 'package:shared/erros/codigo_erro.dart';

import '../../database/database.dart' show AgendamentoData, AulaData;
import '../../shared/autorizacao/identidade.dart';
import '../../shared/erros/agendamento_exception.dart';
import '../../shared/erros/aula_exception.dart';
import '../../shared/erros/tradutor_erro_banco.dart';
import '../aulas/aula_service.dart'
    show CancelamentoDeAgendamentos, exigirAnoDeVigencia;
import 'agendamento_repository.dart';

/// Um item da chamada: o agendamento e a presenca pedida.
class PresencaInformada {
  final int idAgendamento;
  final bool presente;

  const PresencaInformada({required this.idAgendamento, required this.presente});
}

/// Regras de agendamento: so o aluno reserva e cancela a propria vaga,
/// com janela de 2 horas, lotacao, duplicidade e vigencia.
///
/// Data passada, janela de 2 horas, ano de vigencia e dia civil saem do
/// Postgres (`America/Sao_Paulo`, na mesma consulta que le a aula). O Dart
/// nao converte fuso para essas regras.
class AgendamentoService implements CancelamentoDeAgendamentos {
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
      // e unique (uq_agendamento_aluno_aula) decidem com
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

  /// So o `AulaService.cancelar` chama, ja autorizado e dentro da transacao
  /// do cancelamento da aula; por isso nao checa perfil nem abre transacao.
  @override
  Future<int> cancelarEmCascata(int idAula, {required DateTime agora}) =>
      _repository.cancelarAgendadosDaAula(idAula, agora: agora);

  /// Presenca da aula: professor da aula ou admin; aluno nunca.
  ///
  /// Professor que nao e o da aula recebe 404, igual a aula inexistente.
  ///
  /// Primeiro envio (nenhum agendamento da aula com `presente` ou `faltou`):
  /// a lista traz todos os agendamentos ativos da aula. Depois, so os itens
  /// alterados. Tudo ou nada, na transacao com a aula travada.
  Future<List<AgendamentoData>> registrarChamada({
    required Identidade identidade,
    required int idAula,
    required List<PresencaInformada> itens,
  }) async {
    if (identidade.papel == Papel.aluno) throw const AcessoNegado();
    if (itens.isEmpty) {
      throw const ChamadaException(
        CodigoErro.campoInvalido,
        campo: 'corpo',
        mensagem: 'Informe ao menos um agendamento.',
      );
    }
    final vistos = <int>{};
    for (final item in itens) {
      if (!vistos.add(item.idAgendamento)) {
        throw const ChamadaException(
          CodigoErro.campoInvalido,
          campo: 'id',
          mensagem: 'Agendamento repetido na lista.',
        );
      }
    }

    return _repository.transacao(() async {
      // Leitura sem trava: quem nao pode chamar nao segura o FOR UPDATE da aula.
      final previa = await _repository.buscarAula(idAula);
      if (previa == null) throw const AulaNotFoundException();
      _exigirDonoOuAdmin(identidade, previa.aula);

      final aulaTravada = await _repository.travarAulaParaChamada(idAula);
      if (aulaTravada == null) throw const AulaNotFoundException();
      final aula = aulaTravada.aula;
      // Reconfere com a linha travada: o professor pode ter mudado enquanto
      // o pedido esperava a trava.
      _exigirDonoOuAdmin(identidade, aula);
      if (!aula.status) {
        throw const ChamadaException(
          CodigoErro.aulaInativa,
          mensagem: 'Aula cancelada nao aceita chamada.',
        );
      }
      if (aulaTravada.antesDoInicio) {
        throw const ChamadaException(
          CodigoErro.agendamentoForaDaJanela,
          mensagem: 'Chamada so pode ser feita a partir do inicio da aula.',
        );
      }

      final agendamentos = await _repository.travarAgendamentosDaAula(idAula);
      final porId = {for (final a in agendamentos) a.idAgendamento: a};
      final primeiroEnvio = !agendamentos.any(
        (a) => a.status == 'presente' || a.status == 'faltou',
      );

      for (final item in itens) {
        if (porId.containsKey(item.idAgendamento)) continue;
        if (primeiroEnvio) {
          throw const ChamadaException(
            CodigoErro.campoInvalido,
            campo: 'id',
            mensagem: 'Agendamento nao pertence a esta aula.',
          );
        }
        throw const AgendamentoNotFoundException('Agendamento nao encontrado.');
      }

      for (final item in itens) {
        if (porId[item.idAgendamento]!.status == 'cancelado') {
          throw const ChamadaException(
            CodigoErro.registroEmUso,
            campo: 'id',
            mensagem: 'Agendamento cancelado nao aceita alteracao de presenca.',
          );
        }
      }

      if (primeiroEnvio) {
        final enviados = {for (final item in itens) item.idAgendamento};
        final faltando = agendamentos.any(
          (a) => a.status == 'agendado' && !enviados.contains(a.idAgendamento),
        );
        if (faltando) {
          throw const ChamadaException(
            CodigoErro.registroEmUso,
            campo: 'id',
            mensagem:
                'Lista incompleta: envie todos os agendamentos ativos da aula.',
          );
        }
      }

      final presentes = [
        for (final item in itens)
          if (item.presente && porId[item.idAgendamento]!.status != 'presente')
            item.idAgendamento,
      ];
      final faltaram = [
        for (final item in itens)
          if (!item.presente && porId[item.idAgendamento]!.status != 'faltou')
            item.idAgendamento,
      ];
      final gravadas = await _repository.gravarPresenca(
        presentes: presentes,
        faltaram: faltaram,
        agora: _agoraUtc(),
      );
      final porGravada = {for (final g in gravadas) g.idAgendamento: g};
      return [
        for (final item in itens)
          porGravada[item.idAgendamento] ?? porId[item.idAgendamento]!,
      ];
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

  /// Admin chama qualquer aula. Professor so a propria; outra aula responde
  /// como inexistente (404), para nao revelar quais aulas existem.
  void _exigirDonoOuAdmin(Identidade identidade, AulaData aula) {
    if (identidade.papel == Papel.admin) return;
    if (identidade.papel == Papel.professor && aula.idProfessor == identidade.id) {
      return;
    }
    throw const AulaNotFoundException();
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
