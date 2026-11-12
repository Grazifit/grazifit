import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grazifit_app/core/network/api_client.dart';
import 'package:grazifit_app/core/network/api_exception.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared/erros/codigo_erro.dart';

void main() {
  test('erro de cadastro preserva campo e codigo tipado', () async {
    final api = ApiClient(
      baseUrl: 'http://localhost:8080',
      client: MockClient(
        (_) async =>
            http.Response('{"codigo":"EMAIL_EM_USO","campo":"email"}', 409),
      ),
    );
    await expectLater(
      api.post('/professor', {}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.codigoErro, 'codigoErro', CodigoErro.emailEmUso)
            .having((e) => e.campo, 'campo', 'email')
            .having((e) => e.status, 'status', 409)
            .having((e) => e.semResposta, 'semResposta', false),
      ),
    );
  });

  test('post do cadastro usa token atual e login nao envia Bearer', () async {
    final requests = <http.Request>[];
    String? token = 'sessao-1';
    final api = ApiClient(
      baseUrl: 'http://localhost:8080',
      token: () => token,
      client: MockClient((request) async {
        requests.add(request);
        return http.Response('{}', 200);
      }),
    );
    await api.post('/professor', {});
    token = 'sessao-2';
    await api.post('/professor', {});
    await api.postJson('/auth/login', {});
    expect(requests[0].headers['Authorization'], 'Bearer sessao-1');
    expect(requests[1].headers['Authorization'], 'Bearer sessao-2');
    expect(requests[2].headers.containsKey('Authorization'), isFalse);
  });

  test('envia JSON ao endpoint correto e converte resposta 200', () async {
    late http.Request requisicao;
    final client = MockClient((request) async {
      requisicao = request;
      return http.Response('{"ok":true}', 200);
    });

    final resposta = await ApiClient(
      client: client,
      baseUrl: 'http://localhost:8080',
    ).postJson('/auth/login', {'email': 'a@b.com', 'senha': 'segredo'});

    expect(requisicao.url.toString(), 'http://localhost:8080/auth/login');
    expect(requisicao.headers['Content-Type'], 'application/json');
    expect(jsonDecode(requisicao.body), {
      'email': 'a@b.com',
      'senha': 'segredo',
    });
    expect(resposta, {'ok': true});
  });

  test('converte 401 em ApiException tipada', () async {
    final api = ApiClient(
      client: MockClient(
        (_) async => http.Response(
          '{"codigo":"CREDENCIAIS_INVALIDAS","mensagem":"inválidas"}',
          401,
        ),
      ),
      baseUrl: 'http://localhost:8080',
    );

    await expectLater(
      api.postJson('/auth/login', const {}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.codigo, 'codigo', 'CREDENCIAIS_INVALIDAS'),
      ),
    );
  });

  test('converte 429 e Retry-After', () async {
    final api = ApiClient(
      client: MockClient(
        (_) async => http.Response(
          '{"codigo":"MUITAS_TENTATIVAS"}',
          429,
          headers: {'Retry-After': '15'},
        ),
      ),
      baseUrl: 'http://localhost:8080',
    );

    await expectLater(
      api.postJson('/auth/login', const {}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 429)
            .having((e) => e.retryAfter, 'retryAfter', 15),
      ),
    );
  });

  test('trata timeout como falha controlada', () async {
    final api = ApiClient(
      client: MockClient((_) => Completer<http.Response>().future),
      baseUrl: 'http://localhost:8080',
      timeout: Duration.zero,
    );

    await expectLater(
      api.postJson('/auth/login', const {}),
      throwsA(isA<ApiException>().having((e) => e.codigo, 'codigo', 'TIMEOUT')),
    );
  });

  test('trata erro de rede como falha controlada', () async {
    final api = ApiClient(
      client: MockClient((_) async => throw http.ClientException('offline')),
      baseUrl: 'http://localhost:8080',
    );

    await expectLater(
      api.postJson('/auth/login', const {}),
      throwsA(isA<ApiException>().having((e) => e.codigo, 'codigo', 'REDE')),
    );
  });

  test('trata JSON malformado como resposta inválida', () async {
    final api = ApiClient(
      client: MockClient((_) async => http.Response('não-json', 200)),
      baseUrl: 'http://localhost:8080',
    );

    await expectLater(
      api.postJson('/auth/login', const {}),
      throwsA(
        isA<ApiException>().having(
          (e) => e.codigo,
          'codigo',
          'RESPOSTA_INVALIDA',
        ),
      ),
    );
  });

  test('trata API_BASE_URL ausente', () async {
    final api = ApiClient(
      client: MockClient((_) async => http.Response('{}', 200)),
      baseUrl: '',
    );

    await expectLater(
      api.postJson('/auth/login', const {}),
      throwsA(
        isA<ApiException>().having((e) => e.codigo, 'codigo', 'CONFIGURACAO'),
      ),
    );
  });

  test('exceção não expõe senha nem token', () {
    const erro = ApiException(statusCode: 401, codigo: 'CREDENCIAIS_INVALIDAS');

    expect(erro.toString(), isNot(contains('segredo')));
    expect(erro.toString(), isNot(contains('token-jwt')));
  });
}
