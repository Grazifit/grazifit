// app/lib/features/vinculos/screens/aluno_detalhe_screen.dart
//
// Detalhe do aluno (professor). Dados de `alunoDetalheProvider(idAluno)`.
// Dado clínico exige DTO próprio no backend (LGPD): ver o guia, L4.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/cartao_lista.dart';
import '../../../core/design_system/components/texto_apoio.dart';
import '../../../core/design_system/tokens/cores_provisorias.dart';
import '../../../core/state/estado_async.dart';
import '../../../core/utils/datas.dart';
import '../data/vinculos_repository.dart';
import '../state/vinculos_providers.dart';
import '../../avaliacoes/screens/avaliacao_fisica_professor_screen.dart';
import '../../treinos/screens/historico_treinos_screen.dart';
import '../../treinos/screens/treinos_aluno_screen.dart';

class AlunoDetalheScreen extends ConsumerStatefulWidget {
  const AlunoDetalheScreen({super.key, required this.idAluno});

  final int idAluno;

  @override
  ConsumerState<AlunoDetalheScreen> createState() => _AlunoDetalheScreenState();
}

class _AlunoDetalheScreenState extends ConsumerState<AlunoDetalheScreen> {
  bool _saudeAberta = true;

  /// Junta restrição médica e observação de saúde, só o que existir.
  String _textoSaude(AlunoDetalhe a) {
    final partes = [a.restricaoMedica, a.observacaoSaude]
        .whereType<String>()
        .where((t) => t.trim().isNotEmpty)
        .toList();
    return partes.isEmpty ? 'Nenhuma informação registrada.' : partes.join('\n\n');
  }

  String _subtituloAvaliacao(AlunoDetalhe a) {
    final dia = Datas.diaMes(a.ultimaAvaliacao);
    if (dia == null) return 'Sem avaliação registrada';
    final imc = a.imc == null ? '' : ' · IMC ${a.imc!.toStringAsFixed(1).replaceAll('.', ',')}';
    return 'Última em $dia$imc';
  }

  @override
  Widget build(BuildContext context) {
    final aluno = ref.watch(alunoDetalheProvider(widget.idAluno));

    return Scaffold(
        appBar: appBarInterna(context, aluno.valueOrNull?.nome ?? 'Aluno'),
        body: SafeArea(
          child: EstadoAsync<AlunoDetalhe>(
            valor: aluno,
            aoTentarNovamente: () =>
                ref.invalidate(alunoDetalheProvider(widget.idAluno)),
            vazio: (_) => false,
            dados: _conteudo,
          ),
        ),
      );
  }

  Widget _conteudo(AlunoDetalhe a) {
    final desde = Datas.diaMesAno(a.vinculoDesde);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        if (desde != null) TextoApoio('Vínculo ativo desde $desde'),
        const SizedBox(height: 24),
        InkWell(
          onTap: () => setState(() => _saudeAberta = !_saudeAberta),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Informações de saúde',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                Icon(
                  _saudeAberta
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: corInstitucional,
                ),
              ],
            ),
          ),
        ),
        if (_saudeAberta)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _textoSaude(a),
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: corInstitucional.withValues(alpha: 0.8),
              ),
            ),
          ),
        const SizedBox(height: 20),
        const Text(
          'Acompanhamento',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: corInstitucional,
          ),
        ),
        const SizedBox(height: 10),
        CartaoLista(
          itens: [
            ItemLista(
              titulo: 'Treinos do aluno',
              subtitulo: '${a.totalTreinos} treinos personalizados',
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TreinosAlunoScreen(idAluno: a.idAluno))),
            ),
            ItemLista(
              titulo: 'Avaliação física',
              subtitulo: _subtituloAvaliacao(a),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AvaliacaoFisicaProfessorScreen(idAluno: a.idAluno))),
            ),
            ItemLista(
              titulo: 'Histórico de treinos',
              subtitulo: '${a.execucoes30Dias} execuções em 30 dias',
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => HistoricoTreinosScreen(idAluno: a.idAluno))),
            ),
          ],
        ),
      ],
    );
  }
}
