import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grazifit_app/core/routing/admin_shell_screen.dart';
import 'package:grazifit_app/features/aulas/data/aulas_admin_data.dart';
import 'package:grazifit_app/features/inicio/data/inicio_admin_data.dart';
import 'package:grazifit_app/features/inicio/screens/paginas_admin.dart';
import 'package:grazifit_app/features/pessoas/data/usuarios_admin_data.dart';
import 'package:grazifit_app/features/treinos/state/treinos_livres_admin_state.dart';

void main() {
  testWidgets('Abas administrativas carregam uma vez, no primeiro acesso', (
    tester,
  ) async {
    final cargas = <String>[];
    Future<T> carregar<T>(String aba) {
      cargas.add(aba);
      return Completer<T>().future;
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inicioAdminProvider.overrideWith(
            (_) => carregar<InicioAdminData>('Início'),
          ),
          usuariosAdminProvider.overrideWith(
            (_) => carregar<UsuariosAdminData>('Pessoas'),
          ),
          aulasAdminProvider.overrideWith(
            (_) => carregar<List<AulaListaAdminData>>('Aulas'),
          ),
          treinosLivresAdminProvider.overrideWith(
            (_) => carregar<List<TreinoLivreAdminItem>>('Treinos'),
          ),
        ],
        child: const MaterialApp(home: AdminShellScreen()),
      ),
    );
    expect(cargas, ['Início']);

    for (final aba in ['Pessoas', 'Aulas', 'Treinos', 'Início', 'Pessoas']) {
      final shell = tester.widget<Scaffold>(find.byType(Scaffold).first);
      await tester.tap(
        find.descendant(
          of: find.byWidget(shell.bottomNavigationBar!),
          matching: find.text(aba),
        ),
      );
      await tester.pump();
      await tester.pump();
    }
    expect(cargas, ['Início', 'Pessoas', 'Aulas', 'Treinos']);
  });
}
