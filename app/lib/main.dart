import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dev/menu_dev_screen.dart';

void main() {
  runApp(const ProviderScope(child: GraziFitApp()));
}

class GraziFitApp extends StatelessWidget {
  const GraziFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MenuDevScreen(),
    );
  }
}
