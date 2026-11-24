// app/lib/features/vinculos/screens/meus_alunos_screen.dart
//
// Meus alunos (professor): alunos com vínculo ativo. Dados de
// `alunosAtivosProvider` (state/), que ainda depende do backend de vínculos.
// Integração: ver docs/integracao-frontend.md.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/components/barra_navegacao.dart';
import '../../../core/design_system/components/botao_sair.dart';
import '../../../core/design_system/components/campo_busca.dart';
import '../../../core/design_system/components/cartao_lista.dart';
import '../../../core/design_system/components/chip_filtro.dart';
import '../../../core/design_system/components/texto_apoio.dart';
import '../../../core/state/estado_async.dart';
import '../../../core/utils/datas.dart';
import '../data/vinculos_repository.dart';
import '../state/vinculos_providers.dart';
import 'aluno_detalhe_screen.dart';
import 'alunos_inativos_screen.dart';

class MeusAlunosScreen extends ConsumerStatefulWidget {
  const MeusAlunosScreen({super.key});

  @override
  ConsumerState<MeusAlunosScreen> createState() => _MeusAlunosScreenState();
}

class _MeusAlunosScreenState extends ConsumerState<MeusAlunosScreen> {
  final _buscaController = TextEditingController();
  String _busca = '';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  String _subtitulo(AlunoVinculado a) {
    final dia = Datas.diaMes(a.ultimaAvaliacao);
    return dia == null ? 'Sem avaliação registrada' : 'Última avaliação em $dia';
  }

  @override
  Widget build(BuildContext context) {
    final alunos = ref.watch(alunosAtivosProvider);
    final termo = _busca.trim().toLowerCase();

    return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Meus alunos',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  BotaoSair(),
                ],
              ),
              const SizedBox(height: 8),
              if (alunos.hasValue)
                TextoApoio('${alunos.value!.length} alunos com vínculo ativo'),
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
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AlunosInativosScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // A busca filtra a lista já carregada. Decidir se vai para o
              // servidor (GET /aluno tem limit/offset): ver o guia, L3.
              SizedBox(
                height: 320,
                child: EstadoAsync<List<AlunoVinculado>>(
                  valor: alunos,
                  aoTentarNovamente: () => ref.invalidate(alunosAtivosProvider),
                  textoVazio: 'Nenhum aluno encontrado',
                  dados: (lista) {
                    final filtrados = lista
                        .where((a) => a.nome.toLowerCase().contains(termo))
                        .toList();
                    if (filtrados.isEmpty) {
                      return const Center(
                        child: TextoApoio('Nenhum aluno encontrado'),
                      );
                    }
                    return SingleChildScrollView(
                      child: CartaoLista(
                        itens: [
                          for (final aluno in filtrados)
                            ItemLista(
                              titulo: aluno.nome,
                              subtitulo: _subtitulo(aluno),
                              onTap: () =>
                                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AlunoDetalheScreen(idAluno: aluno.idAluno))),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const BarraNavegacao(indiceAtual: 1),
      );
  }
}
