import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grazifit_app/core/network/api_exception.dart';
import 'package:grazifit_app/features/auth/data/auth_repository.dart';
import 'package:grazifit_app/features/auth/state/auth_controller.dart';
import 'package:grazifit_app/features/auth/state/auth_state.dart';
import 'package:shared/dtos/auth_dto.dart';

class _Repository implements AuthRepository {
  _Repository(this.callback);

  final Future<LoginResponseDto> Function() callback;
  int chamadas = 0;

  @override
  Future<LoginResponseDto> login({
    required String email,
    required String senha,
  }) {
    chamadas++;
    return callback();
  }
}

const _sessao = LoginResponseDto(
  accessToken: 'jwt',
  expiresIn: 3600,
  id: 1,
  papel: 'admin',
  nome: 'Admin',
);

ProviderContainer _containerCom(_Repository repository) => ProviderContainer(
  overrides: [authRepositoryProvider.overrideWithValue(repository)],
);

void main() {
  test('mantém sessão somente no estado em memória após sucesso', () async {
    final container = _containerCom(_Repository(() async => _sessao));
    addTearDown(container.dispose);

    final resultado = await container
        .read(authControllerProvider.notifier)
        .login('admin@exemplo.com', 'correta');

    expect(resultado, same(_sessao));
    expect(
      container.read(authControllerProvider).status,
      AuthStatus.autenticado,
    );
    expect(container.read(authControllerProvider).sessao, same(_sessao));
  });

  test('transforma somente 401 em credenciais inválidas', () async {
    final repository = _Repository(
      () async => throw const ApiException(statusCode: 401),
    );
    final container = _containerCom(repository);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).login('a', 'b');

    expect(
      container.read(authControllerProvider).status,
      AuthStatus.credenciaisInvalidas,
    );
  });

  test('trata 429 como falha genérica', () async {
    final repository = _Repository(
      () async => throw const ApiException(statusCode: 429),
    );
    final container = _containerCom(repository);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).login('a', 'b');

    expect(container.read(authControllerProvider).status, AuthStatus.falha);
  });

  test('trata resposta inválida como falha genérica', () async {
    final repository = _Repository(() async => throw const FormatException());
    final container = _containerCom(repository);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).login('a', 'b');

    expect(container.read(authControllerProvider).status, AuthStatus.falha);
  });

  test('impede duas requisições concorrentes', () async {
    final completer = Completer<LoginResponseDto>();
    final repository = _Repository(() => completer.future);
    final container = _containerCom(repository);
    addTearDown(container.dispose);

    final primeira = container
        .read(authControllerProvider.notifier)
        .login('a', 'b');
    final segunda = await container
        .read(authControllerProvider.notifier)
        .login('a', 'b');

    expect(segunda, isNull);
    expect(repository.chamadas, 1);
    completer.complete(_sessao);
    await primeira;
  });
}
