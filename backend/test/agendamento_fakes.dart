import 'package:drift/drift.dart' show Value;
import 'package:drift_postgres/drift_postgres.dart' show PgDate, PgDateTime;
import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/agendamentos/agendamento_repository.dart';
import 'package:grazifit_backend/features/agendamentos/agendamento_service.dart';
import 'package:grazifit_backend/shared/autorizacao/identidade.dart';
import 'package:postgres/postgres.dart' as pg;

/// Repositorio em memoria para testes de service e controller.
/// Nao simula trigger nem constraint: isso e papel dos testes de banco.
class RepositorioAgendamentoFalso implements AgendamentoRepository {
  /// Aula de teste. Busca por id: outro id nao encontra.
  AulaData? aula;

  final List<AgendamentoData> agendamentos = [];
  int _proximoId = 1;
  bool emTransacao = false;

  /// Relogio do fake, no lugar do `now()` do banco.
  DateTime Function() agora = () => agoraFixo;

  /// Conta quantas vezes cada leitura de lock foi chamada fora de transacao.
  int leiturasSemTransacao = 0;

  /// Quantas vezes a aula foi travada para chamada (FOR UPDATE).
  int travasDaAula = 0;

  /// Conta todas as leituras com `FOR UPDATE` (dentro ou fora de transacao).
  int leiturasComTrava = 0;

  /// Regras de tempo como o SQL de `agendamento_repository.dart` calcularia
  /// com [agora]. A prova do fuso e de banco real (grupo `fuso:` em
  /// `agendamento_repository_test.dart`), nao deste fake.
  RegrasDeTempo _regrasDe(AulaData a) {
    final utc = agora().toUtc();
    final brasilia = utc.subtract(const Duration(hours: 3));
    final hoje = PgDate(
      year: brasilia.year,
      month: brasilia.month,
      day: brasilia.day,
    );
    final diaAula = DateTime.utc(a.data.year, a.data.month, a.data.day);
    final diaHoje = DateTime.utc(hoje.year, hoje.month, hoje.day);
    final inicio = diaAula
        .add(Duration(microseconds: a.horaInicio.microseconds))
        .add(const Duration(hours: 3));
    return RegrasDeTempo(
      dataPassada: diaAula.isBefore(diaHoje),
      dentroDaJanela:
          inicio.difference(utc) < AgendamentoService.antecedenciaMinima,
      anoHoje: hoje.year,
      hoje: hoje,
    );
  }

  /// Quantas transacoes foram abertas por este repositorio.
  int transacoes = 0;

  @override
  Future<T> transacao<T>(Future<T> Function() acao) async {
    transacoes++;
    emTransacao = true;
    try {
      return await acao();
    } finally {
      emTransacao = false;
    }
  }

  @override
  Future<SituacaoReserva?> travarSituacaoParaReserva(
    int idAula,
    int idAluno,
  ) async {
    if (!emTransacao) leiturasSemTransacao++;
    final a = aula;
    if (a == null || a.idAula != idAula) return null;
    final existente = agendamentos
        .where((g) => g.idAluno == idAluno && g.idAula == idAula)
        .firstOrNull;
    return SituacaoReserva(
      aula: a,
      regras: _regrasDe(a),
      ocupadas: await contarAtivos(idAula),
      idAgendamentoExistente: existente?.idAgendamento,
      statusExistente: existente?.status,
    );
  }

  @override
  Future<AulaLida?> buscarAula(int idAula) async {
    final a = aula;
    return a == null || a.idAula != idAula
        ? null
        : AulaLida(aula: a, regras: _regrasDe(a));
  }

  @override
  Future<AgendamentoData?> buscarSemTrava(int idAgendamento) async =>
      agendamentos.where((a) => a.idAgendamento == idAgendamento).firstOrNull;

  @override
  Future<AgendamentoData?> buscarParaAtualizar(int idAgendamento) async {
    leiturasComTrava++;
    if (!emTransacao) leiturasSemTransacao++;
    return agendamentos
        .where((a) => a.idAgendamento == idAgendamento)
        .firstOrNull;
  }

  @override
  Future<AgendamentoData?> buscarPorAlunoAula(int idAluno, int idAula) async =>
      agendamentos
          .where((a) => a.idAluno == idAluno && a.idAula == idAula)
          .firstOrNull;

  @override
  Future<int> contarAtivos(int idAula) async => agendamentos
      .where(
        (a) => a.idAula == idAula && !statusQueNaoOcupamVaga.contains(a.status),
      )
      .length;

  @override
  Future<AgendamentoData> inserir({
    required int idAluno,
    required int idAula,
    required PgDate dataAgendamento,
  }) async {
    final novo = AgendamentoData(
      idAgendamento: _proximoId++,
      idAluno: idAluno,
      idAula: idAula,
      dataAgendamento: dataAgendamento,
      status: 'agendado',
    );
    agendamentos.add(novo);
    return novo;
  }

  @override
  Future<AgendamentoData> reativar(
    int idAgendamento, {
    required PgDate dataAgendamento,
  }) async {
    final i = agendamentos.indexWhere((a) => a.idAgendamento == idAgendamento);
    return agendamentos[i] = agendamentos[i].copyWith(
      status: 'agendado',
      dataAgendamento: dataAgendamento,
      dataCancelamento: const Value(null),
    );
  }

  @override
  Future<AgendamentoData> cancelar(
    int idAgendamento, {
    required DateTime agora,
  }) async {
    final i = agendamentos.indexWhere((a) => a.idAgendamento == idAgendamento);
    return agendamentos[i] = agendamentos[i].copyWith(
      status: 'cancelado',
      dataCancelamento: Value(PgDateTime(agora)),
    );
  }

  @override
  Future<AulaChamada?> travarAulaParaChamada(int idAula) async {
    travasDaAula++;
    final a = aula;
    if (a == null || a.idAula != idAula) return null;
    final inicio = DateTime.utc(a.data.year, a.data.month, a.data.day)
        .add(Duration(microseconds: a.horaInicio.microseconds))
        .add(const Duration(hours: 3));
    return AulaChamada(
      aula: a,
      antesDoInicio: agora().toUtc().isBefore(inicio),
    );
  }

  @override
  Future<List<AgendamentoData>> travarAgendamentosDaAula(int idAula) async =>
      agendamentos.where((a) => a.idAula == idAula).toList();

  @override
  Future<List<AgendamentoData>> gravarPresenca({
    required List<int> presentes,
    required List<int> faltaram,
    required DateTime agora,
  }) async {
    final gravadas = <AgendamentoData>[];
    for (var i = 0; i < agendamentos.length; i++) {
      final a = agendamentos[i];
      if (presentes.contains(a.idAgendamento)) {
        agendamentos[i] = a.copyWith(
          status: 'presente',
          dataPresenca: Value(PgDateTime(agora)),
        );
      } else if (faltaram.contains(a.idAgendamento)) {
        agendamentos[i] = a.copyWith(
          status: 'faltou',
          dataPresenca: const Value(null),
        );
      } else {
        continue;
      }
      gravadas.add(agendamentos[i]);
    }
    return gravadas;
  }

  /// Chamadas de [cancelarAgendadosDaAula]: (idAula, agora).
  final List<(int, DateTime)> cascatas = [];

  @override
  Future<int> cancelarAgendadosDaAula(
    int idAula, {
    required DateTime agora,
  }) async {
    cascatas.add((idAula, agora));
    var alterados = 0;
    for (var i = 0; i < agendamentos.length; i++) {
      final a = agendamentos[i];
      if (a.idAula != idAula || a.status != 'agendado') continue;
      agendamentos[i] = a.copyWith(
        status: 'cancelado',
        dataCancelamento: Value(PgDateTime(agora)),
      );
      alterados++;
    }
    return alterados;
  }

  @override
  Future<List<AgendamentoData>> listarDoAluno({
    required int idAluno,
    required int limit,
    required int offset,
  }) async {
    final doAluno = agendamentos.where((a) => a.idAluno == idAluno).toList();
    return doAluno.skip(offset).take(limit).toList();
  }

  @override
  Future<int> contarDoAluno(int idAluno) async =>
      agendamentos.where((a) => a.idAluno == idAluno).length;
}

/// Aula ativa de 20/06/2026, 18:00-19:00, com `vagas` vagas.
AulaData aulaDe({
  int idAula = 1,
  DateTime? data,
  Duration horaInicio = const Duration(hours: 18),
  Duration horaFim = const Duration(hours: 19),
  int vagas = 10,
  bool status = true,
}) => AulaData(
  idAula: idAula,
  idProfessor: 10,
  data: PgDate.fromDateTime(data ?? DateTime(2026, 6, 20)),
  horaInicio: pg.Time.fromMicroseconds(horaInicio.inMicroseconds),
  horaFim: pg.Time.fromMicroseconds(horaFim.inMicroseconds),
  tipo: 'coletiva',
  categoria: 'pilates',
  vagasMaxima: vagas,
  status: status,
);

const aluno = Identidade(id: 5, papel: Papel.aluno);
const outroAluno = Identidade(id: 6, papel: Papel.aluno);
const professor = Identidade(id: 10, papel: Papel.professor);
const admin = Identidade(id: 1, papel: Papel.admin);

/// "Agora" fixo: 10/06/2026, 12:00 de Brasilia (UTC-3) = 15:00 UTC.
/// Instante absoluto, independente do fuso do host. Aula de 20/06 fica
/// bem fora da janela.
final agoraFixo = DateTime.utc(2026, 6, 10, 15);
