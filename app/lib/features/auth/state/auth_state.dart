import 'package:shared/dtos/auth_dto.dart';

enum AuthStatus {
  inicial,
  autenticando,
  autenticado,
  credenciaisInvalidas,
  falha,
}

class AuthState {
  const AuthState({this.status = AuthStatus.inicial, this.sessao});

  final AuthStatus status;
  final LoginResponseDto? sessao;
}
