@Timeout(Duration(minutes: 2))
library;

import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/avaliacoes/avaliacao_controller.dart';
import 'package:grazifit_backend/features/avaliacoes/avaliacao_repository.dart';
import 'package:grazifit_backend/features/avaliacoes/avaliacao_service.dart';
import 'package:grazifit_backend/features/pessoas/aluno/aluno_repository.dart';
import 'package:grazifit_backend/shared/autorizacao/identidade.dart';
import 'package:grazifit_backend/shared/middleware/identidade_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  late GraziDatabase db;
  late Handler handler;
  late int id;
  var serial = 0;
  const admin = Identidade(id: 1, papel: Papel.admin);
  Future<Response> request(
    String method,
    String suffix, {
    Object? body,
    Identidade? identity = admin,
    int? aluno,
  }) async => handler(
    Request(
      method,
      Uri.parse('http://localhost/aluno/${aluno ?? id}/avaliacoes$suffix'),
      body: body == null ? null : jsonEncode(body),
      context: {chaveIdentidadeContexto: ?identity},
    ),
  );
  Future<Map<String, dynamic>> data(Response response) async =>
      jsonDecode(await response.readAsString()) as Map<String, dynamic>;
  setUpAll(() {
    db = GraziDatabase.doAmbiente();
    handler = AvaliacaoController(AvaliacaoService(AvaliacaoRepository(db)))
        .router
        .call;
  });
  setUp(() async {
    serial++;
    final aluno = await AlunoRepository(db).create(
      cpf: (87000000000 + serial).toString(),
      senhaHash: 'teste',
      nome: 'Avaliacao Teste',
      dataNascimento: DateTime(1995, 1, 1),
      telefone: '11900000000',
      email: 'avaliacao$serial@example.test',
    );
    id = aluno.idAluno;
  });
  tearDown(() async {
    await db.customStatement('DELETE FROM avaliacao WHERE id_aluno = \$1', [
      id,
    ]);
    await db.customStatement('DELETE FROM aluno WHERE id_aluno = \$1', [id]);
  });
  tearDownAll(() => db.close());

  test('aluno grava e sobrescreve o dia; banco gera IMC', () async {
    final identity = Identidade(id: id, papel: Papel.aluno);
    final first = await request(
      'POST',
      '/hoje',
      identity: identity,
      body: {'peso': 70, 'altura': 1.75, 'observacao': '  inicial  '},
    );
    expect(first.statusCode, 200);
    final created = await data(first);
    expect(created['imc'], 22.86);
    expect(created['observacao'], 'inicial');
    final today = await db
        .customSelect(
          "SELECT to_char((statement_timestamp() AT TIME ZONE 'America/Sao_Paulo')::date, 'YYYY-MM-DD') AS hoje",
        )
        .getSingle();
    expect(created['data_avaliacao'], today.read<String>('hoje'));
    final updated = await data(
      await request(
        'POST',
        '/hoje',
        identity: identity,
        body: {'peso': 80, 'altura': 2},
      ),
    );
    expect(updated['id_avaliacao'], created['id_avaliacao']);
    expect(updated['imc'], 20);
    expect(updated['observacao'], isNull);
    expect((await data(await request('GET', '')))['total'], 1);
  });

  test('historico ordenado e paginado; atual retorna ultima medida', () async {
    await db.customStatement(
      "INSERT INTO avaliacao (id_aluno, data_avaliacao, peso, altura) VALUES (\$1, '2020-01-01', 70, 1.75), (\$1, '2020-01-02', 80, 2)",
      [id],
    );
    final page = await data(await request('GET', '?limit=1&offset=1'));
    expect(page['total'], 2);
    expect(
      ((page['itens'] as List).single
          as Map<String, dynamic>)['data_avaliacao'],
      '2020-01-01',
    );
    expect(
      (await data(await request('GET', '/atual')))['data_avaliacao'],
      '2020-01-02',
    );
    final empty = await data(await request('GET', '?offset=20'));
    expect(empty['total'], 2);
    expect(empty['itens'], isEmpty);
  });

  test('POST de hoje preserva avaliacoes dos dias anteriores', () async {
    await db.customStatement(
      "INSERT INTO avaliacao (id_aluno, data_avaliacao, peso, altura) VALUES (\$1, (statement_timestamp() AT TIME ZONE 'America/Sao_Paulo')::date - 1, 70, 1.75)",
      [id],
    );
    final response = await request(
      'POST',
      '/hoje',
      body: {'peso': 80, 'altura': 2},
    );
    expect(response.statusCode, 200);
    final page = await data(await request('GET', ''));
    expect(page['total'], 2);
    final items = (page['itens'] as List).cast<Map<String, dynamic>>();
    expect(items.first['peso'], 80);
    expect(items.last['peso'], 70);
    expect(items.last['imc'], 22.86);
    expect(items.first['id_avaliacao'], isNot(items.last['id_avaliacao']));
  });

  test('sem medidas e aluno inexistente', () async {
    expect((await request('GET', '/atual')).statusCode, 204);
    expect((await data(await request('GET', '')))['total'], 0);
    expect((await request('GET', '', aluno: 2147483647)).statusCode, 404);
  });

  test('permissoes em todas as operacoes', () async {
    for (final (method, path) in [
      ('GET', ''),
      ('GET', '/atual'),
      ('POST', '/hoje'),
    ]) {
      final body = method == 'POST' ? {'peso': 70, 'altura': 1.75} : null;
      expect(
        (await request(method, path, body: body, identity: null)).statusCode,
        401,
      );
      for (final identity in [
        Identidade(id: id + 1, papel: Papel.aluno),
        Identidade(id: id, papel: Papel.professor),
      ]) {
        expect(
          (await request(
            method,
            path,
            body: body,
            identity: identity,
          )).statusCode,
          403,
        );
      }
    }
  });

  test('aluno inativo permite leitura mas nao escrita', () async {
    await db.customStatement(
      'UPDATE aluno SET status = false WHERE id_aluno = \$1',
      [id],
    );
    expect(
      (await request(
        'POST',
        '/hoje',
        body: {'peso': 70, 'altura': 1.75},
      )).statusCode,
      403,
    );
    expect((await request('GET', '')).statusCode, 200);
  });

  test('entrada invalida e overflow do IMC nao persistem', () async {
    for (final body in <Object>[
      [],
      {},
      {'peso': '70', 'altura': 1.75},
      {'peso': 70, 'altura': 0},
      {'peso': 500, 'altura': 1.75},
      {'peso': 70, 'altura': 3},
      {'peso': 70.001, 'altura': 1.75},
      {'peso': 70, 'altura': 1.75, 'imc': 20},
      {'peso': 70, 'altura': 1.75, 'data_avaliacao': '2020-01-01'},
      {'peso': 70, 'altura': 1.75, 'observacao': 'x' * 2001},
      {'peso': 70, 'altura': 0.01},
    ]) {
      expect(
        (await request('POST', '/hoje', body: body)).statusCode,
        400,
        reason: '$body',
      );
    }
    for (final query in ['?limit=0', '?limit=101', '?offset=-1', '?limit=a']) {
      expect((await request('GET', query)).statusCode, 400);
    }
    expect((await data(await request('GET', '')))['total'], 0);
  });

  test('gravacoes concorrentes mantem uma unica avaliacao diaria', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final other = GraziDatabase.doAmbiente();
    try {
      final results = await Future.wait([
        AvaliacaoRepository(db).salvarHoje(id, peso: 70, altura: 1.75),
        AvaliacaoRepository(other).salvarHoje(id, peso: 80, altura: 2),
      ]);
      expect(results.first.idAvaliacao, results.last.idAvaliacao);
      final page = await data(await request('GET', ''));
      expect(page['total'], 1);
      final item = (page['itens'] as List).single as Map<String, dynamic>;
      expect(item['imc'], item['peso'] == 70 ? 22.86 : 20);
    } finally {
      await other.close();
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
    }
  });
}
