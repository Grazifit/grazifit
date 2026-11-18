import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart' as pg;

import '../../../database/database.dart';
import '../agendamentos/agendamento_repository.dart'
    show statusQueNaoOcupamVaga;

/// Agendamento listado para admin e professor: so o que identifica o aluno
/// na chamada.
class AgendadoDaAula {
  final int idAgendamento;
  final int idAluno;
  final String nomeAluno;
  final String status;

  const AgendadoDaAula({
    required this.idAgendamento,
    required this.idAluno,
    required this.nomeAluno,
    required this.status,
  });
}

/// Acesso a tabela `aula`. Sem validacao: erros do banco sobem para o
/// tradutor. `professor`, `aluno` e `agendamento` sao so lidos.
class AulaRepository {
  final GraziDatabase _db;

  AulaRepository(this._db);

  /// Insere aula avulsa (`id_cronograma` nulo).
  Future<AulaData> create({
    required int idAdminCriador,
    required int idProfessor,
    required PgDate data,
    required pg.Time horaInicio,
    required pg.Time horaFim,
    required String tipo,
    required String categoria,
    required int vagasMaxima,
  }) {
    return _db
        .into(_db.aula)
        .insertReturning(
          AulaCompanion.insert(
            idAdminCriador: Value(idAdminCriador),
            idProfessor: idProfessor,
            data: data,
            horaInicio: horaInicio,
            horaFim: horaFim,
            tipo: tipo,
            categoria: categoria,
            vagasMaxima: vagasMaxima,
          ),
        );
  }

  /// `null` quando nao existe. Inclui aulas canceladas.
  Future<AulaData?> buscarPorId(int idAula) {
    return (_db.select(
      _db.aula,
    )..where((t) => t.idAula.equals(idAula))).getSingleOrNull();
  }

  /// Ordem cronologica, com desempate por id para paginacao estavel.
  Future<List<AulaData>> listar({
    required int limit,
    required int offset,
    PgDate? data,
    String? categoria,
    int? idProfessor,
  }) {
    return (_db.select(_db.aula)
          ..where(
            (t) => _filtro(
              t,
              data: data,
              categoria: categoria,
              idProfessor: idProfessor,
            ),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.data),
            (t) => OrderingTerm.asc(t.horaInicio),
            (t) => OrderingTerm.asc(t.idAula),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Total com os mesmos filtros de [listar].
  Future<int> contar({
    PgDate? data,
    String? categoria,
    int? idProfessor,
  }) async {
    final total = _db.aula.idAula.count();
    final consulta = _db.selectOnly(_db.aula)
      ..addColumns([total])
      ..where(
        _filtro(
          _db.aula,
          data: data,
          categoria: categoria,
          idProfessor: idProfessor,
        ),
      );
    return (await consulta.getSingle()).read(total)!;
  }

  /// Altera so os campos nao nulos. `null` quando a aula nao existe.
  Future<AulaData?> atualizar(
    int idAula, {
    int? idProfessor,
    PgDate? data,
    pg.Time? horaInicio,
    pg.Time? horaFim,
    String? tipo,
    String? categoria,
    int? vagasMaxima,
  }) async {
    final linhas =
        await (_db.update(
          _db.aula,
        )..where((t) => t.idAula.equals(idAula))).writeReturning(
          AulaCompanion(
            idProfessor: Value.absentIfNull(idProfessor),
            data: Value.absentIfNull(data),
            horaInicio: Value.absentIfNull(horaInicio),
            horaFim: Value.absentIfNull(horaFim),
            tipo: Value.absentIfNull(tipo),
            categoria: Value.absentIfNull(categoria),
            vagasMaxima: Value.absentIfNull(vagasMaxima),
          ),
        );

    return linhas.isEmpty ? null : linhas.single;
  }

  /// Agendamentos que ocupam vaga, pela regra de [statusQueNaoOcupamVaga].
  Future<int> contarAgendamentosAtivos(int idAula) async =>
      (await contarOcupadasPorAula([idAula]))[idAula] ?? 0;

  /// Vagas ocupadas de varias aulas numa so consulta agregada. Aula sem
  /// agendamento que ocupe vaga nao aparece no mapa.
  Future<Map<int, int>> contarOcupadasPorAula(Iterable<int> idsAulas) async {
    final ids = idsAulas.toSet();
    if (ids.isEmpty) return {};
    final g = _db.agendamento;
    final total = g.idAgendamento.count();
    final consulta = _db.selectOnly(g)
      ..addColumns([g.idAula, total])
      ..where(g.idAula.isIn(ids) & g.status.isNotIn(statusQueNaoOcupamVaga))
      ..groupBy([g.idAula]);
    return {
      for (final linha in await consulta.get())
        linha.read(g.idAula)!: linha.read(total)!,
    };
  }

  /// Agendamentos da aula fora `cancelado`, com o nome do aluno. So as
  /// quatro colunas saem do banco. Ordem por nome e desempate por id.
  Future<List<AgendadoDaAula>> listarAgendados(
    int idAula, {
    required int limit,
    required int offset,
  }) async {
    final g = _db.agendamento;
    final a = _db.aluno;
    final consulta =
        _db.selectOnly(g).join([
            innerJoin(a, a.idAluno.equalsExp(g.idAluno), useColumns: false),
          ])
          ..addColumns([g.idAgendamento, g.idAluno, a.nome, g.status])
          ..where(_agendadoDaAula(idAula))
          ..orderBy([
            OrderingTerm.asc(a.nome),
            OrderingTerm.asc(g.idAgendamento),
          ])
          ..limit(limit, offset: offset);
    return [
      for (final linha in await consulta.get())
        AgendadoDaAula(
          idAgendamento: linha.read(g.idAgendamento)!,
          idAluno: linha.read(g.idAluno)!,
          nomeAluno: linha.read(a.nome)!,
          status: linha.read(g.status)!,
        ),
    ];
  }

  /// Total com o mesmo filtro de [listarAgendados].
  Future<int> contarAgendados(int idAula) async {
    final total = _db.agendamento.idAgendamento.count();
    final consulta = _db.selectOnly(_db.agendamento)
      ..addColumns([total])
      ..where(_agendadoDaAula(idAula));
    return (await consulta.getSingle()).read(total)!;
  }

  Expression<bool> _agendadoDaAula(int idAula) =>
      _db.agendamento.idAula.equals(idAula) &
      _db.agendamento.status.equals('cancelado').not();

  Future<bool> professorAtivoExiste(int idProfessor) async {
    final consulta = _db.selectOnly(_db.professor)
      ..addColumns([_db.professor.idProfessor])
      ..where(
        _db.professor.idProfessor.equals(idProfessor) &
            _db.professor.status.equals(true),
      )
      ..limit(1);
    return await consulta.getSingleOrNull() != null;
  }

  /// Marca a aula como cancelada. Exatamente um dos responsaveis deve vir
  /// preenchido (`ck_aula_cancelamento`). Usar dentro de [transacao].
  Future<AulaData> cancelar(
    int idAula, {
    required DateTime agora,
    int? idAdminCancelou,
    int? idProfessorCancelou,
  }) async {
    final linhas =
        await (_db.update(
          _db.aula,
        )..where((t) => t.idAula.equals(idAula))).writeReturning(
          AulaCompanion(
            status: const Value(false),
            dataCancelamento: Value<PgDateTime?>(PgDateTime(agora)),
            idAdminCancelou: Value(idAdminCancelou),
            idProfessorCancelou: Value(idProfessorCancelou),
          ),
        );
    return linhas.single;
  }

  Future<T> transacao<T>(Future<T> Function() acao) => _db.transaction(acao);

  /// Le a aula com `FOR UPDATE`; usar dentro de [transacao].
  Future<AulaData?> buscarParaAtualizar(int idAula) async {
    final linha = await _db
        .customSelect(
          r'SELECT * FROM aula WHERE id_aula = $1 FOR UPDATE',
          variables: [Variable.withInt(idAula)],
          readsFrom: {_db.aula},
        )
        .getSingleOrNull();
    return linha == null ? null : _db.aula.map(linha.data);
  }

  Expression<bool> _filtro(
    $AulaTable t, {
    PgDate? data,
    String? categoria,
    int? idProfessor,
  }) {
    return Expression.and([
      if (data != null) t.data.equalsExp(Variable(data, PgTypes.date)),
      if (categoria != null) t.categoria.equals(categoria),
      if (idProfessor != null) t.idProfessor.equals(idProfessor),
    ]);
  }
}
