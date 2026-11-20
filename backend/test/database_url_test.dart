import 'package:grazifit_backend/database/database.dart';
import 'package:test/test.dart';

// Teste sem banco. Usa apenas credenciais FALSAS, marcadas com FAKE.
// Prova que a traducao da DATABASE_URL nunca devolve a senha em erro.
const _senha = 'SENHA_FAKE_NAO_REAL_7f3a';
const _usuario = 'usuario_fake';

/// Texto que um log ou stack trace imprimiria para a excecao.
String _textoDoErro(Object erro) => '$erro\n${erro.toString()}';

void _semVazamento(Object erro, String url) {
  final texto = _textoDoErro(erro);
  expect(texto, isNot(contains(_senha)), reason: 'senha vazou no erro');
  expect(texto, isNot(contains(_usuario)), reason: 'usuario vazou no erro');
  expect(texto, isNot(contains(url)), reason: 'URL inteira vazou no erro');
  expect(texto, isNot(contains('host_fake')), reason: 'host vazou no erro');
}

void main() {
  group('traduzirDatabaseUrl sem vazar a senha', () {
    test('esquema http:// e rejeitado sem expor a URL', () {
      final url = 'http://$_usuario:$_senha@host_fake/banco?sslmode=disable';
      expect(
        () => traduzirDatabaseUrl(url),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'mensagem',
            contains('postgresql://'),
          ),
        ),
      );
      try {
        traduzirDatabaseUrl(url);
      } on ArgumentError catch (e) {
        _semVazamento(e, url);
      }
    });

    test('URL sem banco e rejeitada sem expor a URL', () {
      final url = 'postgresql://$_usuario:$_senha@host_fake/';
      expect(
        () => traduzirDatabaseUrl(url),
        throwsA(isA<ArgumentError>()),
      );
      try {
        traduzirDatabaseUrl(url);
      } on ArgumentError catch (e) {
        _semVazamento(e, url);
      }
    });

    test('senha sem usuario (sem ":") e rejeitada sem expor a URL', () {
      final url = 'postgresql://$_senha@host_fake/banco';
      try {
        traduzirDatabaseUrl(url);
        fail('deveria lancar ArgumentError');
      } on ArgumentError catch (e) {
        expect(e.message, contains('USUARIO:SENHA@HOST:PORTA/BANCO'));
        _semVazamento(e, url);
      }
    });

    test('porta invalida (FormatException do Uri.parse) nao expoe a URL', () {
      // Uri.parse lanca FormatException cuja mensagem contem a URL original.
      final url = 'postgresql://$_usuario:$_senha@host_fake:porta_ruim/banco';
      expect(
        () => Uri.parse(url),
        throwsA(
          isA<FormatException>().having(
            (e) => e.toString(),
            'FormatException bruta',
            contains(_senha),
          ),
        ),
        reason: 'premissa: a FormatException crua de fato traz a senha',
      );
      try {
        traduzirDatabaseUrl(url);
        fail('deveria lancar ArgumentError');
      } on ArgumentError catch (e) {
        _semVazamento(e, url);
      } on FormatException catch (e) {
        fail('FormatException nao foi capturada: $e');
      }
    });

    test('sslmode nao suportado e rejeitado sem expor a URL', () {
      final url =
          'postgresql://$_usuario:$_senha@host_fake/banco?sslmode=verify-full';
      try {
        traduzirDatabaseUrl(url);
        fail('deveria lancar ArgumentError');
      } on ArgumentError catch (e) {
        _semVazamento(e, url);
      }
    });

    test('URL valida continua traduzindo (comportamento preservado)', () {
      final conexao = traduzirDatabaseUrl(
        'postgresql://$_usuario:$_senha@host_fake:5433/banco?sslmode=disable',
      );
      expect(conexao.endpoint.host, 'host_fake');
      expect(conexao.endpoint.port, 5433);
      expect(conexao.endpoint.database, 'banco');
      expect(conexao.endpoint.username, _usuario);
      expect(conexao.endpoint.password, _senha);
    });
  });
}
