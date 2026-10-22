import 'dart:convert';

import 'package:grazifit_backend/shared/middleware/limite_corpo.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  test('aceita exatamente o limite e entrega o mesmo corpo', () async {
    final corpo = List<int>.filled(16 * 1024, 65);
    final handler = const Pipeline()
        .addMiddleware(limiteCorpo())
        .addHandler(
          (request) async => Response.ok(await request.readAsString()),
        );

    final resposta = await handler(
      Request('POST', Uri.parse('http://localhost/aluno'), body: corpo),
    );
    expect(resposta.statusCode, 200);
    expect((await resposta.readAsString()).length, corpo.length);
  });

  test('recusa 16 KiB + 1 sem chamar o handler', () async {
    var chamou = false;
    final handler = const Pipeline().addMiddleware(limiteCorpo()).addHandler((
      _,
    ) {
      chamou = true;
      return Response.ok('nao deveria');
    });

    final resposta = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/aluno'),
        body: Stream<List<int>>.fromIterable([
          List<int>.filled(8000, 65),
          List<int>.filled(8385, 66),
        ]),
      ),
    );
    expect(resposta.statusCode, 413);
    expect(chamou, isFalse);
    expect(
      (jsonDecode(await resposta.readAsString()) as Map)['codigo'],
      'CORPO_MUITO_GRANDE',
    );
  });

  test('Content-Length acima do teto e recusado antes de ler', () async {
    var chamou = false;
    final handler = const Pipeline().addMiddleware(limiteCorpo()).addHandler((
      _,
    ) {
      chamou = true;
      return Response.ok('nao deveria');
    });
    final resposta = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/aluno'),
        headers: {'Content-Length': '${16 * 1024 + 1}'},
        body: const <int>[],
      ),
    );
    expect(resposta.statusCode, 413);
    expect(chamou, isFalse);
  });
}
