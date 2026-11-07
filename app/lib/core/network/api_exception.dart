class ApiException implements Exception {
  const ApiException({
    this.statusCode,
    this.codigo,
    this.mensagem,
    this.retryAfter,
  });

  final int? statusCode;
  final String? codigo;
  final String? mensagem;
  final int? retryAfter;

  @override
  String toString() => 'ApiException(statusCode: $statusCode, codigo: $codigo)';
}
