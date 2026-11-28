import 'package:drift/drift.dart';

import '../../database/database.dart';

/// Acesso a tabela `exercicio`. Nao valida (isso e do `ExercicioService`) e
/// nao traduz erro do banco: a `ServerException` sobe crua para o tradutor
/// unico, `lib/shared/erros/tradutor_erro_banco.dart`.
class ExercicioRepository {
  final GraziDatabase _db;

  ExercicioRepository(this._db);

  Future<ExercicioData> create({
    required int idAdminCriador,
    required String nome,
    required String instrucoes,
    String? descricao,
    required String dificuldade,
  }) {
    return _db
        .into(_db.exercicio)
        .insertReturning(
          ExercicioCompanion.insert(
            idAdminCriador: idAdminCriador,
            nome: nome,
            instrucoes: instrucoes,
            descricao: Value(descricao),
            dificuldade: Value(dificuldade),
          ),
        );
  }

  /// [excetoIdExercicio] tira o proprio exercicio da conta: na edicao,
  /// manter o nome que ja e dele nao e conflito.
  Future<bool> nomeEmUso(String nome, {int? excetoIdExercicio}) async {
    final consulta = _db.selectOnly(_db.exercicio)
      ..addColumns([_db.exercicio.idExercicio])
      ..where(
        excetoIdExercicio == null
            ? _db.exercicio.nome.equals(nome)
            : _db.exercicio.nome.equals(nome) &
                  _db.exercicio.idExercicio.equals(excetoIdExercicio).not(),
      )
      ..limit(1);

    return await consulta.getSingleOrNull() != null;
  }

  /// Devolve `null` quando o exercicio nao existe — decidir se isso e erro
  /// (404) e papel do `ExercicioService`.
  Future<ExercicioData?> buscarExercicioPorId(int idExercicio) {
    return (_db.select(
      _db.exercicio,
    )..where((t) => t.idExercicio.equals(idExercicio))).getSingleOrNull();
  }

  /// Uma pagina de exercicios, em ordem alfabetica. O desempate por
  /// `idExercicio` mantem a paginacao estavel.
  Future<List<ExercicioData>> buscarExercicios({
    required int limit,
    required int offset,
  }) {
    return (_db.select(_db.exercicio)
          ..orderBy([
            (t) => OrderingTerm.asc(t.nome),
            (t) => OrderingTerm.asc(t.idExercicio),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<int> countExercicios() async {
    final total = _db.exercicio.idExercicio.count();
    final consulta = _db.selectOnly(_db.exercicio)..addColumns([total]);
    return (await consulta.getSingle()).read(total)!;
  }

  /// Altera so os campos nao nulos. Devolve `null` quando o exercicio nao
  /// existe.
  Future<ExercicioData?> atualizar(
    int idExercicio, {
    String? nome,
    String? instrucoes,
    String? descricao,
    String? dificuldade,
  }) async {
    final linhas =
        await (_db.update(
          _db.exercicio,
        )..where((t) => t.idExercicio.equals(idExercicio))).writeReturning(
          ExercicioCompanion(
            nome: Value.absentIfNull(nome),
            instrucoes: Value.absentIfNull(instrucoes),
            descricao: Value.absentIfNull(descricao),
            dificuldade: Value.absentIfNull(dificuldade),
          ),
        );

    return linhas.isEmpty ? null : linhas.single;
  }

  /// Exclusao real. Devolve `false` quando o exercicio nao existe.
  ///
  /// Exercicio usado em `treino_exercicio` faz o banco recusar com `23001`
  /// (FK `RESTRICT`). A excecao sobe crua para o tradutor unico.
  Future<bool> excluir(int idExercicio) async {
    final afetadas = await (_db.delete(
      _db.exercicio,
    )..where((t) => t.idExercicio.equals(idExercicio))).go();

    return afetadas > 0;
  }
}
