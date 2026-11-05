// app/lib/core/design_system/components/cartao_lista.dart

import 'package:flutter/material.dart';

import '../tokens/cores_provisorias.dart';
import 'texto_apoio.dart';

/// Cartão branco com divisores entre os itens.
class CartaoLista extends StatelessWidget {
  const CartaoLista({super.key, required this.itens});

  final List<Widget> itens;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Column(
        children: [
          for (var i = 0; i < itens.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: corDivisor),
            itens[i],
          ],
        ],
      ),
    );
  }
}

/// Item de [CartaoLista]: título, subtítulo opcional e widget à direita.
class ItemLista extends StatelessWidget {
  const ItemLista({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.trailing,
    this.onTap,
  });

  final String titulo;
  final String? subtitulo;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 4),
                    TextoApoio(subtitulo!),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}