@Timeout(Duration(minutes: 2))
library;

import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/pessoas/admin/admin_repository.dart';
import 'package:test/test.dart';

void main() {
  late GraziDatabase db;
  late AdminRepository repository;

  const email = 'patch.admin@exemplo.test';

  setUpAll(() async {
    db = GraziDatabase.doAmbiente();
    repository = AdminRepository(db);
    await db.customSelect('SELECT 1').getSingle();
    await db.customStatement("DELETE FROM admin WHERE email = '$email'");
  });

  tearDownAll(() async {
    await db.customStatement("DELETE FROM admin WHERE email = '$email'");
    await db.close();
  });

  test('PATCH sem telefone preserva o telefone atual', () async {
    final criado = await repository.create(
      cpf: '16899535009',
      nome: 'Admin Patch',
      email: email,
      senhaHash: 'hash-integracao',
      telefone: '11999998888',
    );

    final atualizado = await repository.atualizar(
      idAdmin: criado.idAdmin,
      nome: 'Admin Atualizado',
    );

    expect(atualizado.nome, 'Admin Atualizado');
    expect(atualizado.telefone, '11999998888');
  });
}
