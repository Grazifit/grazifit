import 'package:flutter/material.dart';

import '../../features/inicio/screens/paginas_admin.dart';
import '../../features/inicio/screens/tela_inicio_admin.dart';
import '../../features/pessoas/screens/tela_usuarios_admin.dart';
import '../design_system/components/botao_sair.dart';

enum _DestinoAdmin { inicio, pessoas, aulas, treinos }

/// Casca de navegação visual do Admin: Início, Pessoas, Aulas e Treinos.
class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  _DestinoAdmin _destino = _DestinoAdmin.inicio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
        index: _destino.index,
        children: [
          PaginaInicioAdmin(
            mostrarNavegacaoInferior: false,
            onNavegar: (destino) => _selecionar(_DestinoAdmin.values[destino.index]),
          ),
          PaginaUsuariosAdmin(
            mostrarNavegacaoInferior: false,
            onNavegar: (destino) => _selecionar(_DestinoAdmin.values[destino.index]),
          ),
          const PaginaAulasAdmin(),
          const PaginaTreinosLivresAdmin(),
        ],
      ),
          const Positioned(
            top: 0,
            right: 4,
            child: SafeArea(child: BotaoSair()),
          ),
        ],
      ),
      bottomNavigationBar: _barraNavegacao(),
    );
  }

  Widget _barraNavegacao() {
    const destinos = [
      (Icons.home_outlined, 'Início'),
      (Icons.people_outline, 'Pessoas'),
      (Icons.directions_run, 'Aulas'),
      (Icons.fitness_center, 'Treinos'),
    ];
    final altura = (84 - MediaQuery.of(context).viewPadding.bottom)
        .clamp(60.0, 84.0)
        .toDouble();
    return Container(
      color: const Color(0xFF005B50),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: altura,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < destinos.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => _selecionar(_DestinoAdmin.values[i]),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 5),
                          decoration: BoxDecoration(
                            color: _destino.index == i
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Icon(
                          destinos[i].$1,
                          size: 22,
                          color: _destino.index == i
                              ? Colors.white
                              : Colors.white70,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          destinos[i].$2,
                          style: TextStyle(
                            color: _destino.index == i
                                ? Colors.white
                                : Colors.white70,
                            fontSize: 10,
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

  void _selecionar(_DestinoAdmin destino) {
    setState(() => _destino = destino);
  }
}
