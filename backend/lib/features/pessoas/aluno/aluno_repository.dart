import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart' show PgDate;

import '../../../database/database.dart';

/// Acesso a tabela `aluno`. Nao valida (isso e do `AlunoService`) e nao
/// traduz erro do banco: a `ServerException` sobe crua para o tradutor
/// unico, `lib/shared/erros/tradutor_erro_banco.dart`
/// (`docs/arquitetura.md` §7, D64).
class AlunoRepository {
  final GraziDatabase _db;

  AlunoRepository(this._db);

  Future<AlunoData> create({
    required String cpf,
    required String senhaHash,
    required String nome,
    required DateTime dataNascimento,
    required String telefone,
    required String email,
    int? idAdminCriador,
    int? idEndereco,
    String? restricaoMedica,
    String? observacaoSaude,
  }) {
    return _db
        .into(_db.aluno)
        .insertReturning(
          AlunoCompanion.insert(
            cpf: cpf,
            senhaHash: senhaHash,
            nome: nome,
            dataNascimento: _comoDataCivil(dataNascimento),
            telefone: telefone,
            email: email,
            idAdminCriador: Value(idAdminCriador),
            idEndereco: Value(idEndereco),
            restricaoMedica: Value(restricaoMedica),
            observacaoSaude: Value(observacaoSaude),
          ),
        );
  }

  Future<bool> cpfEmUso(String cpf) async {
    final consulta = _db.selectOnly(_db.aluno)
      ..addColumns([_db.aluno.idAluno])
      ..where(_db.aluno.cpf.equals(cpf))
      ..limit(1);

    return await consulta.getSingleOrNull() != null;
  }

  /// [excetoIdAluno] tira o proprio aluno da conta: na edicao, manter o
  /// e-mail que ja e dele nao e conflito.
  Future<bool> emailEmUso(String email, {int? excetoIdAluno}) async {
    final emAluno = _db.selectOnly(_db.aluno)
      ..addColumns([_db.aluno.idAluno])
      ..where(
        excetoIdAluno == null
            ? _db.aluno.email.equals(email)
            : _db.aluno.email.equals(email) &
                  _db.aluno.idAluno.equals(excetoIdAluno).not(),
      )
      ..limit(1);

    if (await emAluno.getSingleOrNull() != null) {
      return true;
    }

    final emAdmin = _db.selectOnly(_db.admin)
      ..addColumns([_db.admin.idAdmin])
      ..where(_db.admin.email.equals(email))
      ..limit(1);

    return await emAdmin.getSingleOrNull() != null;
  }

  static PgDate _comoDataCivil(DateTime data) =>
      PgDate.fromDateTime(DateTime.utc(data.year, data.month, data.day));

  /// Devolve `null` quando o aluno nao existe — decidir se isso e erro
  /// (404) e papel do `AlunoService`, nao do repositorio.
  Future<AlunoData?> buscarAlunoPorId(int idAluno) {
    return (_db.select(
      _db.aluno,
    )..where((t) => t.idAluno.equals(idAluno))).getSingleOrNull();
  }

  /// Uma pagina de alunos, em ordem alfabetica.
  ///
  /// O desempate por `idAluno` nao e enfeite: dois alunos com o mesmo nome
  /// sem ele podem trocar de lugar entre uma consulta e outra, e um deles
  /// apareceria em duas paginas e o outro em nenhuma.
  Future<List<AlunoData>> buscarAlunos({
    required int limit,
    required int offset,
  }) {
    return (_db.select(_db.aluno)
          ..orderBy([
            (t) => OrderingTerm.asc(t.nome),
            (t) => OrderingTerm.asc(t.idAluno),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<int> countAlunos() async {
    final total = _db.aluno.idAluno.count();
    final consulta = _db.selectOnly(_db.aluno)..addColumns([total]);
    return (await consulta.getSingle()).read(total)!;
  }

  /// Altera so os campos nao nulos. Devolve `null` quando o aluno nao
  /// existe.
  Future<AlunoData?> atualizar(
    int idAluno, {
    String? nome,
    String? telefone,
    String? email,
  }) async {
    final linhas =
        await (_db.update(
          _db.aluno,
        )..where((t) => t.idAluno.equals(idAluno))).writeReturning(
          AlunoCompanion(
            nome: Value.absentIfNull(nome),
            telefone: Value.absentIfNull(telefone),
            email: Value.absentIfNull(email),
          ),
        );

    return linhas.isEmpty ? null : linhas.single;
  }

  /// Inativa (`false`) ou reativa (`true`). Devolve `false` quando o aluno
  /// nao existe.
  Future<bool> alterarStatus(int idAluno, {required bool status}) async {
    final afetadas =
        await (_db.update(_db.aluno)..where((t) => t.idAluno.equals(idAluno)))
            .write(AlunoCompanion(status: Value(status)));

    return afetadas > 0;
  }

  /// Exclusao real. Devolve `false` quando o aluno nao existe.
  ///
  /// Aluno com historico faz o banco recusar com `23001` (FKs `RESTRICT`).
  /// A excecao sobe crua para o tradutor unico.
  Future<bool> excluir(int idAluno) async {
    final afetadas = await (_db.delete(
      _db.aluno,
    )..where((t) => t.idAluno.equals(idAluno))).go();

    return afetadas > 0;
  }
}
