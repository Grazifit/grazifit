import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Base da API, injetada em build: `--dart-define=API_BASE_URL=...`.
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

/// Token Bearer da sessão. Ponto de injeção: quem implementar o login
/// (F-01 no app) grava aqui o token devolvido por `POST /auth/login`.
///
/// Em desenvolvimento, `--dart-define=DEV_TOKEN=...` preenche o valor
/// inicial. Atalho de dev: remover quando o login estiver integrado.
final tokenProvider = StateProvider<String?>((ref) {
  const tokenDev = String.fromEnvironment('DEV_TOKEN');
  return tokenDev.isEmpty ? null : tokenDev;
});

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    client: ref.watch(httpClientProvider),
    token: () => ref.read(tokenProvider),
  );
});

class ApiClient {
  ApiClient({
    required this._client,
    required this._token,
    this._baseUrl = apiBaseUrl,
  });

  final http.Client _client;
  final String? Function() _token;
  final String _baseUrl;

  static const _prazo = Duration(seconds: 15);

  /// POST com corpo JSON. Devolve o JSON de objeto da resposta 2xx; qualquer
  /// outra coisa vira [ApiException].
  Future<Map<String, dynamic>> post(
    String caminho,
    Map<String, dynamic> corpo,
  ) async {
    final token = _token();
    final http.Response resposta;
    try {
      resposta = await _client
          .post(
            Uri.parse('$_baseUrl$caminho'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(corpo),
          )
          .timeout(_prazo);
    } catch (_) {
      throw const ApiException.semConexao();
    }

    final json = _decodificar(resposta.body);
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      if (json == null) throw ApiException(status: resposta.statusCode);
      return json;
    }

    throw ApiException(
      status: resposta.statusCode,
      codigo: ApiException.codigoDe(json?['codigo']),
      campo: json?['campo'] as String?,
      mensagem: (json?['mensagem'] ?? json?['erro']) as String?,
    );
  }

  Map<String, dynamic>? _decodificar(String corpo) {
    if (corpo.isEmpty) return null;
    try {
      final decodificado = jsonDecode(corpo);
      return decodificado is Map<String, dynamic> ? decodificado : null;
    } catch (_) {
      return null;
    }
  }
}
