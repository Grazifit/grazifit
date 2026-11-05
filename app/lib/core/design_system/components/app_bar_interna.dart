// app/lib/core/design_system/components/app_bar_interna.dart

import 'package:flutter/material.dart';

import '../tokens/cores_provisorias.dart';

/// AppBar padrão das telas internas: seta de voltar + título
/// Use sobre [FundoTela] com Scaffold transparente

AppBar appBarInterna(BuildContext context, String titulo) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    foregroundColor: Colors.black87,
    titleSpacing: 0,
    leading: IconButton(
      icon: const Icon(Icons.chevron_left, color: corInstitucional, size: 32),
      onPressed: () => Navigator.of(context).maybePop(),
    ),
    title: Text(
      titulo,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    ),
  );
}