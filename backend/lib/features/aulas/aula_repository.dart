import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart' as pg;

import '../../../database/database.dart';

/// Acesso a tabela `aula`. Sem validacao: erros do banco sobem para o
/// tradutor. `professor` e `agendamento` sao apenas lidos.
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

  /// Agendamentos que ocupam vaga (fora `cancelado` e `faltou`).
  Future<int> contarAgendamentosAtivos(int idAula) async {
    final linha = await _db
        .customSelect(
          r'''
      SELECT COUNT(*)::int AS total
        FROM agendamento
       WHERE id_aula = $1
         AND status NOT IN ('cancelado', 'faltou')
    ''',
          variables: [Variable.withInt(idAula)],
        )
        .getSingle();
    return linha.read<int>('total');
  }

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
