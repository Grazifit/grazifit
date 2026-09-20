import 'package:drift/drift.dart';

import '../../../database/database.dart';

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
    int? idEndereco,
  }) {
    return _db
        .into(_db.professor)
        .insertReturning(
          ProfessorCompanion.insert(
            cpf: cpf,
            senhaHash: senhaHash,
            nome: nome,
            telefone: telefone,
            email: email,
            idAdminCriador: Value(idAdminCriador),
            idEndereco: Value(idEndereco),
          ),
        );
  }

  Future<bool> cpfEmUso(String cpf) async {
    final consulta = _db.selectOnly(_db.professor)
      ..addColumns([_db.professor.idProfessor])
      ..where(_db.professor.cpf.equals(cpf))
      ..limit(1);

    return await consulta.getSingleOrNull() != null;
  }

  Future<bool> emailEmUso(String email) async {
    final emProfessor = _db.selectOnly(_db.professor)
      ..addColumns([_db.professor.idProfessor])
      ..where(_db.professor.email.equals(email))
      ..limit(1);

    if (await emProfessor.getSingleOrNull() != null) {
      return true;
    }

    final emAluno = _db.selectOnly(_db.aluno)
      ..addColumns([_db.aluno.idAluno])
      ..where(_db.aluno.email.equals(email))
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
}