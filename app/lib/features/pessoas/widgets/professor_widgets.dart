// app/lib/features/alunos/widgets/alunos_widgets.dart
//
// Componentes compartilhados pelas telas de alunos do professor.
//
// TODO(specs): quando core/design_system/tokens existir, trocar as cores e
// estilos abaixo pelos tokens reais e promover estes componentes para
// core/design_system/components (são genéricos, não específicos de alunos).

import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/cores_provisorias.dart';

// Reexporta para as telas de alunos continuarem importando só este arquivo.
export '../../../core/design_system/components/app_bar_interna.dart';
export '../../../core/design_system/tokens/cores_provisorias.dart';

const _corSuperficieSuave = Color(0xFFEAEFED);
const _corDivisor = Color(0xFFE6E6E6);

/// Remove o último sobrenome: "Ana Beatriz Ramos" -> "Ana Beatriz".
/// Usado nos títulos "Histórico de Ana Beatriz" / "Treinos de Ana Beatriz".
String nomeCurto(String nome) {
  final partes = nome.trim().split(RegExp(r'\s+'));
  if (partes.length <= 1) return nome.trim();
  return partes.sublist(0, partes.length - 1).join(' ');
}

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

class CampoBusca extends StatelessWidget {
  const CampoBusca({super.key, required this.controller, this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Buscar aluno',
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: const Icon(Icons.search, color: corInstitucional),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: corInstitucional, width: 1.5),
        ),
      ),
    );
  }
}

class ChipFiltro extends StatelessWidget {
  const ChipFiltro({super.key, required this.rotulo, this.onTap});

  final String rotulo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _corSuperficieSuave,
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
        color: destaque ? corInstitucional : _corSuperficieSuave,
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
            if (i > 0) const Divider(height: 1, thickness: 1, color: _corDivisor),
            itens[i],
          ],
        ],
      ),
    );
  }
}

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

/// Barra de navegação inferior (Agenda / Alunos / Perfil).
class BarraNavegacao extends StatelessWidget {
  const BarraNavegacao({
    super.key,
    required this.indiceAtual,
    this.onSelecionar,
  });

  final int indiceAtual;
  final ValueChanged<int>? onSelecionar;

  static const _itens = [
    (Icons.calendar_month_outlined, 'Agenda'),
    (Icons.groups_outlined, 'Alunos'),
    (Icons.person_outline, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: corInstitucional,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < _itens.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: onSelecionar == null ? null : () => onSelecionar!(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 2,
                          color: i == indiceAtual
                              ? Colors.white
                              : Colors.transparent,
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          _itens[i].$1,
                          size: 26,
                          color: i == indiceAtual
                              ? Colors.white
                              : Colors.white70,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _itens[i].$2,
                          style: TextStyle(
                            fontSize: 11,
                            color: i == indiceAtual
                                ? Colors.white
                                : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}