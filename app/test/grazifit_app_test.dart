import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grazifit_app/core/data/repositorios.dart';
import 'package:grazifit_app/main.dart';

void main() {
  testWidgets('Mantém os repositórios quando a raiz é reconstruída', (
    tester,
  ) async {
    Widget raiz() => ProviderScope(child: GraziFitApp());

    await tester.pumpWidget(raiz());
    final agenda = Repositorios.agenda;
    final admin = Repositorios.admin;

    await tester.pumpWidget(raiz());

    expect(Repositorios.agenda, same(agenda));
    expect(Repositorios.admin, same(admin));
  });
}
