import 'dart:io';

class Config {
  final String databaseUrl;
  final String senhaPepper;
  final String tokenSigningKey;
  final String host;
  final int port;

  const Config({
    required this.databaseUrl,
    required this.senhaPepper,
    required this.tokenSigningKey,
    required this.host,
    required this.port,
  });

  factory Config.doAmbiente() {
    return Config(
      databaseUrl: _obrigatoria('DATABASE_URL'),
      senhaPepper: _obrigatoria('SENHA_PEPPER'),
      tokenSigningKey: _obrigatoria('TOKEN_SIGNING_KEY'),
      host: Platform.environment['SERVER_HOST'] ?? '0.0.0.0',
      port: _inteiro(
        nome: 'SERVER_PORT',
        valor: Platform.environment['SERVER_PORT'],
        padrao: 8080,
      ),
    );
  }

  static String _obrigatoria(String nome) {
    final valor = Platform.environment[nome];

    if (valor == null || valor.trim().isEmpty) {
      throw StateError('Variável obrigatória não configurada: $nome');
    }

    return valor.trim();
  }

  static int _inteiro({
    required String nome,
    required String? valor,
    required int padrao,
  }) {
    if (valor == null || valor.trim().isEmpty) {
      return padrao;
    }

    final numero = int.tryParse(valor);

    if (numero == null || numero < 1 || numero > 65535) {
      throw StateError('$nome deve ser um número entre 1 e 65535.');
    }

    return numero;
  }
}
