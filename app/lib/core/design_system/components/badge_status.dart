// app/lib/core/design_system/components/badge_status.dart

import 'package:flutter/material.dart';

import '../tokens/cores_provisorias.dart';

/// Pílula de status. [destaque] = fundo verde com texto branco.
class BadgeStatus extends StatelessWidget {
  const BadgeStatus({super.key, required this.texto, this.destaque = false});

  final String texto;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: destaque ? corInstitucional : corSuperficieSuave,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: destaque ? Colors.white : Colors.black54,
        ),
      ),
    );
  }
}