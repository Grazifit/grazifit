import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/treino_detalhe.dart';
import '../data/treinos_repository.dart';

/// Detalhe de um treino do aluno: exercícios com séries, repetições e carga,
/// e o botão para confirmar a execução. Os dados vêm do [TreinosRepository].
class TelaDetalheTreinoAluno extends StatefulWidget {
  final String treinoId;

  /// Nome mostrado na barra do topo enquanto os dados carregam.
  final String nome;

  /// Repositório de dados. Se não for informado, usa o mock.
  /// TODO: trocar o padrão pela implementação que chama o backend.
  final TreinosRepository? repository;

  const TelaDetalheTreinoAluno({
    super.key,
    required this.treinoId,
    required this.nome,
    this.repository,
  });

  @override
  State<TelaDetalheTreinoAluno> createState() => _TelaDetalheTreinoAlunoState();
}

class _TelaDetalheTreinoAlunoState extends State<TelaDetalheTreinoAluno> {
  late final TreinosRepository _repo;
  late Future<TreinoDetalhe> _future;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? TreinosRepositoryMock();
    _future = _repo.buscarTreino(widget.treinoId);
  }

  void _recarregar() {
    setState(() => _future = _repo.buscarTreino(widget.treinoId));
  }

  Future<void> _confirmar() async {
    setState(() => _enviando = true);
    try {
      await _repo.confirmarExecucao(widget.treinoId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Execução confirmada!')),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível confirmar. Tente novamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(
        backgroundColor: AppColors.fundo,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black87,
        titleSpacing: 0,
        title: Text(
          widget.nome,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: FutureBuilder<TreinoDetalhe>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.verde),
            );
          }
          if (snapshot.hasError || snapshot.data == null) {
            return _buildErro();
          }
          return _buildConteudo(snapshot.data!);
        },
      ),
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
              'Não foi possível carregar o treino.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _recarregar,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.verde,
                side: const BorderSide(color: AppColors.verde),
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudo(TreinoDetalhe treino) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEDED),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  treino.objetivo,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'por ${treino.professor}',
                style: const TextStyle(fontSize: 11.5, color: Colors.black54),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (int i = 0; i < treino.exercicios.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFEFEFEF),
                        ),
                      _buildExercicio(treino.exercicios[i]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _enviando ? null : _confirmar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verde,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.verde.withOpacity(0.6),
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _enviando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Confirmar execução',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExercicio(ExercicioTreino exercicio) {
    final detalhes = <String>[
      if (exercicio.descansoSegundos != null)
        'Descanso: ${exercicio.descansoSegundos}s',
      if (exercicio.observacao != null && exercicio.observacao!.isNotEmpty)
        exercicio.observacao!,
    ];

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: AppColors.verde,
        collapsedIconColor: AppColors.verde,
        title: Text(
          _resumo(exercicio),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        children: [
          if (detalhes.isEmpty)
            const Text(
              'Sem observações.',
              style: TextStyle(fontSize: 12.5, color: Colors.black54),
            )
          else
            for (final linha in detalhes)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  linha,
                  style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                ),
              ),
        ],
      ),
    );
  }

  /// Ex.: "Agachamento livre · 3 × 12 · 40 kg".
  String _resumo(ExercicioTreino e) {
    final partes = <String>[e.nome, '${e.series} × ${e.repeticoes}'];
    if (e.carga != null) partes.add('${_formatarCarga(e.carga!)} kg');
    return partes.join(' · ');
  }

  String _formatarCarga(double carga) {
    if (carga % 1 == 0) return carga.toStringAsFixed(0);
    return carga.toStringAsFixed(1).replaceAll('.', ',');
  }
}