import 'package:shared/erros/codigo_erro.dart';

class ApiException implements Exception {
  const ApiException({
    this.statusCode,
    this.codigo,
    this.mensagem,
    this.retryAfter,
    this.campo,
  });

  final int? statusCode;
  final String? codigo;
  final String? mensagem;
  final int? retryAfter;
  final String? campo;
  int get status => statusCode ?? 0;
  bool get semResposta => status == 0;
  CodigoErro? get codigoErro =>
      CodigoErro.values.where((c) => c.valor == codigo).firstOrNull;

  @override
  String toString() => 'ApiException(statusCode: $statusCode, codigo: $codigo)';
}
