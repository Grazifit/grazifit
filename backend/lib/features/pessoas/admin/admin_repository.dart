import 'package:drift/drift.dart';
import 'package:postgres/postgres.dart' as pg;

import '../../../database/database.dart';
import 'package:grazifit_backend/shared/erros/admin_exceptions.dart'; // ajuste para o tradutor_erro_banco, se for o padrão final

class AdminRepository {
  final GraziDatabase _db;

  AdminRepository(this._db);

  Future<AdminData> create({
    required String cpf,
    required String nome,
    required String email,
    required String senhaHash,
    String? telefone,
  }) async {
    try {
      return await _db.into(_db.admin).insertReturning(
        AdminCompanion.insert(
          cpf: cpf,
          nome: nome,
          senhaHash: senhaHash,
          email: email,
          telefone: Value(telefone),
        ),
      );
      } on pg.ServerException catch (e) {
    _traduzirErroUnico(e);
  }
  }

  Future<AdminData?> buscarPorId(int idAdmin) {
    return (_db.select(_db.admin)
          ..where((t) => t.idAdmin.equals(idAdmin)))
        .getSingleOrNull();
  }

  Future<AdminData> atualizar({
    required int idAdmin,
    String? nome,
    String? email,
    String? telefone,
    String? senhaHash,
  }) async {
    try {
      final linhasAfetadas = await (_db.update(_db.admin)
            ..where((t) => t.idAdmin.equals(idAdmin)))
          .write(
        AdminCompanion(
          nome: nome != null ? Value(nome) : const Value.absent(),
          email: email != null ? Value(email) : const Value.absent(),
          telefone: Value(telefone),
          senhaHash: senhaHash != null ? Value(senhaHash) : const Value.absent(),
        ),
      );

      if (linhasAfetadas == 0) {
        throw NotFoundException('Admin não encontrado.');
      }

      return (await buscarPorId(idAdmin))!;
    } on pg.ServerException catch (e) {
    _traduzirErroUnico(e);
  }
  }

  Future<void> deletar(int idAdmin) async {
    final linhasAfetadas = await (_db.delete(_db.admin)
          ..where((t) => t.idAdmin.equals(idAdmin)))
        .go();

    if (linhasAfetadas == 0) {
      throw NotFoundException('Admin não encontrado.');
    }
  }

  Never _traduzirErroUnico(pg.ServerException e) {
    if (e.code == '23505') {
      if (e.constraintName == 'uq_admin_cpf') {
        throw ConflictException('CPF já cadastrado.');
      }
      if (e.constraintName == 'uq_admin_email') {
        throw ConflictException('E-mail já cadastrado.');
      }
      throw ConflictException('Registro duplicado.');
    }
    throw e;
  }
}