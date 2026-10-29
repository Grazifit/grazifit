// app/lib/features/vinculos/screens/aluno_detalhe_screen.dart
//
// PROTÓTIPO VISUAL — sem integração com backend. Dados fictícios locais.
// Integração com o backend: ver docs/handoff-front-professor.md

import 'package:flutter/material.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/cartao_lista.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/design_system/components/texto_apoio.dart';
import '../../../core/design_system/tokens/cores_provisorias.dart';
import '../../treinos/screens/historico_treinos_screen.dart';
import '../../treinos/screens/treinos_aluno_screen.dart';

class AlunoDetalheScreen extends StatefulWidget {
  const AlunoDetalheScreen({super.key, required this.nome});

  final String nome;

  @override
  State<AlunoDetalheScreen> createState() => _AlunoDetalheScreenState();
}

class _AlunoDetalheScreenState extends State<AlunoDetalheScreen> {
  bool _saudeAberta = true;

  // TODO(backend): vem de aluno.restricao_medica / observacao_saude. O DTO
  // atual de aluno é a visão do ADMIN e não traz esses campos: falta um DTO
  // da visão do professor (aprovação). Ver o guia, item L4.
  // Texto fictício do mockup.
  static const _informacoesSaude =
      'Condromalácia patelar leve no joelho direito. Evitar impacto alto.';

  @override
  Widget build(BuildContext context) {
    return FundoTela(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBarInterna(context, widget.nome),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              // TODO(backend): vinculo_professor_aluno.data_inicio.
              const TextoApoio('Vínculo ativo desde 12/03/2025'),
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
                    _informacoesSaude,
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
                    // TODO(backend): contagem real de treinos do aluno.
                    subtitulo: '2 treinos personalizados',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            TreinosAlunoScreen(nomeAluno: widget.nome),
                      ),
                    ),
                  ),
                  // TODO: ligar à tela "Avaliação física" (professor) quando
                  // existir. Subtítulo vem da última avaliação (IMC é
                  // calculado no banco: vw_aluno_medida_atual).
                  const ItemLista(
                    titulo: 'Avaliação física',
                    subtitulo: 'Última em 12/08 · IMC 25,7',
                  ),
                  ItemLista(
                    titulo: 'Histórico de treinos',
                    // TODO(backend): contagem real de execuções em 30 dias.
                    subtitulo: '12 execuções em 30 dias',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            HistoricoTreinosScreen(nomeAluno: widget.nome),
                      ),
                    ),
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