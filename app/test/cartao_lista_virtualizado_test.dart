import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grazifit_app/core/design_system/components/cartao_lista.dart';

void main() {
  testWidgets('Constrói linhas distantes somente ao rolar', (tester) async {
    final construidos = <int>{};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CartaoListaVirtualizado(
            quantidade: 1000,
            construirItem: (context, index) {
              construidos.add(index);
              return ItemLista(titulo: 'Aluno $index');
            },
          ),
        ),
      ),
    );

    expect(find.text('Aluno 0'), findsOneWidget);
    expect(construidos, isNot(contains(35)));
    await tester.scrollUntilVisible(find.text('Aluno 35'), 250);
    expect(find.text('Aluno 35'), findsOneWidget);
    expect(construidos, isNot(contains(999)));
  });
}
