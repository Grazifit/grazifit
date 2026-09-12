import 'package:drift/drift.dart';
import 'package:postgres/postgres.dart' as pg;

import '../../../database/database.dart'; // ajuste o caminho real
import 'package:shared/erros/admin_exceptions.dart';

class AdminRepository {
  final GraziDatabase _db;

  AdminRepository(this._db);
  
  Future<AdminData> create({
    required String cpf,
    required String nome,
    required String email,
    required String senhaHash,
    String? telefone,
  })async{
    try{
      return await _db.into(_db.admin).insertReturning(
        AdminCompanion.insert(
          cpf: cpf,
          nome: nome,
          senhaHash: senhaHash,
          email: email,
          telefone: Value(telefone),
        ),
      );
    } on pg.ServerException catch(e){
        if (e.code == '23505') {
          if (e.constraintName == 'uq_admin_cpf') {
            throw ConflictException('CPF já cadastrado.');
          }
          if (e.constraintName == 'uq_admin_email') {
            throw ConflictException('E-mail já cadastrado.');
          }
          throw ConflictException('Registro duplicado.');
        }
        rethrow;
    }
  }
}

