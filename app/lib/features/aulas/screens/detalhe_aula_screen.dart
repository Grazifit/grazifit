// app/lib/features/aulas/screens/detalhe_aula_screen.dart
//
// Dados de `detalheAulaProvider(idAula)`. Integração: docs/integracao-frontend.md
//
// Detalhe da aula (professor). Cobre os quatro quadros do mockup:
// detalhe, modal "Cancelar esta aula?", aula cancelada (banner vermelho e
// alunos como "Cancelado") e o caminho para a Chamada.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/badge_status.dart';
import '../../../core/design_system/components/botao_primario.dart';
import '../../../core/design_system/components/cartao_lista.dart';
import '../../../core/design_system/components/texto_apoio.dart';
import '../../../core/design_system/tokens/cores_provisorias.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/state/estado_async.dart';
import '../../../core/utils/datas.dart';
import '../data/aulas_professor_repository.dart';
import '../state/aulas_providers.dart';
import '../widgets/cartao_aula.dart';
import '../../../core/data/repositorios.dart';
import '../../agendamentos/screens/chamada_screen.dart';

class DetalheAulaScreen extends ConsumerWidget {
  const DetalheAulaScreen({super.key, required this.idAula});

  final int idAula;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalhe = ref.watch(detalheAulaProvider(idAula));
    final d = detalhe.valueOrNull;
    if (d != null) return _DetalheAulaConteudo(detalhe: d);

    return Scaffold(
        appBar: appBarInterna(context, 'Detalhe da aula'),
        body: SafeArea(
          child: EstadoAsync<AulaProfessorDetalhe>(
            valor: detalhe,
            aoTentarNovamente: () => ref.invalidate(detalheAulaProvider(idAula)),
            vazio: (_) => false,
            dados: (_) => const SizedBox.shrink(),
          ),
        ),
      );
  }
}

class _DetalheAulaConteudo extends ConsumerStatefulWidget {
  const _DetalheAulaConteudo({required this.detalhe});

  final AulaProfessorDetalhe detalhe;

  @override
  ConsumerState<_DetalheAulaConteudo> createState() =>
      _DetalheAulaConteudoState();
}

class _DetalheAulaConteudoState extends ConsumerState<_DetalheAulaConteudo> {
  late bool _cancelada = widget.detalhe.aula.cancelada;
  late String? _dataCancelamento = widget.detalhe.aula.dataCancelamento;

  String get _avisoCancelamento {
    final n = widget.detalhe.alunos.length;
    final agendados = n == 1 ? '1 aluno está agendado' : '$n alunos estão agendados';
    return '$agendados. Os agendamentos são cancelados junto e cada aluno '
        'recebe o aviso.';
  }

  void _fazerChamada() =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChamadaScreen(idAula: widget.detalhe.aula.idAula)));

  // TODO(backend): cancelar a aula cancela os agendamentos em cascata
  // (AulaService.cancelar → AgendamentoService.cancelarEmCascata, F-12/D9) e
  // avisa cada aluno. Aqui só muda o estado da tela.
  Future<void> _confirmarCancelamento() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Cancelar esta aula?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Text(
          _avisoCancelamento,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: corInstitucional),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: corErro,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancelar aula'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    final mensagem = ScaffoldMessenger.of(context);
    try {
      await Repositorios.aulasProfessor
          .cancelar(widget.detalhe.aula.idAula);
    } on ApiException {
      // TODO(design): texto do erro de cancelamento não está no mockup.
      mensagem.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível cancelar. Tente novamente.'),
        ),
      );
      return;
    }
    ref.invalidate(agendaProfessorProvider);
    ref.invalidate(detalheAulaProvider(widget.detalhe.aula.idAula));
    if (mounted) {
      setState(() {
        _cancelada = true;
        _dataCancelamento ??= widget.detalhe.data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: appBarInterna(context, 'Detalhe da aula'),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (_cancelada) ...[
                _BannerCancelada(
                  texto: 'Aula cancelada por você em ${Datas.diaMes(_dataCancelamento) ?? ''}',
                ),
                const SizedBox(height: 12),
              ],
              CartaoAula(
                horario: widget.detalhe.aula.horario,
                modalidade: widget.detalhe.aula.modalidade,
                professor: widget.detalhe.aula.professor,
                vagasOcupadas: widget.detalhe.aula.vagasOcupadas,
                vagasTotais: widget.detalhe.aula.vagasTotais,
              ),
              const SizedBox(height: 16),
              TextoApoio('Alunos agendados (${widget.detalhe.alunos.length})'),
              const SizedBox(height: 8),
              CartaoLista(
                itens: [
                  for (final aluno in widget.detalhe.alunos)
                    ItemLista(
                      titulo: aluno.nome,
                      trailing: BadgeStatus(
                        texto: _cancelada ? 'Cancelado' : 'Agendado',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: _cancelada
            ? null
            : SafeArea(
                minimum: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BotaoPrimario(
                      texto: 'Fazer chamada',
                      onPressed: _fazerChamada,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: corInstitucional,
                      ),
                      onPressed: _confirmarCancelamento,
                      child: const Text('Cancelar esta aula'),
                    ),
                  ],
                ),
              ),
      );
  }
}

class _BannerCancelada extends StatelessWidget {
  const _BannerCancelada({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: corErro,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel_outlined, size: 20, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}