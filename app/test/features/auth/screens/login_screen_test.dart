import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grazifit_app/core/network/api_exception.dart';
import 'package:grazifit_app/features/agendamentos/screens/tela_agenda_aluno.dart';
import 'package:grazifit_app/features/auth/data/auth_repository.dart';
import 'package:grazifit_app/features/auth/screens/login_screen.dart';
import 'package:grazifit_app/features/auth/state/auth_controller.dart';
import 'package:grazifit_app/features/inicio/screens/tela_inicio_admin.dart';
import 'package:grazifit_app/features/aulas/screens/minha_agenda_screen.dart';
import 'package:shared/dtos/auth_dto.dart';

class _Repository implements AuthRepository {
  _Repository(this.callback);
  final Future<LoginResponseDto> Function(String email, String senha) callback;
  int chamadas = 0;

  @override
  Future<LoginResponseDto> login({
    required String email,
    required String senha,
  }) {
    chamadas++;
    return callback(email, senha);
  }
}

Widget _appCom(_Repository repository, {bool iniciarComErro = false}) =>
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(home: LoginScreen(iniciarComErro: iniciarComErro)),
    );

LoginResponseDto sessao(String papel) => LoginResponseDto(
  accessToken: 'jwt',
  expiresIn: 3600,
  id: 1,
  papel: papel,
  nome: 'Pessoa',
);

void main() {
  testWidgets('envia o e-mail e a senha digitados', (tester) async {
    late String email;
    late String senha;
    final repository = _Repository((e, s) async {
      email = e;
      senha = s;
      return sessao('desconhecido');
    });
    await tester.pumpWidget(_appCom(repository));

    await tester.enterText(find.byType(TextField).at(0), 'nova@exemplo.com');
    await tester.enterText(find.byType(TextField).at(1), 'nova-senha');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(email, 'nova@exemplo.com');
    expect(senha, 'nova-senha');
  });

  testWidgets('mostra credenciais inválidas somente em 401', (tester) async {
    final repository = _Repository(
      (_, _) async => throw const ApiException(statusCode: 401),
    );
    await tester.pumpWidget(_appCom(repository));
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('E-mail ou senha inválidos'), findsOneWidget);
  });

  testWidgets('não mostra credenciais inválidas em 429', (tester) async {
    final repository = _Repository(
      (_, _) async => throw const ApiException(statusCode: 429),
    );
    await tester.pumpWidget(_appCom(repository));
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('E-mail ou senha inválidos'), findsNothing);
  });

  testWidgets('limpa erro imediatamente e clique duplo faz uma requisição', (
    tester,
  ) async {
    final completer = Completer<LoginResponseDto>();
    final repository = _Repository((_, _) => completer.future);
    await tester.pumpWidget(_appCom(repository, iniciarComErro: true));

    await tester.tap(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('E-mail ou senha inválidos'), findsNothing);
    expect(repository.chamadas, 1);
    completer.complete(sessao('desconhecido'));
    await tester.pump();
  });

  for (final caso in <String, Type>{
    'admin': TelaInicioAdmin,
    'aluno': TelaAgendaAluno,
    'professor': MinhaAgendaScreen,
  }.entries) {
    testWidgets('${caso.key} abre a tela correspondente', (tester) async {
      final repository = _Repository((_, _) async => sessao(caso.key));
      await tester.pumpWidget(_appCom(repository));
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.byType(caso.value), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });
  }

  testWidgets('papel desconhecido não abre tela privilegiada', (tester) async {
    final repository = _Repository((_, _) async => sessao('gestor'));
    await tester.pumpWidget(_appCom(repository));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(TelaInicioAdmin), findsNothing);
    expect(find.byType(TelaAgendaAluno), findsNothing);
    expect(find.byType(MinhaAgendaScreen), findsNothing);
  });
}
