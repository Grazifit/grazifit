import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:grazifit_backend/shared/middleware/cors_middleware.dart';

void main() {
  final handler = corsMiddleware('http://localhost:8081')(
    (_) => Response.ok('ok'),
  );
  test('preflight autoriza Bearer somente para origem exata', () async {
    for (final origin in [
      'http://localhost:8081',
      'https://hostile.test',
      'http://localhost:8081.hostile.test',
    ]) {
      final response = await handler(
        Request(
          'OPTIONS',
          Uri.parse('http://localhost/recurso'),
          headers: {
            'origin': origin,
            'access-control-request-method': 'GET',
            'access-control-request-headers': 'authorization,content-type',
          },
        ),
      );
      expect(response.statusCode, 204);
      if (origin == 'http://localhost:8081') {
        expect(
          response.headers['access-control-allow-headers'],
          contains('Authorization'),
        );
        expect(response.headers['access-control-allow-origin'], origin);
      } else {
        expect(
          response.headers.containsKey('access-control-allow-origin'),
          isFalse,
        );
        expect(
          response.headers.containsKey('access-control-allow-headers'),
          isFalse,
        );
      }
    }
  });
}
