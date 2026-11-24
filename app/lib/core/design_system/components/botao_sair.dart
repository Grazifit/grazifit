import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/state/auth_controller.dart';
import '../tokens/cores_provisorias.dart';

/// Botão de logout. Pede confirmação, chama `POST /auth/logout` e encerra a
/// sessão; o guard de rotas (core/routing) leva para o login.
///
/// Pensado para o cabeçalho das telas raiz de cada papel.
class BotaoSair extends ConsumerWidget {
  const BotaoSair({super.key});

  Future<void> _confirmar(BuildContext context, WidgetRef ref) async {
    final sair = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (sair ?? false) {
      await ref.read(authControllerProvider.notifier).sair();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Sair',
      icon: const Icon(Icons.logout, color: corInstitucional),
      onPressed: () => _confirmar(context, ref),
    );
  }
}
