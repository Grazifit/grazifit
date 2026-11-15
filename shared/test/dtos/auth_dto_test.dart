import 'package:shared/dtos/auth_dto.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> respostaValida() => {
    'access_token': 'token-jwt',
    'token_type': 'Bearer',
    'expires_in': 3600,
    'usuario': <String, dynamic>{
      'id': 1,
      'papel': 'admin',
      'nome': 'Administrador',
    },
  };

  test('converte uma resposta completa', () {
    final dto = LoginResponseDto.fromJson(respostaValida());

    expect(dto.accessToken, 'token-jwt');
    expect(dto.expiresIn, 3600);
    expect(dto.id, 1);
    expect(dto.papel, 'admin');
    expect(dto.nome, 'Administrador');
  });

  for (final caso in <String, void Function(Map<String, dynamic>)>{
    'access_token invalido': (json) => json['access_token'] = 123,
    'token_type diferente de Bearer': (json) => json['token_type'] = 'Basic',
    'expires_in invalido': (json) => json['expires_in'] = '3600',
    'usuario invalido': (json) => json['usuario'] = 'usuario',
    'usuario.id invalido': (json) =>
        (json['usuario'] as Map<String, dynamic>)['id'] = '1',
    'usuario.papel invalido': (json) =>
        (json['usuario'] as Map<String, dynamic>)['papel'] = 1,
    'usuario.nome invalido': (json) =>
        (json['usuario'] as Map<String, dynamic>)['nome'] = null,
  }.entries) {
    test('rejeita ${caso.key} com FormatException', () {
      final json = respostaValida();
      caso.value(json);

      expect(() => LoginResponseDto.fromJson(json), throwsFormatException);
    });
  }
}
