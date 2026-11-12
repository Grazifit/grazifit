import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/dtos/auth_dto.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => HttpAuthRepository(ApiClient()),
);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<LoginResponseDto?> login(String email, String senha) async {
    if (state.status == AuthStatus.autenticando) {
      return null;
    }

    state = const AuthState(status: AuthStatus.autenticando);
    try {
      final sessao = await ref
          .read(authRepositoryProvider)
          .login(email: email, senha: senha);
      state = AuthState(status: AuthStatus.autenticado, sessao: sessao);
      return sessao;
    } on ApiException catch (erro) {
      state = AuthState(
        status: erro.statusCode == 401
            ? AuthStatus.credenciaisInvalidas
            : AuthStatus.falha,
      );
      return null;
    } on Object {
      state = const AuthState(status: AuthStatus.falha);
      return null;
    }
  }
}
