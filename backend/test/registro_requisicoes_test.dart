import 'package:grazifit_backend/shared/middleware/registro_requisicoes.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  test('log do login nao inclui query, senha, token ou corpo', () async {
    final linhas = <String>[];
    final handler = registroRequisicoes(registrar: linhas.add)(
      (_) async => Response(401),
    );

    await handler(
      Request(
        'POST',
        Uri.parse(
          'http://localhost/auth/login?senha=segredo&token=nao-registrar',
        ),
        headers: {'Authorization': 'Bearer segredo-token'},
        body: 'senha=outra-senha',
      ),
    );

    expect(linhas, hasLength(1));
    expect(linhas.single, contains('POST /auth/login [401]'));
    expect(linhas.single, isNot(contains('segredo')));
    expect(linhas.single, isNot(contains('token')));
    expect(linhas.single, isNot(contains('?')));
  });
}
