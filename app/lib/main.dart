import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/data/repositorios.dart';
import 'core/network/api_client.dart';
import 'core/routing/app_router.dart';
import 'features/auth/state/auth_controller.dart';

void main() {
  runApp(const ProviderScope(child: GraziFitApp()));
}

class GraziFitApp extends ConsumerWidget {
  const GraziFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Liga os repositórios das telas ao ApiClient (token da sessão).
    Repositorios.inicializar(
      ref.read(apiClientProvider),
      idUsuario: () => ref.read(authControllerProvider).sessao?.id,
      aoSair: () =>
          ref.read(authControllerProvider.notifier).encerrarSessao(),
    );

    return MaterialApp.router(
      title: 'GraziFit',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
