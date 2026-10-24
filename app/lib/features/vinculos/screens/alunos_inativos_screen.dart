// app/lib/features/vinculos/screens/alunos_inativos_screen.dart
//
// PROTÓTIPO VISUAL — sem integração com backend. Dados fictícios locais.

import 'package:flutter/material.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/campo_busca.dart';
import '../../../core/design_system/components/cartao_lista.dart';
import '../../../core/design_system/components/chip_filtro.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/design_system/components/texto_apoio.dart';

class AlunosInativosScreen extends StatefulWidget {
  const AlunosInativosScreen({super.key});

  @override
  State<AlunosInativosScreen> createState() => _AlunosInativosScreenState();
}

class _AlunosInativosScreenState extends State<AlunosInativosScreen> {
  final _buscaController = TextEditingController();
  String _busca = '';

  static const _inativos = [
    _AlunoInativo('Carlos Menezes', 47),
    _AlunoInativo('Júlia Prado', 38),
    _AlunoInativo('Bruno Tavares', 31),
  ];

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final termo = _busca.trim().toLowerCase();
    final filtrados =
        _inativos.where((a) => a.nome.toLowerCase().contains(termo)).toList();

    return FundoTela(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBarInterna(context, 'Inativos'),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const TextoApoio('Alunos vinculados sem acesso há 30 dias'),
              const SizedBox(height: 16),
              CampoBusca(
                controller: _buscaController,
                hint: 'Buscar aluno',
                onChanged: (v) => setState(() => _busca = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ChipFiltro(
                    rotulo: 'Meus alunos',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (filtrados.isEmpty)
                const TextoApoio('Nenhum aluno encontrado')
              else
                CartaoLista(
                  itens: [
                    for (final a in filtrados)
                      ItemLista(
                        titulo: a.nome,
                        subtitulo: '${a.diasSemAcesso} dias sem acesso',
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

class _AlunoInativo {
  const _AlunoInativo(this.nome, this.diasSemAcesso);

  final String nome;
  final int diasSemAcesso;
}