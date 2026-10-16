// app/lib/features/treinos/screens/treinos_aluno_screen.dart
//
// PROTÓTIPO VISUAL — sem integração com backend. Dados fictícios locais.
//
// Suposição do protótipo: tocar na linha alterna entre "Concluído hoje" e
// "Não executado", para visualizar os dois estados. O comportamento real de
// confirmar execução (e o registro no histórico) depende de backend.

import 'package:flutter/material.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/badge_status.dart';
import '../../../core/design_system/components/botao_primario.dart';
import '../../../core/design_system/components/cartao_lista.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/design_system/components/texto_apoio.dart';
import '../../../core/utils/nomes.dart';

class TreinosAlunoScreen extends StatefulWidget {
  const TreinosAlunoScreen({super.key, required this.nomeAluno});

  final String nomeAluno;

  @override
  State<TreinosAlunoScreen> createState() => _TreinosAlunoScreenState();
}

class _TreinosAlunoScreenState extends State<TreinosAlunoScreen> {
  final _treinos = <_Treino>[
    _Treino('Inferiores A', concluidoHoje: true),
    _Treino('Superiores B', concluidoHoje: false),
  ];

  @override
  Widget build(BuildContext context) {
    return FundoTela(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBarInterna(context, 'Treinos de ${nomeCurto(widget.nomeAluno)}'),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              CartaoLista(
                itens: [
                  for (final t in _treinos)
                    ItemLista(
                      titulo: t.nome,
                      trailing: BadgeStatus(
                        texto: t.concluidoHoje
                            ? 'Concluído hoje'
                            : 'Não executado',
                        destaque: t.concluidoHoje,
                      ),
                      onTap: () =>
                          setState(() => t.concluidoHoje = !t.concluidoHoje),
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
        bottomNavigationBar: BarraAcaoInferior(
          texto: 'Montar novo treino',
          // TODO: navegar para a tela de montagem de treino quando existir.
          onPressed: () {},
        ),
      ),
    );
  }
}

class _Treino {
  _Treino(this.nome, {required this.concluidoHoje});

  final String nome;
  bool concluidoHoje;
}