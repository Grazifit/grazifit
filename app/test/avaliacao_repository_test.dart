import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:grazifit_app/core/network/api_client.dart';
import 'package:grazifit_app/features/avaliacoes/data/avaliacao_repository.dart';

void main() {
  Map<String, dynamic> medida(String data, double imc) => {
    'data_avaliacao': data,
    'peso': 70,
    'altura': 1.75,
    'imc': imc,
    'observacao': null,
  };
  test(
    'historico pagina e ordena por data preservando o IMC recebido',
    () async {
      final offsets = <String>[];
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer token-teste');
        offsets.add(request.url.queryParameters['offset']!);
        return http.Response(
          jsonEncode({
            'itens': [
              medida(offsets.length == 1 ? '2026-11-13' : '2026-11-12', 22.86),
            ],
            'total': 2,
          }),
          200,
        );
      });
      final repo = AvaliacaoRepository(
        ApiClient(
          client: client,
          baseUrl: 'http://localhost',
          token: () => 'token-teste',
        ),
      );
      final items = await repo.historico(7);
      expect(offsets, ['0', '1']);
      expect(items.map((m) => m.data), ['2026-11-12', '2026-11-13']);
      expect(items.first.imc, 22.86);
    },
  );
  test('salva com POST sem enviar IMC ou data', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/aluno/7/avaliacoes/hoje');
      expect(jsonDecode(request.body), {
        'peso': 70.0,
        'altura': 1.75,
        'observacao': 'teste',
      });
      return http.Response(jsonEncode(medida('2026-11-13', 22.86)), 200);
    });
    final repo = AvaliacaoRepository(
      ApiClient(client: client, baseUrl: 'http://localhost'),
    );
    expect(
      (await repo.salvar(7, peso: 70, altura: 1.75, observacao: 'teste')).imc,
      22.86,
    );
  });
  test('204 na avaliacao atual representa ausencia de medidas', () async {
    final repo = AvaliacaoRepository(
      ApiClient(
        baseUrl: 'http://localhost',
        client: MockClient((_) async => http.Response('', 204)),
      ),
    );
    expect(await repo.atual(7), isNull);
  });
}
