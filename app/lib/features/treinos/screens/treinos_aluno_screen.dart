// app/lib/features/treinos/screens/treinos_aluno_screen.dart
//
// Treinos de um aluno (professor). Dados de `treinosDoAlunoProvider`.
// Tocar em um treino ainda não concluído hoje confirma a execução.
// Lacuna D29: `historico_treino` não registra quem confirmou (levar ao time).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/badge_status.dart';
import '../../../core/design_system/components/botao_primario.dart';
import '../../../core/design_system/components/cartao_lista.dart';
import '../../../core/design_system/components/texto_apoio.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/state/estado_async.dart';
import '../../../core/utils/nomes.dart';
import '../../vinculos/state/vinculos_providers.dart';
import '../data/treinos_professor_repository.dart';
import '../state/treinos_providers.dart';
import '../../../core/data/repositorios.dart';
import 'montar_treino_screen.dart';

class TreinosAlunoScreen extends ConsumerWidget {
  const TreinosAlunoScreen({super.key, required this.idAluno});

  final int idAluno;

  Future<void> _confirmar(
    BuildContext context,
    WidgetRef ref,
    TreinoDoAluno t,
  ) async {
    if (t.concluidoHoje) return;
    final mensagem = ScaffoldMessenger.of(context);
    try {
      await Repositorios.treinosProfessor
          .confirmarExecucao(idAluno, t.id);
      ref.invalidate(treinosDoAlunoProvider(idAluno));
    } on ApiException {
      // TODO(design): texto do erro de confirmação não está no mockup.
      mensagem.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível confirmar. Tente novamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treinos = ref.watch(treinosDoAlunoProvider(idAluno));
    final nome = ref.watch(alunoDetalheProvider(idAluno)).valueOrNull?.nome;

    return Scaffold(
        appBar: appBarInterna(
          context,
          nome == null ? 'Treinos' : 'Treinos de ${nomeCurto(nome)}',
        ),
        body: SafeArea(
          child: EstadoAsync<List<TreinoDoAluno>>(
            valor: treinos,
            aoTentarNovamente: () =>
                ref.invalidate(treinosDoAlunoProvider(idAluno)),
            textoVazio: 'Este aluno ainda não tem treinos.',
            dados: (lista) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                CartaoLista(
                  itens: [
                    for (final t in lista)
                      ItemLista(
                        titulo: t.nome,
                        trailing: BadgeStatus(
                          texto: t.concluidoHoje
                              ? 'Concluído hoje'
                              : 'Não executado',
                          destaque: t.concluidoHoje,
                        ),
                        onTap: () => _confirmar(context, ref, t),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const TextoApoio(
                  'Confirmar execução por aqui registra no histórico do aluno.',
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BarraAcaoInferior(
          texto: 'Montar novo treino',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MontarTreinoScreen(idAluno: idAluno))),
        ),
      );
  }
}
