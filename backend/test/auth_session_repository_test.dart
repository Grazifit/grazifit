@Timeout(Duration(minutes: 2))
library;

import 'package:grazifit_backend/database/database.dart';
import 'package:test/test.dart';

void main() {
  late GraziDatabase db;
  final emails = <String>[];

  setUpAll(() async {
    db = GraziDatabase.doAmbiente();
    await db.customSelect('SELECT 1 FROM sessao_auth LIMIT 1').get();
  });

  tearDownAll(() async {
    await db.customStatement(
      "DELETE FROM sessao_auth WHERE jti_hash IN ('${'a' * 64}', '${'b' * 64}')",
    );
    for (final email in emails) {
      await db.customStatement(
        "DELETE FROM admin WHERE email = '${email.replaceAll("'", "''")}'",
      );
    }
    await db.close();
  });

  test('troca de senha revoga todas as sessoes ativas da identidade', () async {
    final email =
        'sessao.${DateTime.now().microsecondsSinceEpoch}@exemplo.test';
    emails.add(email);
    final admin = await db.customSelect('''
      INSERT INTO admin (cpf, senha_hash, nome, telefone, email)
      VALUES ('00000009999', 'hash-1', 'Admin Sessao', '11900009999', '$email')
      RETURNING id_admin
    ''').getSingle();
    final id = admin.read<int>('id_admin');

    await db.customStatement('''
      INSERT INTO sessao_auth (jti_hash, papel, id_usuario, expira_em)
      VALUES ('${'a' * 64}', 'admin', $id, now() + interval '1 hour'),
             ('${'b' * 64}', 'admin', $id, now() + interval '1 hour')
    ''');
    await db.customStatement(
      "UPDATE admin SET senha_hash = 'hash-2' WHERE id_admin = $id",
    );

    final ativas = await db.customSelect('''
      SELECT count(*) AS total FROM sessao_auth
       WHERE papel = 'admin' AND id_usuario = $id AND revogada_em IS NULL
    ''').getSingle();
    expect(ativas.read<int>('total'), 0);
  });
}
