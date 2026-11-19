import 'dart:convert';

import 'package:shared/erros/codigo_erro.dart';
import 'package:shelf/shelf.dart';

import '../erros/status_http.dart';

/// Helpers HTTP comuns aos controllers. O formato do erro e o envelope
/// `{codigo, mensagem, campo?}`. Textos de apoio por feature ficam no
/// proprio controller: aqui so entra o que nao depende de feature.

Response jsonResposta(
  int status,
  Object corpo, {
  Map<String, String>? headers,
}) => Response(
  status,
  body: jsonEncode(corpo),
  headers: {'Content-Type': 'application/json', ...?headers},
);

Response envelopeErro(
  CodigoErro codigo, {
  required String mensagem,
  String? campo,
  Map<String, String>? headers,
}) => jsonResposta(statusHttp(codigo), {
  'codigo': codigo.valor,
  'mensagem': mensagem,
  'campo': ?campo,
}, headers: headers);

Response campoInvalido(String campo, String mensagem) =>
    envelopeErro(CodigoErro.campoInvalido, campo: campo, mensagem: mensagem);

/// Corpo que nao e um objeto JSON vira `null`.
Future<Map<String, dynamic>?> lerObjetoJson(Request req) async {
  try {
    final corpo = jsonDecode(await req.readAsString());
    return corpo is Map<String, dynamic> ? corpo : null;
  } on FormatException {
    return null;
  }
}

/// Primeira chave fora de [aceitos], como `CAMPO_INVALIDO`. `null` se todas
/// forem aceitas.
Response? chaveDesconhecida(
  Map<String, dynamic> payload,
  List<String> aceitos,
) {
  final chave = payload.keys.where((k) => !aceitos.contains(k)).firstOrNull;
  if (chave == null) return null;
  return campoInvalido(
    chave,
    'Campo nao aceito. Aceitos: ${aceitos.join(', ')}.',
  );
}

/// Falha nao mapeada: registra no stdout (como o resto da base) e responde
/// `ERRO_INTERNO` sem detalhe ao cliente.
Response erroInterno(
  Object erro,
  StackTrace stackTrace, {
  required String rotulo,
}) {
  // ignore: avoid_print
  print('Erro em $rotulo: $erro');
  // ignore: avoid_print
  print(stackTrace);
  return envelopeErro(
    CodigoErro.erroInterno,
    mensagem: 'Erro interno no servidor.',
  );
}
