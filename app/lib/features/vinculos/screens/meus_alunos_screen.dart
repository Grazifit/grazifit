// app/lib/features/vinculos/screens/meus_alunos_screen.dart
//
// PROTÓTIPO VISUAL — sem integração com backend. Dados fictícios locais.
// Integração com o backend: ver docs/handoff-front-professor.md

import 'package:flutter/material.dart';

import '../../../core/design_system/components/barra_navegacao.dart';
import '../../../core/design_system/components/campo_busca.dart';
import '../../../core/design_system/components/cartao_lista.dart';
import '../../../core/design_system/components/chip_filtro.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/design_system/components/texto_apoio.dart';
import 'aluno_detalhe_screen.dart';
import 'alunos_inativos_screen.dart';

class MeusAlunosScreen extends StatefulWidget {
  const MeusAlunosScreen({super.key});

  @override
  State<MeusAlunosScreen> createState() => _MeusAlunosScreenState();
}

class _MeusAlunosScreenState extends State<MeusAlunosScreen> {
  final _buscaController = TextEditingController();
  String _busca = '';

  // TODO(backend): trocar por alunos com vínculo ATIVO do professor logado
  // (vinculo_professor_aluno.status = true) + data da última avaliação.
  // Ainda não há endpoint (feature vinculos só tem README). GET /aluno é
  // listagem geral do admin, não serve sem decisão. Ver o guia, item L3.
  // Dados fictícios do mockup. O contador do subtítulo ("8 alunos") também é
  // fixo aqui; no real virá do total de vínculos ativos.
  static const _alunos = [
    _AlunoResumo('Ana Beatriz Ramos', 'Última avaliação em 12/08'),
    _AlunoResumo('Carlos Menezes', 'Sem avaliação registrada'),
    _AlunoResumo('Júlia Prado', 'Última avaliação em 03/08'),
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
        _alunos.where((a) => a.nome.toLowerCase().contains(termo)).toList();

    return FundoTela(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              const Text(
                'Meus alunos',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              // TODO(backend): o "8" vem do total de vínculos ativos.
              const TextoApoio('8 alunos com vínculo ativo'),
              const SizedBox(height: 20),
              CampoBusca(
                controller: _buscaController,
                hint: 'Buscar aluno',
                onChanged: (v) => setState(() => _busca = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const ChipFiltro(rotulo: 'Ativos'),
                  const SizedBox(width: 12),
                  ChipFiltro(
                    rotulo: 'Inativos',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AlunosInativosScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // TODO(backend): hoje a busca filtra a lista local. Decidir se
              // vai para o servidor (GET /aluno já tem limit/offset).
              // Estados a cobrir: carregando, vazio, erro, sem conexão.
              if (filtrados.isEmpty)
                const TextoApoio('Nenhum aluno encontrado')
              else
                CartaoLista(
                  itens: [
                    for (final aluno in filtrados)
                      ItemLista(
                        titulo: aluno.nome,
                        subtitulo: aluno.avaliacao,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AlunoDetalheScreen(nome: aluno.nome),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        bottomNavigationBar: const BarraNavegacao(indiceAtual: 1),
      ),
    );
  }
}

class _AlunoResumo {
  const _AlunoResumo(this.nome, this.avaliacao);

  final String nome;
  final String avaliacao;
}