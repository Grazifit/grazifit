import 'dart:io';
import 'dart:isolate';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

const swaggerPath = '/swagger';
const swaggerJsonPath = '/swagger.json';

Future<Router> carregarSwagger() async {
  final uri = await Isolate.resolvePackageUri(
    Uri.parse('package:grazifit_backend/shared/http/openapi.json'),
  );
  if (uri == null) {
    throw StateError('Não foi possível localizar a especificação OpenAPI.');
  }
  final especificacao = await File.fromUri(uri).readAsBytes();
  return Router()
    ..get(
      swaggerPath,
      (Request _) => Response.ok(
        _swaggerHtml,
        headers: {'Content-Type': 'text/html; charset=utf-8'},
      ),
    )
    ..get(
      swaggerJsonPath,
      (Request _) => Response.ok(
        especificacao,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      ),
    );
}

const _swaggerHtml =
    '''
<!doctype html>
<html lang="pt-BR" class="dark-mode">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="dark">
  <title>API GraziFit — Swagger UI</title>
  <link rel="stylesheet"
    href="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.31.0/swagger-ui.css"
    integrity="sha384-KX9Rx9vM1AmUNAn07bPAiZhFD4C8jdNgG6f5MRNvR+EfAxs2PmMFtUUazui7ryZQ"
    crossorigin="anonymous">
  <style>
    html.dark-mode { background: #1c2022; color: #e4e6e6; }
    .openapi-download a { color: #9acaff; }
  </style>
</head>
<body>
  <div id="swagger-ui"></div>
  <script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.31.0/swagger-ui-bundle.js"
    integrity="sha384-cxafBeQ+zYROeFafGFxtFbnp1ICqeS9mG7+f0WWSHzhnrUvwg9Za5CCw6wgrHA7K"
    crossorigin="anonymous"></script>
  <script>
    if (typeof SwaggerUIBundle === 'function') {
      SwaggerUIBundle({
        url: '.$swaggerJsonPath',
        dom_id: '#swagger-ui',
        deepLinking: true,
        validatorUrl: null,
        persistAuthorization: false
      });
    } else {
      document.querySelector('#swagger-ui').textContent =
        'A interface Swagger não pôde ser carregada.';
    }
  </script>
  <p class="openapi-download">
    <a href=".$swaggerJsonPath">Baixar especificação OpenAPI (JSON)</a>
  </p>
</body>
</html>
''';
