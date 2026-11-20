import 'package:flutter/material.dart';

import '../../../core/data/repositorios.dart';
import '../../../core/theme/app_colors.dart';
import '../data/treino_resumo.dart';
import '../data/treinos_repository.dart';
import 'tela_detalhe_treino_aluno.dart';
import '../../pessoas/screens/tela_perfil_aluno.dart';
import '../../avaliacoes/screens/tela_evolucao_aluno.dart';

/// Tela de treinos do aluno: treinos montados pelo professor,
/// treinos livres e acesso ao histórico.
///
/// Os dados vêm de um [TreinosRepository]. Se nenhum for informado, usa o
/// definido em `core/data/repositorios.dart`.
class TelaTreinosAluno extends StatefulWidget {
  final TreinosRepository? repository;

  const TelaTreinosAluno({super.key, this.repository});

  @override
  State<TelaTreinosAluno> createState() => _TelaTreinosAlunoState();
}

class _TelaTreinosAlunoState extends State<TelaTreinosAluno> {
  static const Color kGreen = AppColors.verde;
  static const Color kBackground = AppColors.fundo;

  int _navSelecionado = 1;

  late final TreinosRepository _repo;
  late Future<TreinosDoAluno> _future;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? Repositorios.treinos;
    _future = _repo.buscarTreinos();
  }

  void _recarregar() {
    setState(() {
      _future = _repo.buscarTreinos();
    });
  }

  void _abrirTreino(TreinoResumo treino) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TelaDetalheTreinoAluno(
          treinoId: treino.id,
          nome: treino.nome,
          repository: _repo,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'Treinos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<TreinosDoAluno>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(color: kGreen),
                    );
                  }
                  if (snapshot.hasError || snapshot.data == null) {
                    return _buildErro();
                  }
                  return _buildConteudo(snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavInferior(),
    );
  }

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.black45),
            const SizedBox(height: 12),
            const Text(
              'Não foi possível carregar os treinos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _recarregar,
              style: OutlinedButton.styleFrom(
                foregroundColor: kGreen,
                side: const BorderSide(color: kGreen),
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudo(TreinosDoAluno dados) {
    final vazio =
        dados.treinosDoProfessor.isEmpty && dados.treinosLivres.isEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        if (vazio)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Nenhum treino disponível.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
          )
        else ...[
          if (dados.treinosDoProfessor.isNotEmpty) ...[
            _buildSecao(
              'Feitos para você · ${dados.professor}',
              dados.treinosDoProfessor,
            ),
            const SizedBox(height: 20),
          ],
          if (dados.treinosLivres.isNotEmpty) ...[
            _buildSecao('Treinos livres', dados.treinosLivres),
            const SizedBox(height: 20),
          ],
        ],
        _buildHistorico(),
      ],
    );
  }

  Widget _buildSecao(String titulo, List<TreinoResumo> treinos) {
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

  Widget _buildLinhaTreino(TreinoResumo treino) {
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
