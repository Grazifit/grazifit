import 'dart:convert';

import 'package:grazifit_backend/features/auth/token_service.dart';
import 'package:grazifit_backend/shared/autorizacao/identidade.dart';
import 'package:test/test.dart';

void main() {
  final chave = base64Encode(List<int>.generate(32, (i) => i));
  var agora = DateTime.utc(2026, 10, 1, 12);
  final tokens = TokenService(chaveBase64: chave, agora: () => agora);
  const admin = Identidade(id: 7, papel: Papel.admin);

  test('emite token para identidade e rejeita alteracao ou expiracao', () {
    final token = tokens.emitir(admin);
    final identidade = tokens.validar(token);
    expect(identidade?.id, 7);
    expect(identidade?.papel, Papel.admin);

    final partes = token.split('.');
    final segmento = partes[1];
    final padding = '=' * ((4 - segmento.length % 4) % 4);
    final payload = jsonDecode(
      utf8.decode(base64Url.decode('$segmento$padding')),
    ) as Map<String, dynamic>;
    payload['papel'] = 'aluno';
    final adulterado =
        '${partes[0]}.${base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '')}.${partes[2]}';
    expect(tokens.validar(adulterado), isNull);

    agora = agora.add(TokenService.validade);
    expect(tokens.validar(token), isNull);
  });

  test('nao aceita token assinado com outra chave', () {
    final outro = TokenService(
      chaveBase64: base64Encode(List<int>.filled(32, 9)),
      agora: () => agora,
    );
    expect(outro.validar(tokens.emitir(admin)), isNull);
  });
}
