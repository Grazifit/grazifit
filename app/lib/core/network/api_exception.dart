import 'package:shared/erros/codigo_erro.dart';

class ApiException implements Exception {
  const ApiException({
    this.statusCode,
    this.codigo,
    this.mensagem,
    this.retryAfter,
    this.campo,
  });

  /// Endpoint que o backend ainda não entregou. O app nem chama a rede: a
  /// tela cai no estado de erro. Ver docs/integracao-frontend.md.
  const ApiException.pendente()
      : statusCode = 501,
        codigo = 'ENDPOINT_PENDENTE',
        mensagem = null,
        retryAfter = null,
        campo = null;

  final int? statusCode;
  final String? codigo;
  final String? mensagem;
  final int? retryAfter;
  final String? campo;
  int get status => statusCode ?? 0;
  bool get pendente => codigo == 'ENDPOINT_PENDENTE';
  bool get semResposta => status == 0;
  CodigoErro? get codigoErro =>
      CodigoErro.values.where((c) => c.valor == codigo).firstOrNull;

  @override
  String toString() => 'ApiException(statusCode: $statusCode, codigo: $codigo)';
}
