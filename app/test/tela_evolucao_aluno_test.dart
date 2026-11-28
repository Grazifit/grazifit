import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grazifit_app/features/avaliacoes/data/avaliacao_repository.dart';
import 'package:grazifit_app/features/avaliacoes/screens/tela_evolucao_aluno.dart';

void main() {
  testWidgets('Só pede para repintar quando o histórico muda', (tester) async {
    List<MedidaAvaliacao> historico(double peso) => [
      for (final dia in ['01', '02'])
        MedidaAvaliacao.fromJson({
          'data_avaliacao': '2026-11-$dia',
          'peso': peso,
          'altura': 1.7,
          'imc': 24.0,
        }),
    ];

    var medidas = historico(70);
    final container = ProviderContainer(
      overrides: [
        historicoAvaliacoesProvider.overrideWith((_) async => medidas),
      ],
    );
    addTearDown(container.dispose);
    Widget tela() => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: TelaEvolucaoAluno()),
    );
    CustomPainter grafico() => tester
        .widget<CustomPaint>(
          find.byWidgetPredicate(
            (widget) => widget is CustomPaint && widget.size == Size.infinite,
          ),
        )
        .painter!;

    await tester.pumpWidget(tela());
    await tester.pumpAndSettle();
    final primeiro = grafico();

    await tester.pumpWidget(tela());
    expect(grafico().shouldRepaint(primeiro), isFalse);

    medidas = historico(72);
    container.invalidate(historicoAvaliacoesProvider);
    await tester.pumpAndSettle();
    expect(grafico().shouldRepaint(primeiro), isTrue);
  });
}
