// app/lib/core/design_system/components/barra_navegacao.dart

import 'package:flutter/material.dart';

import '../../../features/aulas/screens/minha_agenda_screen.dart';
import '../../../features/pessoas/screens/perfil_professor_screen.dart';
import '../../../features/vinculos/screens/meus_alunos_screen.dart';
import '../tokens/cores_provisorias.dart';

/// Barra de navegação inferior do professor (Agenda / Alunos / Perfil).
/// Sem [onSelecionar], troca de aba substituindo a tela atual.
class BarraNavegacao extends StatelessWidget {
  const BarraNavegacao({
    super.key,
    required this.indiceAtual,
    this.onSelecionar,
  });

  final int indiceAtual;
  final ValueChanged<int>? onSelecionar;

  static Widget _tela(int i) => switch (i) {
        0 => const MinhaAgendaScreen(),
        1 => const MeusAlunosScreen(),
        _ => const PerfilProfessorScreen(),
      };

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
                    onTap: () {
                      if (onSelecionar != null) {
                        onSelecionar!(i);
                      } else if (i != indiceAtual) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(builder: (_) => _tela(i)),
                        );
                      }
                    },
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