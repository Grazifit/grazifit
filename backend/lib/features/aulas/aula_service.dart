import 'package:drift_postgres/drift_postgres.dart' show PgDate;
import 'package:postgres/postgres.dart' as pg;
import 'package:shared/dtos/aula_serializer.dart';
import 'package:shared/erros/codigo_erro.dart';

import '../../database/database.dart' show AulaData;
import '../../shared/autorizacao/identidade.dart';
import '../../shared/erros/aula_exception.dart';
import 'aula_repository.dart';

/// Regra de vigencia de data: aceita o ano corrente e o seguinte. Unica
/// fonte; aula e agendamento usam esta mesma funcao.
void exigirAnoDeVigencia(int ano, DateTime agora) {
  final atual = agora.year;
  if (ano != atual && ano != atual + 1) {
    throw const AulaValidationException(CodigoErro.campoInvalido, campo: 'data');
  }
}

/// O que o cancelamento da aula precisa da feature de agendamento.
/// Declarada aqui porque o agendamento ja importa a aula; quem implementa e
/// o `AgendamentoService`.
abstract interface class CancelamentoDeAgendamentos {
  /// Cancela os `agendado` da aula com [agora]; devolve quantos mudaram.
  Future<int> cancelarEmCascata(int idAula, {required DateTime agora});
}

/// Regras e permissoes de aula: criar (admin), ler (todos), atualizar,
/// cancelar e ver os agendados (admin; professor so nas proprias).
class AulaService {
  final AulaRepository _repository;

  final CancelamentoDeAgendamentos _agendamentos;

  final DateTime Function() _agora;

  AulaService(
    this._repository,
    this._agendamentos, {
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now;

  Future<AulaData> criar({
    required Identidade identidade,
    required int idProfessor,
    required DateTime data,
    required Duration horaInicio,
    required Duration horaFim,
    required String tipo,
    required String categoria,
    required int vagasMaxima,
  }) async {
    exigirAdmin(identidade);

    _exigirAnoDeVigencia(data.year);
    final dia = _diaCivil(data);
    _exigirForaDoPassado(
      mudaData: true,
      mudaInicio: true,
      mudaFim: false,
      dataFinal: dia,
      inicioFinal: horaInicio,
      fimFinal: horaFim,
    );
    _validarAula(
      tipo: tipo,
      categoria: categoria,
      horaInicio: horaInicio,
      horaFim: horaFim,
      vagasMaxima: vagasMaxima,
      deCronograma: false,
    );
    await _exigirProfessorAtivo(idProfessor);

    return _repository.create(
      idAdminCriador: identidade.id,
      idProfessor: idProfessor,
      data: dia,
      horaInicio: _paraTime(horaInicio),
      horaFim: _paraTime(horaFim),
      tipo: tipo,
      categoria: categoria,
      vagasMaxima: vagasMaxima,
    );
  }

  Future<AulaData> buscarPorId(Identidade identidade, int idAula) async {
    final aula = await _repository.buscarPorId(idAula);
    if (aula == null) throw const AulaNotFoundException();
    return aula;
  }

  Future<({List<AulaData> itens, int total})> listar(
    Identidade identidade, {
    required int limit,
    required int offset,
    DateTime? data,
    String? categoria,
    int? idProfessor,
  }) async {
    if (categoria != null && !categoriasAula.contains(categoria)) {
      throw const AulaValidationException(
        CodigoErro.campoInvalido,
        campo: 'categoria',
      );
    }
    final dia = data == null ? null : PgDate.fromDateTime(data);

    final itens = await _repository.listar(
      limit: limit,
      offset: offset,
      data: dia,
      categoria: categoria,
      idProfessor: idProfessor,
    );
    final total = await _repository.contar(
      data: dia,
      categoria: categoria,
      idProfessor: idProfessor,
    );
    return (itens: itens, total: total);
  }

  /// Vagas ocupadas por aula; aula sem ocupacao vem com 0. A leitura da
  /// aula e livre para todos os perfis, e a ocupacao segue a mesma regra.
  Future<Map<int, int>> vagasOcupadas(
    Identidade identidade,
    List<int> idsAulas,
  ) async {
    final contagem = await _repository.contarOcupadasPorAula(idsAulas);
    return {for (final id in idsAulas) id: contagem[id] ?? 0};
  }

  /// Agendados da aula (sem os cancelados). Admin em qualquer aula;
  /// professor so na propria; aluno nunca.
  Future<({List<AgendadoDaAula> itens, int total})> listarAgendados(
    Identidade identidade,
    int idAula, {
    required int limit,
    required int offset,
  }) async {
    if (identidade.papel == Papel.aluno) throw const AcessoNegado();

    final aula = await _repository.buscarPorId(idAula);
    if (aula == null) throw const AulaNotFoundException();
    if (identidade.papel == Papel.professor &&
        aula.idProfessor != identidade.id) {
      throw const AcessoNegado();
    }

    final itens = await _repository.listarAgendados(
      idAula,
      limit: limit,
      offset: offset,
    );
    final total = await _repository.contarAgendados(idAula);
    return (itens: itens, total: total);
  }

  /// Campo nulo = nao alterar. Roda com a aula travada para nenhum
  /// agendamento entrar durante a edicao.
  Future<AulaData> atualizar({
    required Identidade identidade,
    required int idAula,
    int? idProfessor,
    DateTime? data,
    Duration? horaInicio,
    Duration? horaFim,
    String? tipo,
    String? categoria,
    int? vagasMaxima,
  }) async {
    if (identidade.papel == Papel.aluno) throw const AcessoNegado();

    return _repository.transacao(() async {
      final atual = await _repository.buscarParaAtualizar(idAula);
      if (atual == null) throw const AulaNotFoundException();

      if (!atual.status) {
        throw const AulaConflictException(CodigoErro.aulaInativa);
      }

      final novaData = data == null ? null : _diaCivil(data);

      // So conta como alteracao o que difere do valor atual.
      final mudaProfessor =
          idProfessor != null && idProfessor != atual.idProfessor;
      final mudaData = novaData != null && novaData != atual.data;
      final mudaInicio =
          horaInicio != null && horaInicio != _paraDuration(atual.horaInicio);
      final mudaFim =
          horaFim != null && horaFim != _paraDuration(atual.horaFim);

      if (identidade.papel == Papel.professor) {
        _exigirRegrasDoProfessor(
          identidade,
          atual,
          mudaProfessor: mudaProfessor,
        );
      }

      // Apos a autorizacao, para quem nao pode editar receber sempre 403.
      _exigirForaDoPassado(
        mudaData: mudaData,
        mudaInicio: mudaInicio,
        mudaFim: mudaFim,
        dataFinal: novaData ?? atual.data,
        inicioFinal: horaInicio ?? _paraDuration(atual.horaInicio),
        fimFinal: horaFim ?? _paraDuration(atual.horaFim),
      );
      if (mudaData) _exigirAnoDeVigencia(novaData.year);

      // Valida a combinacao final, nao so os campos enviados.
      _validarAula(
        tipo: tipo ?? atual.tipo,
        categoria: categoria ?? atual.categoria,
        horaInicio: horaInicio ?? _paraDuration(atual.horaInicio),
        horaFim: horaFim ?? _paraDuration(atual.horaFim),
        vagasMaxima: vagasMaxima ?? atual.vagasMaxima,
        deCronograma: atual.idCronograma != null,
      );

      if (mudaProfessor) await _exigirProfessorAtivo(idProfessor);

      final mudaHorario = mudaProfessor || mudaData || mudaInicio || mudaFim;
      final reduzVagas = vagasMaxima != null && vagasMaxima < atual.vagasMaxima;
      if (mudaHorario || reduzVagas) {
        await _exigirCompativelComAgendamentos(
          atual.idAula,
          mudaProfessor: mudaProfessor,
          mudaData: mudaData,
          mudaInicio: mudaInicio,
          mudaFim: mudaFim,
          vagasMaxima: reduzVagas ? vagasMaxima : null,
        );
      }

      final atualizada = await _repository.atualizar(
        idAula,
        idProfessor: mudaProfessor ? idProfessor : null,
        data: mudaData ? novaData : null,
        horaInicio: mudaInicio ? _paraTime(horaInicio) : null,
        horaFim: mudaFim ? _paraTime(horaFim) : null,
        tipo: tipo,
        categoria: categoria,
        vagasMaxima: vagasMaxima,
      );
      if (atualizada == null) throw const AulaNotFoundException();
      return atualizada;
    });
  }

  /// Admin em qualquer aula; professor so na propria. Na mesma transacao,
  /// os agendamentos `agendado` sao cancelados com o mesmo instante. Aula
  /// ja cancelada devolve o estado atual; aula realizada nao cancela.
  Future<AulaData> cancelar({
    required Identidade identidade,
    required int idAula,
  }) async {
    if (identidade.papel == Papel.aluno) throw const AcessoNegado();

    return _repository.transacao(() async {
      final atual = await _repository.buscarParaAtualizar(idAula);
      if (atual == null) throw const AulaNotFoundException();

      if (identidade.papel == Papel.professor &&
          atual.idProfessor != identidade.id) {
        throw const AcessoNegado();
      }

      if (!atual.status) return atual;

      if (_jaRealizada(atual)) {
        throw const AulaConflictException(CodigoErro.aulaDataPassada);
      }

      final instante = _agora().toUtc();
      final porAdmin = identidade.papel == Papel.admin;
      final cancelada = await _repository.cancelar(
        idAula,
        agora: instante,
        idAdminCancelou: porAdmin ? identidade.id : null,
        idProfessorCancelou: porAdmin ? null : identidade.id,
      );
      await _agendamentos.cancelarEmCascata(idAula, agora: instante);
      return cancelada;
    });
  }

  void _validarAula({
    required String tipo,
    required String categoria,
    required Duration horaInicio,
    required Duration horaFim,
    required int vagasMaxima,
    required bool deCronograma,
  }) {
    if (!tiposAula.contains(tipo)) _invalido('tipo');
    if (deCronograma && tipo != 'coletiva') _invalido('tipo');
    if (!categoriasAula.contains(categoria)) _invalido('categoria');

    if (!_horaValida(horaInicio)) _invalido('hora_inicio');
    if (!_horaValida(horaFim)) _invalido('hora_fim');
    if (horaFim <= horaInicio) _invalido('hora_fim');

    if (vagasMaxima <= 0 || vagasMaxima > _vagasMaximaLimite) {
      _invalido('vagas_maxima');
    }
    if (tipo == 'individual' && vagasMaxima > 3) _invalido('vagas_maxima');
  }

  /// Limite do INT do banco.
  static const int _vagasMaximaLimite = 2147483647;

  void _exigirAnoDeVigencia(int ano) => exigirAnoDeVigencia(ano, _agora());

  /// Professor: so a propria aula, ainda nao realizada, sem trocar o
  /// professor.
  void _exigirRegrasDoProfessor(
    Identidade identidade,
    AulaData atual, {
    required bool mudaProfessor,
  }) {
    if (atual.idProfessor != identidade.id) throw const AcessoNegado();
    if (_jaRealizada(atual)) throw const AcessoNegado();
    if (mudaProfessor) throw const AcessoNegado();
  }

  /// Admin e professor: data e horario alterados nao podem cair no passado.
  /// "Exatamente agora" conta como passado.
  void _exigirForaDoPassado({
    required bool mudaData,
    required bool mudaInicio,
    required bool mudaFim,
    required PgDate dataFinal,
    required Duration inicioFinal,
    required Duration fimFinal,
  }) {
    if (mudaData && _diaCivil(dataFinal.toDateTime()).compareTo(_hoje()) < 0) {
      _invalido('data');
    }

    final agora = _agora();
    if ((mudaData || mudaInicio) &&
        !_momento(dataFinal, inicioFinal).isAfter(agora)) {
      _invalido(mudaInicio ? 'hora_inicio' : 'data');
    }
    if (mudaFim && !_momento(dataFinal, fimFinal).isAfter(agora)) {
      _invalido('hora_fim');
    }
  }

  /// Com agendamento ativo, data/hora/professor ficam travados e as vagas
  /// nao descem abaixo da ocupacao.
  Future<void> _exigirCompativelComAgendamentos(
    int idAula, {
    required bool mudaProfessor,
    required bool mudaData,
    required bool mudaInicio,
    required bool mudaFim,
    required int? vagasMaxima,
  }) async {
    final ocupadas = await _repository.contarAgendamentosAtivos(idAula);
    if (ocupadas == 0) return;

    final campoTravado = {
      'data': mudaData,
      'hora_inicio': mudaInicio,
      'hora_fim': mudaFim,
      'id_professor': mudaProfessor,
    }.entries.where((e) => e.value).map((e) => e.key).firstOrNull;
    if (campoTravado != null) {
      throw AulaConflictException(
        CodigoErro.registroEmUso,
        campo: campoTravado,
      );
    }
    if (vagasMaxima != null && vagasMaxima < ocupadas) {
      throw const AulaConflictException(
        CodigoErro.registroEmUso,
        campo: 'vagas_maxima',
      );
    }
  }

  Future<void> _exigirProfessorAtivo(int idProfessor) async {
    if (!await _repository.professorAtivoExiste(idProfessor)) {
      _invalido('id_professor');
    }
  }

  Never _invalido(String campo) =>
      throw AulaValidationException(CodigoErro.campoInvalido, campo: campo);

  PgDate _hoje() => _diaCivil(_agora());

  /// So o dia civil: descarta hora e fuso do DateTime de origem.
  static PgDate _diaCivil(DateTime d) =>
      PgDate(year: d.year, month: d.month, day: d.day);

  bool _jaRealizada(AulaData aula) =>
      !_momento(aula.data, _paraDuration(aula.horaFim)).isAfter(_agora());

  static DateTime _momento(PgDate data, Duration hora) {
    final dia = data.toDateTime();
    return DateTime(dia.year, dia.month, dia.day).add(hora);
  }

  static bool _horaValida(Duration d) =>
      !d.isNegative &&
      d < const Duration(hours: 24) &&
      d.inMicroseconds % Duration.microsecondsPerMinute == 0;

  static pg.Time _paraTime(Duration d) =>
      pg.Time.fromMicroseconds(d.inMicroseconds);

  static Duration _paraDuration(pg.Time t) =>
      Duration(microseconds: t.microseconds);
}
