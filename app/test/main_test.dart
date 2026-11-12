import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grazifit_app/dev/menu_dev_screen.dart';
import 'package:grazifit_app/main.dart';

void main() {
  testWidgets('aplicação inicia no menu dev dentro de ProviderScope', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: GraziFitApp()));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(MenuDevScreen), findsOneWidget);
  });

  test('configuração local fornece API_BASE_URL ao Flutter', () {
    final launch = File('../.vscode/launch.json').readAsStringSync();

    expect(
      launch,
      contains('--dart-define=API_BASE_URL=http://localhost:8080'),
    );
    expect(launch, contains('--web-port=8081'));
  });

  test('manifest principal declara permissão de internet', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    expect(
      manifest,
      contains('<uses-permission android:name="android.permission.INTERNET"/>'),
    );
  });
}
