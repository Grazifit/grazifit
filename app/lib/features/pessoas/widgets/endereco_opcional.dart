// app/lib/features/pessoas/widgets/endereco_opcional.dart
//
// Sub-form "Endereço (opcional)", compartilhado por professor e aluno (D18:
// endereço é sub-form opcional, não feature própria).

import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/cores_provisorias.dart';

class EnderecoOpcional extends StatefulWidget {
  const EnderecoOpcional({super.key, this.nota});

  /// Nota de escopo exibida sob o título (texto real da tela, vindo do
  /// mockup — não é comentário de dev).
  final String? nota;

  @override
  State<EnderecoOpcional> createState() => _EnderecoOpcionalState();
}

class _EnderecoOpcionalState extends State<EnderecoOpcional> {
  bool _aberto = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _aberto = !_aberto),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Endereço (opcional)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              AnimatedRotation(
                turns: _aberto ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: corInstitucional,
                ),
              ),
            ],
          ),
        ),
        if (widget.nota != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              widget.nota!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        // TODO(specs): os campos deste sub-form dependem das colunas reais
        // da tabela `endereco` em database/schema/grazi_db_init_schema.sql,
        // que não veio no export de specs. Não inventar campos (rua, número,
        // CEP etc.) até essa fonte de verdade estar disponível — ver R4 em
        // docs/05-prompts-ia/prompt-fase-1-estrutura.md.
        if (_aberto)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Campos de endereço pendentes: schema real da tabela '
              '"endereco" ainda não disponível nas specs.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
      ],
    );
  }
}