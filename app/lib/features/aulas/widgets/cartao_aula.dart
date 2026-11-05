// app/lib/features/aulas/widgets/cartao_aula.dart
//
// Cartão de aula do professor, usado na Minha agenda e no Detalhe da aula.
// Widget só desta feature: compõe componentes do design system, não cria um.

import 'package:flutter/material.dart';

import '../../../core/design_system/components/badge_status.dart';
import '../../../core/design_system/components/texto_apoio.dart';
import '../../../core/design_system/tokens/cores_provisorias.dart';

enum StatusAula { normal, ultimasVagas, cancelada }

class CartaoAula extends StatelessWidget {
  const CartaoAula({
    super.key,
    required this.horario,
    required this.modalidade,
    required this.professor,
    required this.vagasOcupadas,
    required this.vagasTotais,
    this.tipo = 'Em grupo',
    this.status = StatusAula.normal,
    this.onTap,
  });

  /// Ex.: '07:00 - 08:00'.
  final String horario;
  final String modalidade;
  final String professor;
  final int vagasOcupadas;
  final int vagasTotais;
  final String tipo;
  final StatusAula status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      horario,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (status != StatusAula.normal)
                    _EtiquetaStatus(
                      texto: status == StatusAula.cancelada
                          ? 'Cancelada'
                          : 'Últimas vagas',
                      cor: status == StatusAula.cancelada
                          ? corErro
                          : corAlerta,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // TODO(specs): trocar pelo ícone da modalidade do mockup.
                  const Icon(
                    Icons.fitness_center,
                    size: 14,
                    color: corInstitucional,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    modalidade,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(width: 8),
                  BadgeStatus(texto: tipo),
                ],
              ),
              const SizedBox(height: 8),
              TextoApoio(professor),
              const SizedBox(height: 6),
              _textoVagas(),
              if (status == StatusAula.cancelada) ...[
                const SizedBox(height: 6),
                const Text(
                  'Aula cancelada pelo professor',
                  style: TextStyle(fontSize: 11, color: corErro),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _textoVagas() {
    switch (status) {
      case StatusAula.cancelada:
        return TextoApoio('$vagasTotais vagas');
      case StatusAula.ultimasVagas:
        return Text(
          '$vagasOcupadas de $vagasTotais vagas',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: corAlerta,
          ),
        );
      case StatusAula.normal:
        return TextoApoio('$vagasOcupadas de $vagasTotais vagas');
    }
  }
}

class _EtiquetaStatus extends StatelessWidget {
  const _EtiquetaStatus({required this.texto, required this.cor});

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}