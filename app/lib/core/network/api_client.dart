import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

class ApiClient {
  ApiClient({
    http.Client? client,
    this.baseUrl = const String.fromEnvironment('API_BASE_URL'),
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, Object?> body,
  ) async {
    if (baseUrl.trim().isEmpty) {
      throw const ApiException(codigo: 'CONFIGURACAO');
    }

    try {
      final uri = Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}$path');
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final erro = _decodeObjectOrEmpty(response.body);
        throw ApiException(
          statusCode: response.statusCode,
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
