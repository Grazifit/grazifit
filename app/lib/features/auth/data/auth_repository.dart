import 'package:shared/dtos/auth_dto.dart';

import '../../../core/network/api_client.dart';

abstract interface class AuthRepository {
  Future<LoginResponseDto> login({
    required String email,
    required String senha,
  });
}

class HttpAuthRepository implements AuthRepository {
  const HttpAuthRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<LoginResponseDto> login({
    required String email,
    required String senha,
  }) async {
    final resposta = await _apiClient.postJson('/auth/login', {
      'email': email,
      'senha': senha,
    });
    return LoginResponseDto.fromJson(resposta);
  }
}
