import 'package:shelf/shelf.dart';

/// CORS para UMA origem explicita, vinda de `CORS_ORIGIN`.
///
/// Escrito a mao, sem pacote novo (plano GRAZ-63, decisao 1). A origem
/// recebida so ganha `Access-Control-Allow-Origin` quando e IGUAL a
/// configurada: nunca `*`, nunca o reflexo do `Origin` sem comparar.
/// Outra origem recebe a resposta sem cabecalho CORS, e o navegador a
/// bloqueia.
///
/// `Vary: Origin` vai em toda resposta para que nenhum cache entregue a
/// uma origem a resposta montada para outra.
Middleware corsMiddleware(String origemPermitida) {
  const cabecalhosPreflight = {
    'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE',
    'Access-Control-Allow-Headers': 'Content-Type',
  };

  return (Handler interno) {
    return (Request request) async {
      final permitida = request.headers['origin'] == origemPermitida;
      final cabecalhos = {
        'Vary': 'Origin',
        if (permitida) 'Access-Control-Allow-Origin': origemPermitida,
      };

      // Preflight responde aqui, sem chegar ao router: nenhuma rota
      // declara OPTIONS.
      final preflight =
          request.method == 'OPTIONS' &&
          request.headers.containsKey('access-control-request-method');
      if (preflight) {
        return Response(
          204,
          headers: {...cabecalhos, if (permitida) ...cabecalhosPreflight},
        );
      }

      final resposta = await interno(request);
      return resposta.change(headers: cabecalhos);
    };
  };
}
