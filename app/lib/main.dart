import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/data/repositorios.dart';
import 'core/network/api_client.dart';
import 'core/routing/app_router.dart';
import 'features/auth/state/auth_controller.dart';

void main() {
  runApp(const ProviderScope(child: GraziFitApp()));
}

class GraziFitApp extends ConsumerStatefulWidget {
  const GraziFitApp({super.key});

  @override
  ConsumerState<GraziFitApp> createState() => _GraziFitAppState();
}

class _GraziFitAppState extends ConsumerState<GraziFitApp> {
  @override
  void initState() {
    super.initState();
    // Liga os repositórios das telas ao ApiClient (token da sessão).
    Repositorios.inicializar(
      ref.read(apiClientProvider),
      idUsuario: () => ref.read(authControllerProvider).sessao?.id,
      aoSair: () => ref.read(authControllerProvider.notifier).encerrarSessao(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GraziFit',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
