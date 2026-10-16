// app/lib/core/design_system/components/chip_filtro.dart

import 'package:flutter/material.dart';

import '../tokens/cores_provisorias.dart';

class ChipFiltro extends StatelessWidget {
  const ChipFiltro({super.key, required this.rotulo, this.onTap});

  final String rotulo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: corSuperficieSuave,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            rotulo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}