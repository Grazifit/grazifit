// app/lib/features/treinos/screens/montar_treino_screen.dart
//
// PROTÓTIPO VISUAL — sem integração com backend. Dados fictícios do mockup.
// Integração com o backend: ver docs/handoff-front-professor.md
//
// Montar treino (professor): nome, aluno, tipo, lista reordenável de
// exercícios e "Salvar treino". Aberta por "Montar novo treino" em
// Treinos do aluno.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/botao_primario.dart';
import '../../../core/design_system/components/campo_texto.dart';
import '../../../core/design_system/components/texto_apoio.dart';
import '../../../core/design_system/tokens/cores_provisorias.dart';
import '../../../core/state/estado_async.dart';
import '../../vinculos/state/vinculos_providers.dart';

class MontarTreinoScreen extends ConsumerStatefulWidget {
  const MontarTreinoScreen({super.key, required this.idAluno});

  final int idAluno;

  @override
  ConsumerState<MontarTreinoScreen> createState() =>
      _MontarTreinoScreenState();
}

class _MontarTreinoScreenState extends ConsumerState<MontarTreinoScreen> {
  static const _tipos = ['Força', 'Hipertrofia', 'Cardio'];

  final _nomeController = TextEditingController();
  int _tipo = 0;

  // TODO(backend): exercícios vêm da feature exercicios (catálogo); séries,
  // repetições e carga ficam em treino_exercicio. Começa vazio: a escolha de
  // exercício depende do catálogo, que ainda não existe.
  final _exercicios = <_Exercicio>[];

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  void _reordenar(int antigo, int novo) {
    setState(() {
      if (novo > antigo) novo -= 1;
      final item = _exercicios.removeAt(antigo);
      _exercicios.insert(novo, item);
    });
  }

  // TODO(backend): salvar cria treino + treino_exercicio para `widget.idAluno`
  // (aluno com vínculo ativo). Ainda não há endpoint.
  void _salvar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(TextosEstado.pendente)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: appBarInterna(context, 'Montar treino'),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              CampoTexto(
                label: 'Nome do treino',
                controller: _nomeController,
                helper: 'Como o aluno verá',
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              const Text(
                'Aluno',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ref.watch(alunoDetalheProvider(widget.idAluno)).valueOrNull?.nome ??
                      '—',
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tipo do treino',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (var i = 0; i < _tipos.length; i++)
                    _ChipTipo(
                      rotulo: _tipos[i],
                      selecionado: i == _tipo,
                      onTap: () => setState(() => _tipo = i),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Exercícios',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorder: _reordenar,
                children: [
                  for (var i = 0; i < _exercicios.length; i++)
                    _LinhaExercicio(
                      key: ValueKey(_exercicios[i].nome),
                      indice: i,
                      exercicio: _exercicios[i],
                      ultima: i == _exercicios.length - 1,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: corInstitucional,
                    side: const BorderSide(color: corInstitucional),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // TODO: abrir a escolha de exercício quando a tela existir.
                  onPressed: () {},
                  child: const Text(
                    'Adicionar exercício',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BarraAcaoInferior(
          texto: 'Salvar treino',
          onPressed: _salvar,
        ),
      );
  }
}

class _Exercicio {
  const _Exercicio(this.nome, this.series, this.repeticoes, this.cargaKg);

  final String nome;
  final int series;
  final int repeticoes;
  final int cargaKg;

  String get resumo => '$series × $repeticoes · $cargaKg kg';
}

class _LinhaExercicio extends StatelessWidget {
  const _LinhaExercicio({
    super.key,
    required this.indice,
    required this.exercicio,
    required this.ultima,
  });

  final int indice;
  final _Exercicio exercicio;
  final bool ultima;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: ultima
            ? null
            : const Border(bottom: BorderSide(color: corDivisor)),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: indice,
            child: Icon(Icons.drag_handle, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 16,
            child: Text(
              '${indice + 1}',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercicio.nome,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                TextoApoio(exercicio.resumo),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip com estado selecionado. O ChipFiltro do design system ainda não tem
/// esse estado; ideal é uma variante lá (aprovação do time).
class _ChipTipo extends StatelessWidget {
  const _ChipTipo({
    required this.rotulo,
    required this.selecionado,
    required this.onTap,
  });

  final String rotulo;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionado ? corInstitucional : corSuperficieSuave,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            rotulo,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selecionado ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}