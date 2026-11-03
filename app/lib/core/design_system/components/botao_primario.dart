// app/lib/lib/core/design_system/components/botao_primario.dart

import 'package:flutter/material.dart';

import '../tokens/cores_provisorias.dart';

/// Botão de ação principal: verde institucional, 52 de altura, raio 8

class BotaoPrimario extends StatelessWidget {
  const BotaoPrimario({
    super.key,
    required this.texto,
    required this.onPressed,
  });

  final String texto;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: corInstitucional,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          texto,
          style: const TextStyle(fontSize:16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}


/// [BotaoPrimario] fixo no rodapé. Use em 'Scaffold.bottomNavigationBar'

class BarraAcaoInferior extends StatelessWidget {
  const BarraAcaoInferior({
    super.key,
    required this.texto,
    required this.onPressed,
  });

  final String texto;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: BotaoPrimario(texto: texto, onPressed: onPressed),
    );
  }
}