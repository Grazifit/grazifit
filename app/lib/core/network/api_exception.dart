import 'package:shared/erros/codigo_erro.dart';

/// Falha devolvida pela API. A tela escolhe o texto a partir de [codigo],
/// jamais de [mensagem] (D64). [codigo] é nulo quando a resposta não segue
/// o envelope `{ codigo, mensagem, campo? }` ou o código é desconhecido.
class ApiException implements Exception {
  const ApiException({
    required this.status,
    this.codigo,
    this.campo,
    this.mensagem,
  });

  /// Sem resposta HTTP: rede fora do ar, CORS bloqueado, timeout.
  const ApiException.semConexao()
      : status = 0,
        codigo = null,
        campo = null,
        mensagem = null;

  final int status;
  final CodigoErro? codigo;
  final String? campo;

  /// Só para log. Nunca exibir.
  final String? mensagem;

  bool get semResposta => status == 0;

  static CodigoErro? codigoDe(Object? valor) {
    for (final c in CodigoErro.values) {
      if (c.valor == valor) return c;
    }
    return null;
  }

  @override
  String toString() => 'ApiException($status, ${codigo?.valor}, $campo)';
}
