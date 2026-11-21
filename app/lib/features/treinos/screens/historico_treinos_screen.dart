// app/lib/features/treinos/screens/historico_treinos_screen.dart
//
// Histórico de treinos de um aluno (professor): execuções dos últimos 30
// dias. Dados de `historicoAlunoProvider(idAluno)`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/cartao_lista.dart';
import '../../../core/design_system/components/texto_apoio.dart';
import '../../../core/design_system/tokens/cores_provisorias.dart';
import '../../../core/state/estado_async.dart';
import '../../../core/utils/datas.dart';
import '../../../core/utils/nomes.dart';
import '../../vinculos/state/vinculos_providers.dart';
import '../data/treinos_professor_repository.dart';
import '../state/treinos_providers.dart';

class HistoricoTreinosScreen extends ConsumerWidget {
  const HistoricoTreinosScreen({super.key, required this.idAluno});

  final int idAluno;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historico = ref.watch(historicoAlunoProvider(idAluno));
    final nome = ref.watch(alunoDetalheProvider(idAluno)).valueOrNull?.nome;

    return Scaffold(
        appBar: appBarInterna(
          context,
          nome == null ? 'Histórico' : 'Histórico de ${nomeCurto(nome)}',
        ),
        body: SafeArea(
          child: EstadoAsync<HistoricoAluno>(
            valor: historico,
            aoTentarNovamente: () =>
                ref.invalidate(historicoAlunoProvider(idAluno)),
            vazio: (h) => h.execucoes.isEmpty,
            textoVazio: 'Nenhuma execução nos últimos 30 dias.',
            dados: (h) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                TextoApoio('${h.total} execuções nos últimos 30 dias'),
                const SizedBox(height: 16),
                CartaoLista(
                  itens: [
                    for (final e in h.execucoes)
                      ItemLista(
                        // TODO(design): o mockup mostra "Ontem, 31/08"; aqui
                        // só dd/MM.
                        titulo:
                            '${e.treino}  ·  ${Datas.diaMes(e.data) ?? e.data}',
                        trailing: _StatusExecucao(concluido: e.concluido),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class _StatusExecucao extends StatelessWidget {
  const _StatusExecucao({required this.concluido});

  final bool concluido;

  @override
  Widget build(BuildContext context) {
    final cor = concluido ? corInstitucional : Colors.grey.shade600;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          concluido ? Icons.check : Icons.radio_button_unchecked,
          size: 20,
          color: cor,
        ),
        const SizedBox(width: 4),
        Text(
          concluido ? 'Concluído' : 'Não concluído',
          style: TextStyle(
            fontSize: 12,
            fontWeight: concluido ? FontWeight.w600 : FontWeight.w400,
            color: cor,
          ),
        ),
      ],
    );
  }
}
