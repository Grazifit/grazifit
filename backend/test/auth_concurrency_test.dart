@Timeout(Duration(minutes: 2))
library;

import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;

import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/auth/auth_repository.dart';
import 'package:grazifit_backend/features/auth/token_service.dart';
import 'package:grazifit_backend/features/pessoas/aluno/aluno_repository.dart';
import 'package:grazifit_backend/shared/autorizacao/identidade.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';

void main() {
  // Duas conexoes PostgreSQL independentes sao intencionais nestes testes.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late GraziDatabase db, other;
  var serial = 0;
  final suffix = DateTime.now().microsecondsSinceEpoch;
  final owners = <(String, int)>[];
  setUp(() {
    db = GraziDatabase.doAmbiente();
    other = GraziDatabase.doAmbiente();
  });
  tearDown(() async {
    for (final (role, id) in owners.reversed) {
      await db.customStatement(
        'DELETE FROM sessao_auth WHERE papel = \$1 AND id_usuario = \$2',
        [role, id],
      );
      await db.customStatement('DELETE FROM $role WHERE id_$role = \$1', [id]);
    }
    owners.clear();
    await other.close();
    await db.close();
  });
  Future<int> insert(GraziDatabase conn, String role, String email) async {
    final cpf = (87000000000 + ++serial).toString();
    final birthColumn = role == 'aluno' ? ', data_nascimento' : '';
    final birthValue = role == 'aluno' ? ", DATE '1990-01-01'" : '';
    final row = await conn
        .customSelect(
          "INSERT INTO $role (cpf, nome, senha_hash, telefone, email$birthColumn) VALUES ('$cpf', 'Teste', 'old', '11900000000', '$email'$birthValue) RETURNING id_$role",
        )
        .getSingle();
    final id = row.read<int>('id_$role');
    owners.add((role, id));
    return id;
  }

  Future<void> waitForLock(int pid) async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (DateTime.now().isBefore(deadline)) {
      final row = await db
          .customSelect(
            "SELECT count(*) AS n FROM pg_stat_activity WHERE pid = $pid AND wait_event_type = 'Lock'",
          )
          .getSingle();
      if (row.read<int>('n') == 1) return;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    fail('A segunda conexão não aguardou o bloqueio esperado');
  }

  Future<int> pid() async =>
      (await other.customSelect('SELECT pg_backend_pid() AS pid').getSingle())
          .read<int>('pid');

  for (final first in ['admin', 'professor', 'aluno']) {
    for (final second in ['admin', 'professor', 'aluno']) {
      test('email global $first/$second recusa criacao e edicao', () async {
        final email = 'global.$suffix.${++serial}@exemplo.test';
        final id = await insert(db, first, email.toUpperCase());
        expect(
          (await db
                  .customSelect(
                    'SELECT email::text AS email FROM $first WHERE id_$first = $id',
                  )
                  .getSingle())
              .read<String>('email'),
          email,
        );
        final collision = isA<pg.ServerException>().having(
          (e) => e.constraintName,
          'constraint',
          'uq_conta_email',
        );
        await expectLater(insert(other, second, email), throwsA(collision));
        final id2 = await insert(
          other,
          second,
          'other.$suffix.${++serial}@exemplo.test',
        );
        await expectLater(
          other.customStatement(
            'UPDATE $second SET email = \$1 WHERE id_$second = \$2',
            [email.toUpperCase(), id2],
          ),
          throwsA(collision),
        );
        if (first == 'professor') {
          expect(await AlunoRepository(db).emailEmUso(email), isTrue);
        }
      });
    }
  }
  test('duas criacoes concorrentes disputam o indice unico', () async {
    final email = 'race.$suffix@exemplo.test';
    final release = Completer<void>(), inserted = Completer<void>();
    final tx = db.transaction(() async {
      await insert(db, 'admin', email);
      inserted.complete();
      await release.future;
    });
    await inserted.future;
    final pending = expectLater(
      insert(other, 'professor', email),
      throwsA(isA<pg.ServerException>().having((e) => e.code, 'code', '23505')),
    );
    // O commit da primeira transacao arbitra a segunda insercao.
    release.complete();
    await tx;
    await pending;
  });
  for (final role in ['admin', 'professor', 'aluno']) {
    test(
      '$role troca de senha antes da insercao rejeita hash antigo',
      () async {
        final id = await insert(
          db,
          role,
          'password.$role.$suffix@exemplo.test',
        );
        final identity = Identidade(id: id, papel: Papel.values.byName(role));
        final token = TokenEmitido(
          token: 'test',
          jtiHash: '${role.length}' * 64,
          expiraEm: DateTime.now().toUtc().add(const Duration(hours: 1)),
        );
        final release = Completer<void>(), changed = Completer<void>();
        final tx = db.transaction(() async {
          await db.customStatement(
            'UPDATE $role SET senha_hash = \'new\' WHERE id_$role = \$1',
            [id],
          );
          changed.complete();
          await release.future;
        });
        await changed.future;
        final pending = expectLater(
          AuthRepository(other)
              .registrarSessao(token, identity, senhaHashEsperada: 'old'),
          throwsA(isA<CredencialAlterada>()),
        );
        release.complete();
        await tx;
        await pending;
        expect(
          await AuthRepository(other).sessaoAtiva(
            TokenValidado(
              identidade: identity,
              jtiHash: token.jtiHash,
              expiraEm: token.expiraEm,
            ),
          ),
          isFalse,
        );
      },
    );
    test(
      '$role troca iniciada antes mas concluida depois revoga login',
      () async {
        final id = await insert(db, role, 'reverse.$role.$suffix@exemplo.test');
        final identity = Identidade(id: id, papel: Papel.values.byName(role));
        final token = TokenEmitido(
          token: 'test',
          jtiHash: '${role.length}' * 64,
          expiraEm: DateTime.now().toUtc().add(const Duration(hours: 1)),
        );
        final started = Completer<void>(), update = Completer<void>();
        final backendPid = await pid();
        final password = other.transaction(() async {
          await other.customSelect('SELECT now()').get();
          started.complete();
          await update.future;
          await other.customStatement(
            'UPDATE $role SET senha_hash = \'new\' WHERE id_$role = \$1',
            [id],
          );
        });
        await started.future;
        await db.transaction(() async {
          await AuthRepository(db)
              .registrarSessao(token, identity, senhaHashEsperada: 'old');
          update.complete();
          await waitForLock(backendPid);
        });
        await password;
        expect(
          await AuthRepository(db).sessaoAtiva(
            TokenValidado(
              identidade: identity,
              jtiHash: token.jtiHash,
              expiraEm: token.expiraEm,
            ),
          ),
          isFalse,
        );
      },
    );
  }
}
