import 'package:shared/dtos/auth_dto.dart';

import 'auth_repository.dart';
import 'criptografia.dart';
import 'token_service.dart';
import 'validacoes.dart';

class CredenciaisInvalidas implements Exception {
  const CredenciaisInvalidas();
}

class AuthService {
  final AuthRepository _repository;
  final SenhaHasher _senhaHasher;
  final TokenService _tokens;
  final String _hashFicticio;

  AuthService(this._repository, SenhaHasher senhaHasher, this._tokens)
    : _senhaHasher = senhaHasher,
      _hashFicticio = senhaHasher.gerarHash('senha-ficticia');

  Future<LoginResponseDto> login(LoginRequestDto entrada) async {
    final email = entrada.email.trim().toLowerCase();
    if (!Validacoes.emailValido(email)) {
      throw const CredenciaisInvalidas();
    }

    final contas = await _repository.buscarPorEmail(email);
    final conta = contas.length == 1 ? contas.single : null;
    final hash = conta?.senhaHash ?? _hashFicticio;
    final senhaCorreta = _senhaHasher.verificar(
      senha: entrada.senha,
      hashArmazenado: hash,
    );
    if (conta == null || !conta.ativa || !senhaCorreta) {
      throw const CredenciaisInvalidas();
    }

    return LoginResponseDto(
      accessToken: _tokens.emitir(conta.identidade),
      expiresIn: TokenService.validade.inSeconds,
      id: conta.identidade.id,
      papel: conta.identidade.papel.name,
      nome: conta.nome,
    );
  }
}
