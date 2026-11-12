import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/state/auth_controller.dart';

import 'api_exception.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    client: ref.watch(httpClientProvider),
    token: () => ref.read(authControllerProvider).sessao?.accessToken,
  ),
);

class ApiClient {
  ApiClient({
    http.Client? client,
    this.token,
    this.baseUrl = const String.fromEnvironment('API_BASE_URL'),
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;
  final String? Function()? token;

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      postJson(path, body);

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, Object?> body,
  ) async {
    if (baseUrl.trim().isEmpty) {
      throw const ApiException(codigo: 'CONFIGURACAO');
    }

    try {
      final uri = Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}$path');
      final token = path == '/auth/login' ? null : this.token?.call();
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final erro = _decodeObjectOrEmpty(response.body);
        throw ApiException(
          statusCode: response.statusCode,
          campo: erro['campo'] is String ? erro['campo'] as String : null,
          codigo: erro['codigo'] is String ? erro['codigo'] as String : null,
          mensagem: erro['mensagem'] is String
              ? erro['mensagem'] as String
              : null,
          retryAfter: int.tryParse(
            response.headers.entries
                    .where((entry) => entry.key.toLowerCase() == 'retry-after')
                    .map((entry) => entry.value)
                    .firstOrNull ??
                '',
          ),
        );
      }

      return _decodeObject(response.body);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(codigo: 'TIMEOUT');
    } on http.ClientException {
      throw const ApiException(codigo: 'REDE');
    } on FormatException {
      throw const ApiException(codigo: 'RESPOSTA_INVALIDA');
    }
  }

  Map<String, dynamic> _decodeObject(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Resposta JSON não é um objeto');
    }
    return decoded;
  }

  Map<String, dynamic> _decodeObjectOrEmpty(String source) {
    try {
      return _decodeObject(source);
    } on FormatException {
      return const {};
    }
  }
}
