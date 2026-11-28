import 'dart:convert';

import 'package:grazifit_backend/shared/http/swagger.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  test('Swagger UI carrega com o tema escuro ativo', () async {
    final router = await carregarSwagger();
    final resposta = await router.call(
      Request('GET', Uri.parse('http://localhost/swagger')),
    );
    final html = await resposta.readAsString();
    expect(html, contains('<html lang="pt-BR" class="dark-mode">'));
  });

  test('serve a interface e a especificação OpenAPI', () async {
    final router = await carregarSwagger();
    Future<Response> get(String path) =>
        router.call(Request('GET', Uri.parse('http://localhost$path')));

    final ui = await get('/swagger');
    expect(ui.statusCode, 200);
    expect(ui.headers['content-type'], startsWith('text/html'));
    expect(await ui.readAsString(), contains('swagger.json'));

    final resposta = await get('/swagger.json');
    expect(resposta.statusCode, 200);
    expect(resposta.headers['content-type'], startsWith('application/json'));
    final spec = jsonDecode(await resposta.readAsString()) as Map;
    expect(spec['openapi'], '3.0.3');
    expect(spec['security'], [
      {'bearerAuth': <String>[]},
    ]);
    expect(
      spec['paths'],
      containsPair(
        '/auth/login',
        containsPair('post', containsPair('security', isEmpty)),
      ),
    );
    expect(
      spec['paths'],
      containsPair(
        '/health',
        containsPair('get', containsPair('security', isEmpty)),
      ),
    );
  });
}
