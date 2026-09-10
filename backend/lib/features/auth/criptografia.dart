import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'package:argon2/argon2.dart';
import 'package:dotenv/dotenv.dart';

const int saltLength = 16;
const int hashLength = 32;

String? _cachedPepper;

/// Sobe diretórios a partir do local do próprio script até achar o .env
File _findEnvFile() {
  var dir = Directory(
    File(Platform.script.toFilePath()).parent.path,
  );

  while (true) {
    final candidate = File('${dir.path}${Platform.pathSeparator}.env');
    if (candidate.existsSync()) {
      return candidate;
    }

    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw Exception('.env não encontrado em nenhum diretório acima');
    }
    dir = parent;
  }
}

/// Carrega e retorna o PEPPER da env, com cache em memória.
String getPepper() {
  if (_cachedPepper != null) {
    return _cachedPepper!;
  }

  final envFile = _findEnvFile();

  final env = DotEnv(includePlatformEnvironment: true)
    ..load([envFile.path]);

  final pepper = env['PEPPER'];

  if (pepper == null || pepper.isEmpty) {
    throw Exception('PEPPER não configurado');
  }

  _cachedPepper = pepper;
  return pepper;
}

Uint8List generateSalt() {
  final random = Random.secure();
  return Uint8List.fromList(
    List<int>.generate(saltLength, (_) => random.nextInt(256)),
  );
}

bool _constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var result = 0;
  for (var i = 0; i < a.length; i++) {
    result |= a[i] ^ b[i];
  }
  return result == 0;
}

Uint8List _derive({
  required String password,
  required Uint8List salt,
  required String pepper,
  required int iterations,
  required int memoryPowerOf2,
  required int lanes,
}) {
  final parameters = Argon2Parameters(
    Argon2Parameters.ARGON2_id,
    salt,
    secret: Uint8List.fromList(utf8.encode(pepper)),
    iterations: iterations,
    memoryPowerOf2: memoryPowerOf2,
    lanes: lanes,
    version: Argon2Parameters.ARGON2_VERSION_13,
  );

  final generator = Argon2BytesGenerator();
  generator.init(parameters);

  final hash = Uint8List(hashLength);
  generator.generateBytes(
    Uint8List.fromList(utf8.encode(password)),
    hash,
    0,
    hash.length,
  );

  return hash;
}

/// Gera o hash da senha usando Argon2id + pepper (lido automaticamente da env).
String hashPassword(
  String password, {
  int iterations = 3,
  int memoryPowerOf2 = 16,
  int lanes = 1,
}) {
  final pepper = getPepper();
  final salt = generateSalt();

  final hash = _derive(
    password: password,
    salt: salt,
    pepper: pepper,
    iterations: iterations,
    memoryPowerOf2: memoryPowerOf2,
    lanes: lanes,
  );

  return '$iterations:$memoryPowerOf2:$lanes:${base64Encode(salt)}:${base64Encode(hash)}';
}

/// Verifica se a senha informada corresponde ao hash armazenado.
bool verifyPassword(String password, String stored) {
  final pepper = getPepper();

  final partes = stored.split(':');
  if (partes.length != 5) return false;

  final iterations = int.tryParse(partes[0]);
  final memoryPowerOf2 = int.tryParse(partes[1]);
  final lanes = int.tryParse(partes[2]);
  if (iterations == null || memoryPowerOf2 == null || lanes == null) {
    return false;
  }

  final Uint8List salt;
  final Uint8List hashArmazenado;
  try {
    salt = base64Decode(partes[3]);
    hashArmazenado = base64Decode(partes[4]);
  } catch (_) {
    return false;
  }

  final hashCalculado = _derive(
    password: password,
    salt: salt,
    pepper: pepper,
    iterations: iterations,
    memoryPowerOf2: memoryPowerOf2,
    lanes: lanes,
  );

  return _constantTimeEquals(hashCalculado, hashArmazenado);
}