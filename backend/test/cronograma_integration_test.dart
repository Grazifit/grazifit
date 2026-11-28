@Timeout(Duration(minutes: 2))
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart'
    show QueryInterceptor, QueryExecutor, ApplyInterceptor, Variable;
import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart' as pg;

import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/cronogramas/cronograma_controller.dart';
import 'package:grazifit_backend/features/cronogramas/cronograma_repository.dart';
import 'package:grazifit_backend/features/cronogramas/cronograma_service.dart';
import 'package:grazifit_backend/shared/autorizacao/identidade.dart';
import 'package:grazifit_backend/shared/middleware/identidade_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  late GraziDatabase db;
  late Handler handler;
  late int adminId, professorId;
  final ids = <int>[];
  final consultas = _ContadorSelects();
  Map<String, dynamic> payload() => {
    'id_professor': professorId,
    'categoria': 'pilates',
    'hora_inicio': '08:00',
    'hora_fim': '09:00',
    'data_inicio': '2026-01-01',
    'dias_semana': [1, 3, 5],
    'vagas_maxima': 10,
  };
  Future<Response> req(
    String method,
    String path, {
    Object? body,
    Papel papel = Papel.admin,
    bool autenticado = true,
  }) async => handler(
    Request(
      method,
      Uri.parse('http://localhost/cronogramas$path'),
      body: body == null ? null : jsonEncode(body),
      context: {
        if (autenticado)
          chaveIdentidadeContexto: Identidade(id: adminId, papel: papel),
      },
    ),
  );
  Future<Map<String, dynamic>> json(Response r) async =>
      jsonDecode(await r.readAsString()) as Map<String, dynamic>;
  Future<int> criar() async {
    final response = await req('POST', '', body: payload());
    expect(response.statusCode, 201);
    final data = await json(response);
    final id = data['id_cronograma'] as int;
    ids.add(id);
    expect(data['dias_semana'], [1, 3, 5]);
    expect(data['id_admin_criador'], adminId);
    return id;
  }

  setUpAll(() async {
    final conexao = traduzirDatabaseUrl(Platform.environment['DATABASE_URL']!);
    db = GraziDatabase(
      PgDatabase(
        endpoint: conexao.endpoint,
        settings: pg.ConnectionSettings(sslMode: conexao.sslMode),
        enableMigrations: false,
      ).interceptWith(consultas),
    );
    handler = CronogramaController(CronogramaService(CronogramaRepository(db)))
        .router
        .call;
    final admin = await db.customWriteReturning(
      "INSERT INTO admin (cpf,nome,email,senha_hash) VALUES ('86000000001','Cronograma','cronograma-admin@example.test','hash') RETURNING id_admin",
      updates: {},
    );
    adminId = admin.single.read<int>('id_admin');
    final professor = await db.customWriteReturning(
      "INSERT INTO professor (cpf,nome,email,senha_hash,telefone) VALUES ('86000000002','Professor','cronograma-prof@example.test','hash','11900000000') RETURNING id_professor",
      updates: {},
    );
    professorId = professor.single.read<int>('id_professor');
  });
  tearDown(() async {
    for (final id in ids) {
      await db.customStatement('DELETE FROM aula WHERE id_cronograma = \$1', [
        id,
      ]);
      await db.customStatement(
        'DELETE FROM cronograma WHERE id_cronograma = \$1',
        [id],
      );
    }
    ids.clear();
    await db.customStatement(
      'UPDATE professor SET status = true WHERE id_professor = \$1',
      [professorId],
    );
  });
  tearDownAll(() async {
    await db.customStatement('DELETE FROM professor WHERE id_professor = \$1', [
      professorId,
    ]);
    await db.customStatement('DELETE FROM admin WHERE id_admin = \$1', [
      adminId,
    ]);
    await db.close();
  });
  test('pagina de 100 usa tres SELECTs e preserva dias e ordenacao', () async {
    final rows = await db.customWriteReturning(
      "INSERT INTO cronograma (id_admin_criador,id_professor,categoria,hora_inicio,hora_fim,data_inicio,vagas_maxima,status) SELECT \$1,\$2,'pilates','08:00','09:00','2026-01-01'::date + (n % 3),10,n <= 100 FROM generate_series(1,105) n RETURNING id_cronograma",
      variables: [Variable.withInt(adminId), Variable.withInt(professorId)],
      updates: {},
    );
    ids.addAll(rows.map((row) => row.read<int>('id_cronograma')));
    for (var i = 0; i < ids.length; i++) {
      await db.customStatement('INSERT INTO cronograma_dia VALUES (\$1,\$2)', [
        ids[i],
        i % 7,
      ]);
    }
    final repository = CronogramaRepository(db);
    Future<Map<String, dynamic>> antigo() => repository.transacao(() async {
      await db.customStatement(
        'SET TRANSACTION ISOLATION LEVEL REPEATABLE READ',
      );
      final total =
          (await db
                  .customSelect(
                    'SELECT count(*) AS total FROM cronograma WHERE status = TRUE',
                  )
                  .getSingle())
              .read<int>('total');
      final pagina = await db
          .customSelect(
            'SELECT id_cronograma FROM cronograma WHERE status = TRUE ORDER BY data_inicio DESC, id_cronograma DESC LIMIT 100 OFFSET 0',
          )
          .get();
      final itens = <Map<String, dynamic>>[];
      for (final row in pagina) {
        itens.add(
          (await repository.buscar(row.read<int>('id_cronograma')))!.toJson(),
        );
      }
      return {'itens': itens, 'total': total, 'limit': 100, 'offset': 0};
    });
    Future<Map<String, dynamic>> novo() =>
        repository.transacao(() => repository.listar(100, 0, true));
    await antigo();
    await novo();
    final antes = <int>[];
    final depois = <int>[];
    for (var i = 0; i < 5; i++) {
      consultas.total = 0;
      final timer = Stopwatch()..start();
      final esperado = await antigo();
      timer.stop();
      antes.add(timer.elapsedMicroseconds);
      expect(consultas.total, 202);
      consultas.total = 0;
      timer.reset();
      timer.start();
      final resultado = await novo();
      timer.stop();
      depois.add(timer.elapsedMicroseconds);
      expect(consultas.total, 3);
      expect(resultado, esperado);
      expect((resultado['itens'] as List).length, 100);
    }
    antes.sort();
    depois.sort();
    print(
      'Q6: 100 itens, 5 amostras apos aquecimento; SELECTs 202 -> 3; mediana ${antes[2] / 1000} ms -> ${depois[2] / 1000} ms (transacao incluida).',
    );
    consultas.total = 0;
    final vazia = await repository.transacao(
      () => repository.listar(100, 100, true),
    );
    expect(vazia['total'], 100);
    expect(vazia['itens'], isEmpty);
    expect(consultas.total, 2);
  });

  test('CRUD completo e substituicao atomica dos dias', () async {
    final id = await criar();
    expect((await req('GET', '/$id')).statusCode, 200);
    final updated = await req(
      'PATCH',
      '/$id',
      body: {
        'dias_semana': [2, 4],
        'data_fim': '2026-12-31',
      },
    );
    expect(updated.statusCode, 200);
    expect((await json(updated))['dias_semana'], [2, 4]);
    final cleared = await req('PATCH', '/$id', body: {'data_fim': null});
    expect((await json(cleared))['data_fim'], isNull);
    expect((await req('DELETE', '/$id')).statusCode, 204);
    expect((await req('GET', '/$id')).statusCode, 404);
    expect(
      (await db
              .customSelect(
                'SELECT count(*) AS n FROM cronograma_dia WHERE id_cronograma = $id',
              )
              .getSingle())
          .read<int>('n'),
      0,
    );
  });
  test('lista pagina e filtra inativos', () async {
    final id = await criar();
    await req('PATCH', '/$id', body: {'status': false});
    final page = await json(await req('GET', '?status=false&limit=1&offset=0'));
    expect(page['total'], 1);
    expect((page['itens'] as List).length, 1);
    expect(
      (await json(await req('GET', '?status=false&offset=10')))['itens'],
      isEmpty,
    );
    expect((await req('GET', '?limit=101')).statusCode, 400);
    expect((await req('GET', '?offset=-1')).statusCode, 400);
    expect((await req('GET', '?status=xyz')).statusCode, 400);
  });
  test('rejeita formatos e regras invalidas sem persistir', () async {
    for (final changes in <Map<String, dynamic>>[
      {'dias_semana': <int>[]},
      {
        'dias_semana': [1, 1],
      },
      {
        'dias_semana': [7],
      },
      {
        'dias_semana': [true],
      },
      {'data_inicio': '2026-02-30'},
      {'data_fim': '2025-12-31'},
      {'hora_fim': '07:00'},
      {'hora_inicio': '25:00'},
      {'vagas_maxima': 0},
      {'vagas_maxima': 1.5},
      {'categoria': 'invalida'},
      {'id_professor': 2147483647},
      {'status': null},
      {'id_admin_criador': 1},
    ]) {
      expect(
        (await req('POST', '', body: {...payload(), ...changes})).statusCode,
        400,
        reason: '$changes',
      );
    }
    expect((await req('POST', '', body: [])).statusCode, 400);
    expect((await req('POST', '', body: {})).statusCode, 400);
    expect((await json(await req('GET', '')))['total'], 0);
  });
  test(
    'professor inativo nao recebe cronograma; inativacao continua permitida',
    () async {
      final id = await criar();
      await db.customStatement(
        'UPDATE professor SET status = false WHERE id_professor = \$1',
        [professorId],
      );
      expect((await req('POST', '', body: payload())).statusCode, 400);
      expect(
        (await req('PATCH', '/$id', body: {'status': false})).statusCode,
        200,
      );
      expect(
        (await req('PATCH', '/$id', body: {'status': true})).statusCode,
        400,
      );
    },
  );
  test(
    'aulas vinculadas bloqueiam edicao e exclusao mas permitem inativar',
    () async {
      final id = await criar();
      await db.customStatement(
        "INSERT INTO aula (id_professor,id_cronograma,data,hora_inicio,hora_fim,tipo,categoria,vagas_maxima) VALUES (\$1,\$2,'2026-01-05','08:00','09:00','coletiva','pilates',10)",
        [professorId, id],
      );
      expect(
        (await req(
          'PATCH',
          '/$id',
          body: {'categoria': 'funcional'},
        )).statusCode,
        409,
      );
      expect((await req('DELETE', '/$id')).statusCode, 409);
      expect(
        (await req('PATCH', '/$id', body: {'status': false})).statusCode,
        200,
      );
      expect(
        (await db
                .customSelect(
                  'SELECT status FROM aula WHERE id_cronograma = $id',
                )
                .getSingle())
            .read<bool>('status'),
        true,
      );
    },
  );
  test('autorizacao em todas as rotas e recursos inexistentes', () async {
    for (final (method, path) in [
      ('POST', ''),
      ('GET', ''),
      ('GET', '/1'),
      ('PATCH', '/1'),
      ('DELETE', '/1'),
    ]) {
      expect(
        (await req(
          method,
          path,
          body: payload(),
          autenticado: false,
        )).statusCode,
        401,
      );
      for (final papel in [Papel.aluno, Papel.professor]) {
        expect(
          (await req(method, path, body: payload(), papel: papel)).statusCode,
          403,
        );
      }
    }
    for (final method in ['GET', 'PATCH', 'DELETE']) {
      expect(
        (await req(method, '/2147483647', body: {'status': false})).statusCode,
        404,
      );
    }
  });
  test('PATCH invalido preserva cronograma e dias anteriores', () async {
    final id = await criar();
    expect(
      (await req(
        'PATCH',
        '/$id',
        body: {
          'dias_semana': [2],
          'hora_fim': '07:00',
        },
      )).statusCode,
      400,
    );
    final original = await json(await req('GET', '/$id'));
    expect(original['dias_semana'], [1, 3, 5]);
    expect(original['hora_fim'], '09:00');
  });
}

class _ContadorSelects extends QueryInterceptor {
  int total = 0;
  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    total++;
    return executor.runSelect(statement, args);
  }
}
