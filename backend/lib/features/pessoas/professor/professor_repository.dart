import 'package:drift/drift.dart';

import '../../../database/database.dart';

/// Acesso à tabela `professor`.
///
/// Não valida e não traduz erro: quem valida é o `ProfessorService`, e a
/// tradução do erro do banco é do `tradutor_erro_banco.dart` (D64).
class ProfessorRepository {
  final GraziDatabase _db;

  ProfessorRepository(this._db);

  Future<ProfessorData> create({
    required String cpf,
    required String senhaHash,
    required String nome,
    required String telefone,
    required String email,
    int? idAdminCriador,
  }) {
    return _db.into(_db.professor).insertReturning(
      ProfessorCompanion.insert(
        cpf: cpf,
        senhaHash: senhaHash,
        nome: nome,
        telefone: telefone,
        email: email,
        idAdminCriador: Value(idAdminCriador),
      ),
    );
  }

  Future<ProfessorData?> buscarPorId(int idProfessor) {
    return (_db.select(_db.professor)
          ..where((t) => t.idProfessor.equals(idProfessor)))
        .getSingleOrNull();
  }

  /// Devolve `null` se o id não existe.
  Future<ProfessorData?> atualizar({
    required int idProfessor,
    String? nome,
    String? email,
    String? telefone,
    String? senhaHash,
    bool? status,
  }) async {
    final linhas = await (_db.update(_db.professor)
          ..where((t) => t.idProfessor.equals(idProfessor)))
        .write(
      ProfessorCompanion(
        nome: nome != null ? Value(nome) : const Value.absent(),
        email: email != null ? Value(email) : const Value.absent(),
        telefone: telefone != null ? Value(telefone) : const Value.absent(),
        senhaHash: senhaHash != null ? Value(senhaHash) : const Value.absent(),
        status: status != null ? Value(status) : const Value.absent(),
      ),
    );

    if (linhas == 0) return null;
    return buscarPorId(idProfessor);
  }

  /// Devolve `false` se o id não existe.
  Future<bool> deletar(int idProfessor) async {
    final linhas = await (_db.delete(_db.professor)
          ..where((t) => t.idProfessor.equals(idProfessor)))
        .go();
    return linhas > 0;
  }

  Future<bool> cpfEmUso(String cpf) async {
    final consulta = _db.selectOnly(_db.professor)
      ..addColumns([_db.professor.idProfessor])
      ..where(_db.professor.cpf.equals(cpf))
      ..limit(1);

    return await consulta.getSingleOrNull() != null;
  }

  /// D61: o e-mail é único entre professor, admin e aluno.
  /// [ignorarIdProfessor] evita que o professor "conflite" com o próprio
  /// e-mail ao atualizar.
  Future<bool> emailEmUso(String email, {int? ignorarIdProfessor}) async {
    final emProfessor = _db.selectOnly(_db.professor)
      ..addColumns([_db.professor.idProfessor])
      ..where(_db.professor.email.equals(email))
      ..limit(1);

    if (ignorarIdProfessor != null) {
      emProfessor.where(
        _db.professor.idProfessor.equals(ignorarIdProfessor).not(),
      );
    }

    if (await emProfessor.getSingleOrNull() != null) return true;

    final emAdmin = _db.selectOnly(_db.admin)
      ..addColumns([_db.admin.idAdmin])
      ..where(_db.admin.email.equals(email))
      ..limit(1);

    if (await emAdmin.getSingleOrNull() != null) return true;

    final emAluno = _db.selectOnly(_db.aluno)
      ..addColumns([_db.aluno.idAluno])
      ..where(_db.aluno.email.equals(email))
      ..limit(1);

    return await emAluno.getSingleOrNull() != null;
  }
}