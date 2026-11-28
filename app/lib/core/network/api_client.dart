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

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) =>
      _enviar('GET', path, query: query);

  /// [body] é um `Map` ou uma `List`, enviado como JSON na raiz.
  Future<Map<String, dynamic>> post(String path, Object body) =>
      postJson(path, body);

  /// [body] é um `Map` ou uma `List`, enviado como JSON na raiz.
  Future<Map<String, dynamic>> postJson(String path, Object body) =>
      _enviar('POST', path, body: body);

  /// [body] é um `Map` ou uma `List`, enviado como JSON na raiz.
  Future<Map<String, dynamic>> patch(String path, Object body) =>
      _enviar('PATCH', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _enviar('DELETE', path);

  /// Devolve o objeto JSON da resposta 2xx (`{}` para 204). Qualquer falha
  /// sobe como [ApiException].
  Future<Map<String, dynamic>> _enviar(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    if (body != null && body is! Map && body is! List) {
      throw ArgumentError.value(body, 'body', 'deve ser Map ou List');
    }
    if (baseUrl.trim().isEmpty) {
      throw const ApiException(codigo: 'CONFIGURACAO');
    }

    try {
      var uri = Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}$path');
      if (query != null && query.isNotEmpty) {
        uri = uri.replace(queryParameters: query);
      }
      final token = path == '/auth/login' ? null : this.token?.call();
      final request = http.Request(method, uri)
        ..headers.addAll({
          'Accept': 'application/json',
          if (body != null) 'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        });
      if (body != null) request.body = jsonEncode(body);

      final response = await http.Response.fromStream(
        await _client.send(request).timeout(timeout),
      );

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

      if (response.statusCode == 204 || response.body.isEmpty) return const {};
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
