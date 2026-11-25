// app/lib/features/vinculos/screens/alunos_inativos_screen.dart
//
// Alunos vinculados sem acesso recente. A regra dos "30 dias" é do backend
// (não recalcular aqui). Dados de `alunosInativosProvider`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/campo_busca.dart';
import '../../../core/design_system/components/cartao_lista.dart';
import '../../../core/design_system/components/chip_filtro.dart';
import '../../../core/design_system/components/texto_apoio.dart';
import '../../../core/state/estado_async.dart';
import '../data/vinculos_repository.dart';
import '../state/vinculos_providers.dart';

class AlunosInativosScreen extends ConsumerStatefulWidget {
  const AlunosInativosScreen({super.key});

  @override
  ConsumerState<AlunosInativosScreen> createState() =>
      _AlunosInativosScreenState();
}

class _AlunosInativosScreenState extends ConsumerState<AlunosInativosScreen> {
  final _buscaController = TextEditingController();
  String _busca = '';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  String _subtitulo(AlunoInativo a) => a.diasSemAcesso == null
      ? 'Nunca acessou'
      : '${a.diasSemAcesso} dias sem acesso';

  @override
  Widget build(BuildContext context) {
    final inativos = ref.watch(alunosInativosProvider);
    final termo = _busca.trim().toLowerCase();

    return Scaffold(
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
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 320,
                child: EstadoAsync<List<AlunoInativo>>(
                  valor: inativos,
                  aoTentarNovamente: () =>
                      ref.invalidate(alunosInativosProvider),
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
                          for (final a in filtrados)
                            ItemLista(
                              titulo: a.nome,
                              subtitulo: _subtitulo(a),
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
      );
  }
}
