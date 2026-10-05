/// Contrato HTTP da jornada F-01. Nao contem senha_hash nem dados clinicos.
class LoginRequestDto {
  final String email;
  final String senha;

  const LoginRequestDto({required this.email, required this.senha});

  factory LoginRequestDto.fromJson(Map<String, dynamic> json) {
    final email = json['email'];
    final senha = json['senha'];
    if (email is! String ||
        email.trim().isEmpty ||
        senha is! String ||
        senha.isEmpty) {
      throw const FormatException('email e senha sao obrigatorios');
    }
    return LoginRequestDto(email: email, senha: senha);
  }
}

class LoginResponseDto {
  final String accessToken;
  final int expiresIn;
  final int id;
  final String papel;
  final String nome;

  const LoginResponseDto({
    required this.accessToken,
    required this.expiresIn,
    required this.id,
    required this.papel,
    required this.nome,
  });

  Map<String, Object> toJson() => {
    'access_token': accessToken,
    'token_type': 'Bearer',
    'expires_in': expiresIn,
    'usuario': {'id': id, 'papel': papel, 'nome': nome},
  };
}
