import 'package:flutter_test/flutter_test.dart';
import 'package:grazifit_app/core/network/api_client.dart';
import 'package:grazifit_app/features/auth/data/auth_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('login envia credenciais e converte a sessão', () async {
    final repository = HttpAuthRepository(
      ApiClient(
        client: MockClient(
          (_) async => http.Response(
            '{"access_token":"jwt","token_type":"Bearer","expires_in":3600,'
            '"usuario":{"id":1,"papel":"admin","nome":"Admin"}}',
            200,
          ),
        ),
        baseUrl: 'http://localhost:8080',
      ),
    );

    final sessao = await repository.login(
      email: 'admin@exemplo.com',
      senha: 'correta',
    );

    expect(sessao.papel, 'admin');
    expect(sessao.accessToken, 'jwt');
  });
}
