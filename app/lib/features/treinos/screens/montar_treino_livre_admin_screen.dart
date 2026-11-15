import 'package:flutter/material.dart';

import '../../../../core/design_system/components/app_bar_interna.dart';
import '../../../../core/design_system/components/botao_primario.dart';
import '../../../../core/design_system/components/campo_texto.dart';
import '../../../../core/design_system/components/fundo_tela.dart';
import '../../../../core/design_system/components/texto_apoio.dart';
import '../../../../core/design_system/tokens/cores_provisorias.dart';

enum TipoTreinoLivreAdmin {
  resistencia('resistencia', 'Resistência'),
  cardio('cardio', 'Cardio'),
  mobilidade('mobilidade', 'Mobilidade');

  const TipoTreinoLivreAdmin(this.codigo, this.rotulo);

  final String codigo;
  final String rotulo;
}

/// Exercício já selecionado do catálogo. O Admin não cria dados de exercício
/// nesta tela; a escolha será fornecida pela integração com a biblioteca.
class ExercicioTreinoLivreAdmin {
  const ExercicioTreinoLivreAdmin({
    required this.id,
    required this.nome,
    required this.series,
    required this.repeticoes,
    required this.carga,
  });

  final String id;
  final String nome;
  final int series;
  final int repeticoes;
  final String carga;

  String get resumo => '$series × $repeticoes · $carga';
}

/// Dados de apresentação prontos para o callback que será ligado ao backend.
class TreinoLivreAdminDraft {
  const TreinoLivreAdminDraft({
    required this.nome,
    required this.tipo,
    required this.exercicios,
  });

  final String nome;
  final TipoTreinoLivreAdmin tipo;
  final List<ExercicioTreinoLivreAdmin> exercicios;
}

class MontarTreinoLivreAdminScreen extends StatefulWidget {
  const MontarTreinoLivreAdminScreen({
    super.key,
    this.exerciciosIniciais = const [],
    this.onAdicionarExercicio,
    this.onSalvarTreino,
  });

  final List<ExercicioTreinoLivreAdmin> exerciciosIniciais;
  final Future<ExercicioTreinoLivreAdmin?> Function()? onAdicionarExercicio;
  final Future<void> Function(TreinoLivreAdminDraft treino)? onSalvarTreino;

  @override
  State<MontarTreinoLivreAdminScreen> createState() =>
      _MontarTreinoLivreAdminScreenState();
}

class _MontarTreinoLivreAdminScreenState
    extends State<MontarTreinoLivreAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  late final List<ExercicioTreinoLivreAdmin> _exercicios =
      List.of(widget.exerciciosIniciais);

  TipoTreinoLivreAdmin _tipo = TipoTreinoLivreAdmin.resistencia;
  bool _adicionandoExercicio = false;
  bool _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MontarTreinoLivreAdminScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciciosIniciais != widget.exerciciosIniciais) {
      _exercicios
        ..clear()
        ..addAll(widget.exerciciosIniciais);
    }
  }

  void _reordenar(int indiceAntigo, int indiceNovo) {
    setState(() {
      if (indiceNovo > indiceAntigo) indiceNovo -= 1;
      final exercicio = _exercicios.removeAt(indiceAntigo);
      _exercicios.insert(indiceNovo, exercicio);
    });
  }

  Future<void> _adicionarExercicio() async {
    final selecionar = widget.onAdicionarExercicio;
    if (selecionar == null) {
      _mostrarMensagem('Seleção de exercícios aguardando integração.');
      return;
    }

    setState(() => _adicionandoExercicio = true);
    try {
      final exercicio = await selecionar();
      if (!mounted || exercicio == null) return;
      setState(() => _exercicios.add(exercicio));
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem(
        'Não foi possível adicionar o exercício. Tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _adicionandoExercicio = false);
    }
  }

  Future<void> _salvarTreino() async {
    if (!_formKey.currentState!.validate() || _salvando) return;

    final salvar = widget.onSalvarTreino;
    if (salvar == null) {
      _mostrarMensagem('Cadastro aguardando integração.');
      return;
    }

    final treino = TreinoLivreAdminDraft(
      nome: _nomeController.text.trim(),
      tipo: _tipo,
      exercicios: List.unmodifiable(_exercicios),
    );

    setState(() => _salvando = true);
    try {
      await salvar(treino);
      if (!mounted) return;
      _mostrarMensagem('Treino livre salvo.');
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível salvar o treino. Tente novamente.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return FundoTela(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: appBarInterna(context, 'Montar treino livre'),
            body: SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    CampoTexto(
                      label: 'Nome do treino',
                      controller: _nomeController,
                      helper: 'Disponível para todos os alunos',
                      textCapitalization: TextCapitalization.sentences,
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return 'Informe o nome do treino.';
                        }
                        if (valor.trim().length > 120) {
                          return 'Use até 120 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Tipo do treino',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tipo in TipoTreinoLivreAdmin.values)
                          _ChipTipoTreino(
                            tipo: tipo,
                            selecionado: tipo == _tipo,
                            onTap: () => setState(() => _tipo = tipo),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Exercícios',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_exercicios.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: TextoApoio('Nenhum exercício adicionado.'),
                      )
                    else
                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        onReorder: _reordenar,
                        children: [
                          for (var indice = 0;
                              indice < _exercicios.length;
                              indice++)
                            _LinhaExercicioAdmin(
                              key: ValueKey(_exercicios[indice].id),
                              indice: indice,
                              exercicio: _exercicios[indice],
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
                        onPressed:
                            _adicionandoExercicio ? null : _adicionarExercicio,
                        child: _adicionandoExercicio
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Adicionar exercício',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: BarraAcaoInferior(
              texto: _salvando ? 'Salvando...' : 'Salvar treino livre',
              onPressed: _salvando ? null : _salvarTreino,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipTipoTreino extends StatelessWidget {
  const _ChipTipoTreino({
    required this.tipo,
    required this.selecionado,
    required this.onTap,
  });

  final TipoTreinoLivreAdmin tipo;
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
            tipo.rotulo,
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

class _LinhaExercicioAdmin extends StatelessWidget {
  const _LinhaExercicioAdmin({
    super.key,
    required this.indice,
    required this.exercicio,
  });

  final int indice;
  final ExercicioTreinoLivreAdmin exercicio;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 2),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: indice,
              child: const Icon(Icons.drag_handle, color: Color(0xFF7C8987)),
            ),
            const SizedBox(width: 10),
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
      ),
    );
  }
}
