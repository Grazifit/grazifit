import 'dart:io';

import 'package:shelf/shelf.dart';

/// Registra metodo, caminho e status, nunca query string, headers ou corpo.
/// Assim tentativas de login ficam auditaveis sem senha ou token no log.
Middleware registroRequisicoes({void Function(String)? registrar}) {
  final void Function(String) registrarLinha =
      registrar ?? (linha) => stdout.writeln(linha);
  return (innerHandler) => (request) async {
    var status = 500;
    final relogio = Stopwatch()..start();
    try {
      final resposta = await innerHandler(request);
      status = resposta.statusCode;
      return resposta;
    } finally {
      relogio.stop();
      registrarLinha(
        '${request.method} /${request.url.path} [$status] '
        '${relogio.elapsedMilliseconds}ms',
      );
    }
  };
}
