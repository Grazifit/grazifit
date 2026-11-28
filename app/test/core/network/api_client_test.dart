import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grazifit_app/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  http.Request? enviada;

  ApiClient cliente({int status = 200, String corpo = '{}'}) {
    enviada = null;
    return ApiClient(
      baseUrl: 'http://api.teste',
      client: MockClient((request) async {
        enviada = request;
        return http.Response(corpo, status);
      }),
    );
  }

  group('corpo lista', () {
    final lista = [
      {'id_aluno': 1, 'presente': true},
      {'id_aluno': 2, 'presente': false},
    ];

    test('patch envia a lista na raiz com Content-Type JSON', () async {
      await cliente().patch('/aulas/7/presencas', lista);

      expect(enviada!.method, 'PATCH');
      expect(enviada!.body, jsonEncode(lista));
      expect(jsonDecode(enviada!.body), isA<List<dynamic>>());
      expect(enviada!.headers['Content-Type'], startsWith('application/json'));
    });

    test('post e postJson enviam a lista na raiz', () async {
      final api = cliente();
      await api.post('/x', lista);
      expect(enviada!.method, 'POST');
      expect(enviada!.body, jsonEncode(lista));
      expect(enviada!.headers['Content-Type'], startsWith('application/json'));

      await api.postJson('/x', lista);
      expect(enviada!.body, jsonEncode(lista));
    });

    test('204 devolve {}', () async {
      expect(await cliente(status: 204, corpo: '').patch('/x', lista), {});
    });

    test('2xx sem corpo devolve {}', () async {
      expect(await cliente(corpo: '').post('/x', lista), {});
    });
  });

  group('corpo mapa', () {
    final mapa = {'nome': 'Ana', 'email': 'ana@x.com'};

    test('post envia o objeto e devolve o JSON da resposta', () async {
      final resposta = await cliente(corpo: '{"id": 3}').post('/x', mapa);

      expect(enviada!.method, 'POST');
      expect(enviada!.body, jsonEncode(mapa));
      expect(enviada!.headers['Content-Type'], startsWith('application/json'));
      expect(resposta, {'id': 3});
    });

    test('patch envia o objeto', () async {
      await cliente().patch('/x', mapa);

      expect(enviada!.method, 'PATCH');
      expect(enviada!.body, jsonEncode(mapa));
      expect(enviada!.headers['Content-Type'], startsWith('application/json'));
    });

    test('204 devolve {}', () async {
      expect(await cliente(status: 204, corpo: '').patch('/x', mapa), {});
    });
  });

  test('corpo que não é Map nem List é rejeitado', () {
    expect(() => cliente().post('/x', 'texto'), throwsArgumentError);
  });
}
