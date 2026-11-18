// app/lib/features/aulas/screens/detalhe_aula_screen.dart
//
// PROTÓTIPO VISUAL — sem integração com backend. Dados fictícios do mockup.
// Integração com o backend: ver docs/handoff-front-professor.md
//
// Detalhe da aula (professor). Cobre os quatro quadros do mockup:
// detalhe, modal "Cancelar esta aula?", aula cancelada (banner vermelho e
// alunos como "Cancelado") e o caminho para a Chamada.

import 'package:flutter/material.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/badge_status.dart';
import '../../../core/design_system/components/botao_primario.dart';
import '../../../core/design_system/components/cartao_lista.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/design_system/components/texto_apoio.dart';
import '../../../core/design_system/tokens/cores_provisorias.dart';
import '../../agendamentos/screens/chamada_screen.dart';
import '../widgets/cartao_aula.dart';

class DetalheAulaScreen extends StatefulWidget {
  const DetalheAulaScreen({
    super.key,
    this.horario = '07:00 - 08:00',
    this.modalidade = 'Funcional',
    this.professor = 'Prof. Marina Alves',
    this.vagasOcupadas = 8,
    this.vagasTotais = 12,
    this.alunos = const ['Ana Beatriz Ramos', 'Carlos Menezes', 'Júlia Prado'],
    this.cancelada = false,
    this.dataCancelamento = '01/09',
  });

  // Valores padrão = dados fictícios do mockup.
  final String horario;
  final String modalidade;
  final String professor;
  final int vagasOcupadas;
  final int vagasTotais;
  final List<String> alunos;

  /// Abre a tela já no estado "aula cancelada".
  final bool cancelada;
  final String dataCancelamento;

  @override
  State<DetalheAulaScreen> createState() => _DetalheAulaScreenState();
}

class _DetalheAulaScreenState extends State<DetalheAulaScreen> {
  late bool _cancelada = widget.cancelada;

  String get _avisoCancelamento {
    final n = widget.alunos.length;
    final agendados = n == 1 ? '1 aluno está agendado' : '$n alunos estão agendados';
    return '$agendados. Os agendamentos são cancelados junto e cada aluno '
        'recebe o aviso.';
  }

  void _fazerChamada() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChamadaScreen(
          modalidade: widget.modalidade,
          horario: widget.horario,
          alunos: widget.alunos,
        ),
      ),
    );
  }

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
    if (confirmou == true && mounted) {
      setState(() => _cancelada = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FundoTela(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBarInterna(context, 'Detalhe da aula'),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (_cancelada) ...[
                _BannerCancelada(
                  texto: 'Aula cancelada por você em ${widget.dataCancelamento}',
                ),
                const SizedBox(height: 12),
              ],
              CartaoAula(
                horario: widget.horario,
                modalidade: widget.modalidade,
                professor: widget.professor,
                vagasOcupadas: widget.vagasOcupadas,
                vagasTotais: widget.vagasTotais,
              ),
              const SizedBox(height: 16),
              TextoApoio('Alunos agendados (${widget.alunos.length})'),
              const SizedBox(height: 8),
              CartaoLista(
                itens: [
                  for (final aluno in widget.alunos)
                    ItemLista(
                      titulo: aluno,
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