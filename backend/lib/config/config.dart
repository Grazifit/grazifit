import 'dart:io';

class Config {
  final String databaseUrl;
  final String senhaPepper;
  final String host;
  final int port;
  final String corsOrigin;

  const Config({
    required this.databaseUrl,
    required this.senhaPepper,
    required this.host,
    required this.port,
    required this.corsOrigin,
  });

  factory Config.doAmbiente() {
    return Config(
      databaseUrl: _obrigatoria('DATABASE_URL'),
      senhaPepper: _obrigatoria('SENHA_PEPPER'),
      host: Platform.environment['SERVER_HOST'] ?? '0.0.0.0',
      port: _inteiro(
        nome: 'SERVER_PORT',
        valor: Platform.environment['SERVER_PORT'],
        padrao: 8080,
      ),
      corsOrigin: _origem('CORS_ORIGIN'),
    );
  }

  static String _obrigatoria(String nome) {
    final valor = Platform.environment[nome];

    if (valor == null || valor.trim().isEmpty) {
      throw StateError('Variável obrigatória não configurada: $nome');
    }

    return valor.trim();
  }

  /// Origem HTTP exata, como o navegador a envia no cabecalho `Origin`:
  /// esquema, host e porta, sem caminho nem barra final. `*` e recusado.
  static String _origem(String nome) {
    final valor = _obrigatoria(nome);
    final uri = Uri.tryParse(valor);

    final valida =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        uri.path.isEmpty &&
        !uri.hasQuery &&
        !uri.hasFragment;

    if (!valida) {
      throw StateError(
        '$nome deve ser uma origem no formato esquema://host[:porta], '
        'sem barra final (ex.: http://localhost:8081).',
      );
    }

    return valor;
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
