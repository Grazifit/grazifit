import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grazifit_app/core/state/busca_com_debounce.dart';

void main() {
  testWidgets('Publica apenas o último termo e limpa imediatamente', (
    tester,
  ) async {
    final busca = BuscaComDebounce();
    final termos = <String>[];
    busca.termo.addListener(() => termos.add(busca.termo.value));

    busca.text = 'A';
    await tester.pump(const Duration(milliseconds: 200));
    busca.text = ' ANA ';
    await tester.pump(const Duration(milliseconds: 249));
    expect(termos, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(termos, ['ana']);

    busca.selection = const TextSelection.collapsed(offset: 1);
    await tester.pump(const Duration(milliseconds: 250));
    expect(termos, ['ana']);

    busca.text = 'Maria';
    busca.clear();
    expect(termos, ['ana', '']);
    await tester.pump(const Duration(milliseconds: 250));
    expect(termos, ['ana', '']);

    busca.text = 'Pedro';
    busca.dispose();
    await tester.pump(const Duration(milliseconds: 250));
    expect(termos, ['ana', '']);
  });
}
