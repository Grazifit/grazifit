import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart' show PgDate;

import '../../../database/database.dart';

/// Acesso a tabela `aluno`.
///
/// O repositorio **nao valida e nao traduz**.
///
/// Nao valida porque quem valida formato e regra e o `AlunoService` —
/// aqui so chega dado ja normalizado.
///
/// Nao traduz porque o tradutor e unico (D64):
/// `lib/shared/erros/tradutor_erro_banco.dart`. Nenhum `catch` sobre
/// `ServerException` mora neste arquivo; a excecao sobe crua e e traduzida
/// uma vez so, no ponto que conhece HTTP. O que o banco rejeita continua
/// sendo a ultima palavra (D58) — apenas nao e este arquivo que da nome ao
/// que ele rejeitou.
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

  Future<bool> emailEmUso(String email) async {
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

  static PgDate _comoDataCivil(DateTime data) =>
      PgDate.fromDateTime(DateTime.utc(data.year, data.month, data.day));
}
