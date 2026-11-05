import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'tela_detalhe_treino_aluno.dart';
import '../../pessoas/screens/tela_perfil_aluno.dart';
import '../../avaliacoes/screens/tela_evolucao_aluno.dart';

/// Tela de treinos do aluno: treinos montados pelo professor,
/// treinos livres e acesso ao histórico.
class TelaTreinosAluno extends StatefulWidget {
  const TelaTreinosAluno({super.key});

  @override
  State<TelaTreinosAluno> createState() => _TelaTreinosAlunoState();
}

class _TelaTreinosAlunoState extends State<TelaTreinosAluno> {
  static const Color kGreen = AppColors.verde;
  static const Color kBackground = AppColors.fundo;

  int _navSelecionado = 1;

  // Dados de exemplo. Troque pela chamada ao backend.
  final String _professor = 'Prof. Marina Alves';

  final List<_Treino> _treinosDoProfessor = const [
    _Treino(id: '1', nome: 'Inferiores A', objetivo: 'Força'),
    _Treino(id: '2', nome: 'Superiores B', objetivo: 'Hipertrofia'),
  ];

  final List<_Treino> _treinosLivres = const [
    _Treino(id: '3', nome: 'Full body iniciante', objetivo: 'Resistência'),
    _Treino(id: '4', nome: 'Cardio leve', objetivo: 'Cardio'),
  ];

  void _abrirTreino(_Treino treino) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TelaDetalheTreinoAluno(
          treinoId: treino.id,
          nome: treino.nome,
        ),
      ),
    );
  }

  void _abrirHistorico() {
    // TODO: navegar para a tela de histórico de treinos.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            const Text(
              'Treinos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildSecao('Feitos para você · $_professor', _treinosDoProfessor),
            const SizedBox(height: 20),
            _buildSecao('Treinos livres', _treinosLivres),
            const SizedBox(height: 20),
            _buildHistorico(),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavInferior(),
    );
  }

  Widget _buildSecao(String titulo, List<_Treino> treinos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < treinos.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFEFEFEF),
                  ),
                _buildLinhaTreino(treinos[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinhaTreino(_Treino treino) {
    return InkWell(
      onTap: () => _abrirTreino(treino),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                treino.nome,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEDEDED),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                treino.objetivo,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorico() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _abrirHistorico,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Histórico de treinos',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              Text(
                'Abrir',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavInferior() {
    final itens = [
      (Icons.calendar_today, 'Agenda'),
      (Icons.fitness_center, 'Treinos'),
      (Icons.trending_up, 'Evolução'),
      (Icons.person, 'Perfil'),
    ];
    return Container(
      color: kGreen,
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(itens.length, (index) {
            final selecionado = _navSelecionado == index;
            final item = itens[index];
            final cor = selecionado ? Colors.white : Colors.white54;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (index == 0) {
                    // Agenda: volta para a tela anterior.
                    Navigator.of(context).pop();
                  } else if (index == 2) {
                    // Evolução: troca esta tela pela de evolução.
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const TelaEvolucaoAluno(),
                      ),
                    );
                  } else if (index == 3) {
                    // Perfil: troca esta tela pela de perfil.
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const TelaPerfilAluno(),
                      ),
                    );
                  } else {
                    setState(() => _navSelecionado = index);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicador no topo do item selecionado.
                    Container(
                      height: 3,
                      width: 28,
                      decoration: BoxDecoration(
                        color: selecionado ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(item.$1, size: 22, color: cor),
                    const SizedBox(height: 4),
                    Text(
                      item.$2,
                      style: TextStyle(fontSize: 11, color: cor),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _Treino {
  final String id;
  final String nome;
  final String objetivo;
  const _Treino({
    required this.id,
    required this.nome,
    required this.objetivo,
  });
}