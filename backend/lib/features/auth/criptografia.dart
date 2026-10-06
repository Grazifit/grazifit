import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:argon2/argon2.dart';
import 'package:crypto/crypto.dart';

SenhaHasher? _senhaHasherConfigurado;

/// Configurado uma vez no inicio do processo, antes de atender requisicoes.
void configurarCriptografia(SenhaHasher hasher) {
  if (_senhaHasherConfigurado != null) {
    throw StateError('A criptografia de senha ja foi configurada.');
  }
  _senhaHasherConfigurado = hasher;
}

SenhaHasher get _senhaHasher =>
    _senhaHasherConfigurado ??
    (throw StateError('A criptografia de senha nao foi configurada.'));

/// Mantem a interface usada pelos services existentes.
String hashPassword(String senha) => _senhaHasher.gerarHash(senha);

bool verifyPassword(String senha, String hashArmazenado) =>
    _senhaHasher.verificar(senha: senha, hashArmazenado: hashArmazenado);

class SenhaHasher {
  static const int _saltLength = 16;
  static const int _hashLength = 32;

  static const int _versaoArgon2 = 19;
  static const int _memoriaKiB = 65536;
  static const int _memoriaPowerOf2 = 16;
  static const int _iteracoes = 3;
  static const int _paralelismo = 4;

  final Uint8List _pepper;
  final Random _random;

  SenhaHasher({required String pepperBase64, Random? random})
    : _pepper = _decodificarPepper(pepperBase64),
      _random = random ?? Random.secure();

  String gerarHash(String senha) {
    final salt = _gerarSalt();

    final hash = _derivar(
      senha: senha,
      salt: salt,
      iteracoes: _iteracoes,
      memoriaPowerOf2: _memoriaPowerOf2,
      paralelismo: _paralelismo,
    );

    return [
      '',
      'argon2id',
      'v=$_versaoArgon2',
      'm=$_memoriaKiB,t=$_iteracoes,p=$_paralelismo',
      _base64SemPadding(salt),
      _base64SemPadding(hash),
    ].join(r'$');
  }

  bool verificar({required String senha, required String hashArmazenado}) {
    final phc = _PhcArgon2id.tryParse(hashArmazenado);

    if (phc == null) {
      return false;
    }

    // Evita executar parâmetros inesperados ou excessivos vindos do banco.
    if (phc.versao != _versaoArgon2 ||
        phc.memoriaKiB != _memoriaKiB ||
        phc.iteracoes != _iteracoes ||
        phc.paralelismo != _paralelismo ||
        phc.salt.length != _saltLength ||
        phc.hash.length != _hashLength) {
      return false;
    }

    final hashCalculado = _derivar(
      senha: senha,
      salt: phc.salt,
      iteracoes: phc.iteracoes,
      memoriaPowerOf2: _memoriaPowerOf2,
      paralelismo: phc.paralelismo,
    );

    return _compararEmTempoConstante(hashCalculado, phc.hash);
  }

  Uint8List _derivar({
    required String senha,
    required Uint8List salt,
    required int iteracoes,
    required int memoriaPowerOf2,
    required int paralelismo,
  }) {
    final senhaProtegida = _aplicarPepper(senha);

    final parametros = Argon2Parameters(
      Argon2Parameters.ARGON2_id,
      salt,
      iterations: iteracoes,
      memoryPowerOf2: memoriaPowerOf2,
      lanes: paralelismo,
      version: Argon2Parameters.ARGON2_VERSION_13,
    );

    final gerador = Argon2BytesGenerator()..init(parametros);
    final hash = Uint8List(_hashLength);

    gerador.generateBytes(senhaProtegida, hash, 0, hash.length);

    return hash;
  }

  Uint8List _aplicarPepper(String senha) {
    final hmac = Hmac(sha256, _pepper);
    final digest = hmac.convert(utf8.encode(senha));

    return Uint8List.fromList(digest.bytes);
  }

  Uint8List _gerarSalt() {
    return Uint8List.fromList(
      List<int>.generate(_saltLength, (_) => _random.nextInt(256)),
    );
  }

  static Uint8List _decodificarPepper(String valor) {
    if (valor.trim().isEmpty) {
      throw StateError('SENHA_PEPPER não foi configurado.');
    }

    final List<int> bytes;

    try {
      bytes = base64Decode(valor);
    } on FormatException {
      throw StateError('SENHA_PEPPER deve estar em Base64 válido.');
    }

    if (bytes.length != 32) {
      throw StateError('SENHA_PEPPER deve representar exatamente 32 bytes.');
    }

    return Uint8List.fromList(bytes);
  }

  static String _base64SemPadding(List<int> bytes) {
    return base64Encode(bytes).replaceAll('=', '');
  }

  static bool _compararEmTempoConstante(
    List<int> recebido,
    List<int> esperado,
  ) {
    if (recebido.length != esperado.length) {
      return false;
    }

    var diferenca = 0;

    for (var i = 0; i < recebido.length; i++) {
      diferenca |= recebido[i] ^ esperado[i];
    }

    return diferenca == 0;
  }
}

class _PhcArgon2id {
  final int versao;
  final int memoriaKiB;
  final int iteracoes;
  final int paralelismo;
  final Uint8List salt;
  final Uint8List hash;

  const _PhcArgon2id({
    required this.versao,
    required this.memoriaKiB,
    required this.iteracoes,
    required this.paralelismo,
    required this.salt,
    required this.hash,
  });

  static _PhcArgon2id? tryParse(String valor) {
    final partes = valor.split(r'$');

    if (partes.length != 6 || partes[0].isNotEmpty || partes[1] != 'argon2id') {
      return null;
    }

    final versao = _lerNumeroComPrefixo(partes[2], 'v=');
    final parametros = _lerParametros(partes[3]);

    if (versao == null || parametros == null) {
      return null;
    }

    try {
      return _PhcArgon2id(
        versao: versao,
        memoriaKiB: parametros.memoriaKiB,
        iteracoes: parametros.iteracoes,
        paralelismo: parametros.paralelismo,
        salt: _base64PhcDecode(partes[4]),
        hash: _base64PhcDecode(partes[5]),
      );
    } on FormatException {
      return null;
    }
  }

  static int? _lerNumeroComPrefixo(String valor, String prefixo) {
    if (!valor.startsWith(prefixo)) {
      return null;
    }

    return int.tryParse(valor.substring(prefixo.length));
  }

  static ({int memoriaKiB, int iteracoes, int paralelismo})? _lerParametros(
    String valor,
  ) {
    final itens = valor.split(',');

    if (itens.length != 3) {
      return null;
    }

    final memoria = _lerNumeroComPrefixo(itens[0], 'm=');
    final iteracoes = _lerNumeroComPrefixo(itens[1], 't=');
    final paralelismo = _lerNumeroComPrefixo(itens[2], 'p=');

    if (memoria == null || iteracoes == null || paralelismo == null) {
      return null;
    }

    return (
      memoriaKiB: memoria,
      iteracoes: iteracoes,
      paralelismo: paralelismo,
    );
  }

  static Uint8List _base64PhcDecode(String valor) {
    final padding = '=' * ((4 - valor.length % 4) % 4);
    return Uint8List.fromList(base64Decode('$valor$padding'));
  }
}
