// app/lib/core/design_system/components/texto_apoio.dart

import 'package:flutter/material.dart';

/// Texto pequeno e cinza usado como subtítulo/legenda.
class TextoApoio extends StatelessWidget {
  const TextoApoio(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
    );
  }
}