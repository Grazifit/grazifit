// app/lib/features/treinos/screens/historico_treinos_screen.dart
//
// PROTÓTIPO VISUAL — sem integração com backend. Dados fictícios locais.
// Integração com o backend: ver docs/handoff-front-professor.md

import 'package:flutter/material.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/cartao_lista.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/design_system/components/texto_apoio.dart';
import '../../../core/design_system/tokens/cores_provisorias.dart';
import '../../../core/utils/nomes.dart';

class HistoricoTreinosScreen extends StatelessWidget {
  const HistoricoTreinosScreen({super.key, required this.nomeAluno});

  final String nomeAluno;

  // TODO(backend): vem de historico_treino do aluno (últimos 30 dias).
  // "Ontem, 31/08" é formatação da data: fazer no app a partir da data real.
  // Estados a cobrir: carregando, vazio, erro, sem conexão.
  static const _execucoes = [
    _Execucao('Inferiores A', 'Ontem, 31/08', true),
    _Execucao('Superiores B', '29/08', true),
    _Execucao('Inferiores A', '27/08', false),
    _Execucao('Full body iniciante', '25/08', true),
  ];

  @override
  Widget build(BuildContext context) {
    return FundoTela(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBarInterna(context, 'Histórico de ${nomeCurto(nomeAluno)}'),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              // TODO(backend): total real de execuções no período.
              const TextoApoio('12 execuções nos últimos 30 dias'),
              const SizedBox(height: 16),
              CartaoLista(
                itens: [
                  for (final e in _execucoes)
                    ItemLista(
                      titulo: '${e.treino}  ·  ${e.data}',
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

class _Execucao {
  const _Execucao(this.treino, this.data, this.concluido);

  final String treino;
  final String data;
  final bool concluido;
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