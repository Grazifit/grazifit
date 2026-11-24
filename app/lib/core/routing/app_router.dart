import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dev/menu_dev_screen.dart';
import '../../features/agendamentos/screens/tela_agenda_aluno.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/state/auth_controller.dart';
import '../../features/auth/state/auth_state.dart';
import '../../features/aulas/screens/minha_agenda_screen.dart';
import 'admin_shell_screen.dart';
import 'rotas.dart';

class _SessaoListenable extends ChangeNotifier {
  void avisar() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final aviso = _SessaoListenable();
  ref.listen<AuthState>(authControllerProvider, (_, __) => aviso.avisar());
  ref.onDispose(aviso.dispose);

  final router = GoRouter(
    initialLocation: Rotas.login,
    refreshListenable: aviso,
    // Sem sessão só existe o login. Com sessão, cada papel só entra no
    // próprio prefixo. O backend continua sendo a autoridade do RBAC.
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final local = state.matchedLocation;
      final sessao =
          auth.status == AuthStatus.autenticado ? auth.sessao : null;

      // Catálogo de telas: acessível sem login, só em modo debug.
      if (local == Rotas.dev && kDebugMode) return null;

      if (sessao == null) return local == Rotas.login ? null : Rotas.login;

      final inicio = Rotas.inicioDe(sessao.papel);
      if (inicio == null) return Rotas.login;
      if (local == Rotas.login || local == '/') return inicio;
      return local == inicio ? null : inicio;
    },
    routes: [
      GoRoute(path: Rotas.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: Rotas.aluno,
        builder: (_, __) => const TelaAgendaAluno(),
      ),
      GoRoute(
        path: Rotas.professor,
        builder: (_, __) => const MinhaAgendaScreen(),
      ),
      GoRoute(
        path: Rotas.admin,
        builder: (_, __) => const AdminShellScreen(),
      ),
      GoRoute(path: Rotas.dev, builder: (_, __) => const MenuDevScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
