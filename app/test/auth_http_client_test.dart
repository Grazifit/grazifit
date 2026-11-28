import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grazifit_app/core/network/api_client.dart';
import 'package:grazifit_app/features/auth/state/auth_controller.dart';
import 'package:grazifit_app/features/auth/state/auth_state.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('Login e logout usam o mesmo cliente HTTP da aplicação', () async {
    final requisicoes = <http.Request>[];
    final cliente = MockClient((request) async {
      requisicoes.add(request);
      if (request.url.path == '/auth/logout') return http.Response('', 204);
      return http.Response(
        jsonEncode({
          'access_token': 'token-de-teste',
          'token_type': 'Bearer',
          'expires_in': 3600,
          'usuario': {'id': 1, 'papel': 'aluno', 'nome': 'Aluno'},
        }),
        200,
      );
    });
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWith(
          (ref) => ApiClient(
            client: cliente,
            baseUrl: 'https://example.test',
            token: () => ref.read(authControllerProvider).sessao?.accessToken,
          ),
        ),
      ],
    );
    addTearDown(cliente.close);
    addTearDown(container.dispose);

    final auth = container.read(authControllerProvider.notifier);
    await auth.login('aluno@example.test', 'senha-de-teste');
    expect(requisicoes.map((r) => r.url.path), ['/auth/login']);
    expect(requisicoes.single.headers['authorization'], isNull);
    expect(
      container.read(authControllerProvider).status,
      AuthStatus.autenticado,
    );

    await auth.sair();
    expect(requisicoes.last.url.path, '/auth/logout');
    expect(requisicoes.last.headers['authorization'], 'Bearer token-de-teste');
    expect(container.read(authControllerProvider).sessao, isNull);
  });
}
