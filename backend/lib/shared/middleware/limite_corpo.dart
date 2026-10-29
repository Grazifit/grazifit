import 'dart:convert';
import 'dart:typed_data';

import 'package:shared/erros/codigo_erro.dart';
import 'package:shelf/shelf.dart';

Middleware limiteCorpo({int maxBytes = 16 * 1024}) =>
    (innerHandler) => (request) async {
      final declarado = int.tryParse(request.headers['content-length'] ?? '');
      if (declarado != null && declarado > maxBytes) return _muitoGrande();

      final bytes = BytesBuilder(copy: false);
      await for (final bloco in request.read()) {
        if (bytes.length + bloco.length > maxBytes) return _muitoGrande();
        bytes.add(bloco);
      }

      return innerHandler(request.change(body: bytes.takeBytes()));
    };

Response _muitoGrande() => Response(
  413,
  body: jsonEncode({
    'codigo': CodigoErro.corpoMuitoGrande.valor,
    'mensagem': 'Corpo da requisicao excede o limite permitido.',
  }),
  headers: {'Content-Type': 'application/json; charset=utf-8'},
);
