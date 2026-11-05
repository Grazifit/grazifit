import 'dart:convert';

import 'package:grazifit_backend/features/auth/criptografia.dart';
import 'package:test/test.dart';

void main() {
  final pepper = base64Encode(List<int>.generate(32, (i) => i));

  test('gera PHC Argon2id e verifica a senha com o mesmo pepper', () {
    final hasher = SenhaHasher(pepperBase64: pepper);
    final hash = hasher.gerarHash('senha de teste');

    expect(hash, startsWith(r'$argon2id$v=19$m=65536,t=3,p=4$'));
    expect(hash, isNot(contains('senha de teste')));
    expect(hasher.verificar(senha: 'senha de teste', hashArmazenado: hash), isTrue);
    expect(hasher.verificar(senha: 'senha errada', hashArmazenado: hash), isFalse);
  });

  test('rejeita PHC invalido sem tentar derivar a senha', () {
    final hasher = SenhaHasher(pepperBase64: pepper);

    expect(
      hasher.verificar(senha: 'qualquer', hashArmazenado: 'formato antigo'),
      isFalse,
    );
    expect(
      hasher.verificar(
        senha: 'qualquer',
        hashArmazenado: r'$argon2id$v=19$m=1048576,t=3,p=4$c2FsdA$aGFzaA',
      ),
      isFalse,
    );
  });

  test('exige pepper Base64 de 32 bytes', () {
    expect(() => SenhaHasher(pepperBase64: ''), throwsStateError);
    expect(() => SenhaHasher(pepperBase64: 'invalid%'), throwsStateError);
    expect(
      () => SenhaHasher(pepperBase64: base64Encode(List<int>.filled(16, 1))),
      throwsStateError,
    );
  });
}
