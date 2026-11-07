// Executar da pasta backend com DATABASE_URL definida. Cria e remove apenas
// um banco de teste com nome unico; nunca aplica SQL no banco de origem.
import 'dart:io';

import 'package:postgres/postgres.dart';

Future<void> main(List<String> args) async {
  final source = Uri.parse(Platform.environment['DATABASE_URL']!);
  final name = 'grazifit_auth_test_${DateTime.now().microsecondsSinceEpoch}';
  final admin = await Connection.openFromUrl(source.toString());
  final duplicates = await admin.execute('''
    SELECT count(*) FROM (
      SELECT lower(btrim(email::text)) FROM (
        SELECT email FROM admin UNION ALL SELECT email FROM professor
        UNION ALL SELECT email FROM aluno
      ) contas GROUP BY lower(btrim(email::text)) HAVING count(*) > 1
    ) duplicados
  ''');
  stdout.writeln(
    'Grupos de emails duplicados no banco de origem: ${duplicates.single.single}',
  );
  try {
    await admin.execute('CREATE DATABASE $name');
    final target = source.replace(path: '/$name').toString();
    final db = await Connection.openFromUrl(target);
    try {
      await db.execute(
        await File('../database/schema/grazi_db_init_schema.sql')
            .readAsString(),
        queryMode: QueryMode.simple,
      );
      final migrations =
          Directory('../database/migrations')
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.sql'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      for (final file in migrations) {
        if (file.path.endsWith('002_unicidade_email_global.sql')) {
          await db.execute(
            "INSERT INTO admin (cpf, nome, senha_hash, email) VALUES ('88000000001','Teste','hash','Duplicate@example.test'); INSERT INTO professor (cpf, nome, senha_hash, telefone, email) VALUES ('88000000002','Teste','hash','11900000000','duplicate@example.test');",
            queryMode: QueryMode.simple,
          );
          var rejected = false;
          try {
            await db.execute(
              'BEGIN;\n${await file.readAsString()}\nCOMMIT;',
              queryMode: QueryMode.simple,
            );
          } on ServerException catch (e) {
            rejected =
                e.code == '23505' && e.constraintName == 'uq_conta_email';
            await db.execute('ROLLBACK');
          }
          if (!rejected) {
            throw StateError('Migration aceitou duplicidade preexistente');
          }
          await db.execute(
            "DELETE FROM admin WHERE cpf = '88000000001'; DELETE FROM professor WHERE cpf = '88000000002';",
            queryMode: QueryMode.simple,
          );
          stdout.writeln(
            'Migration rejeitou duplicidade preexistente atomicamente.',
          );
        }
        await db.execute(
          'BEGIN;\n${await file.readAsString()}\nCOMMIT;',
          queryMode: QueryMode.simple,
        );
      }
    } finally {
      await db.close();
    }
    final test = await Process.start(
      Platform.resolvedExecutable,
      ['test', '--concurrency=1', ...args],
      environment: {'DATABASE_URL': target},
      mode: ProcessStartMode.inheritStdio,
    );
    exitCode = await test.exitCode;
  } finally {
    await admin.execute('DROP DATABASE IF EXISTS $name WITH (FORCE)');
    await admin.close();
  }
}
