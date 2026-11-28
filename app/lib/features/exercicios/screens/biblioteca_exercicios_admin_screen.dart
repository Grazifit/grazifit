import 'package:flutter/material.dart';

import '../../../core/state/busca_com_debounce.dart';

import '../../../core/design_system/tokens/cores_provisorias.dart';
import '../state/biblioteca_exercicios_admin_state.dart';

/// Biblioteca de exercícios da área Admin. Busca e filtros operam somente
/// sobre os itens recebidos pela integração.
class BibliotecaExerciciosAdminScreen extends StatefulWidget {
  const BibliotecaExerciciosAdminScreen({
    super.key,
    this.estado = EstadoBibliotecaExerciciosAdmin.vazio,
    this.exercicios = const [],
    this.onAbrirTreinosLivres,
    this.onSelecionarExercicio,
    this.onTentarNovamente,
    this.onNavegar,
  });

  final EstadoBibliotecaExerciciosAdmin estado;
  final List<ExercicioBibliotecaAdminItem> exercicios;
  final VoidCallback? onAbrirTreinosLivres;
  final ValueChanged<ExercicioBibliotecaAdminItem>? onSelecionarExercicio;
  final VoidCallback? onTentarNovamente;
  final ValueChanged<int>? onNavegar;

  @override
  State<BibliotecaExerciciosAdminScreen> createState() =>
      _BibliotecaExerciciosAdminScreenState();
}

class _BibliotecaExerciciosAdminScreenState
    extends State<BibliotecaExerciciosAdminScreen> {
  final _buscaController = BuscaComDebounce();
  final _dificuldadesSelecionadas = <String>{};

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                        sliver: SliverMainAxisGroup(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Treinos',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF26312F),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      _AbaBiblioteca(
                                        rotulo: 'Treinos livres',
                                        selecionada: false,
                                        onTap: _abrirTreinosLivres,
                                      ),
                                      const SizedBox(width: 8),
                                      const _AbaBiblioteca(
                                        rotulo: 'Exercícios',
                                        selecionada: true,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _campoBusca(),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _FiltroDificuldade(
                                        rotulo: 'Iniciante',
                                        selecionado: _dificuldadesSelecionadas
                                            .contains('iniciante'),
                                        onTap: () =>
                                            _alternarDificuldade('iniciante'),
                                      ),
                                      _FiltroDificuldade(
                                        rotulo: 'Avançado',
                                        selecionado: _dificuldadesSelecionadas
                                            .contains('avancado'),
                                        onTap: () =>
                                            _alternarDificuldade('avancado'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                            ValueListenableBuilder<String>(
                              valueListenable: _buscaController.termo,
                              builder: (context, termo, child) =>
                                  _conteudo(termo),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _NavegacaoAdmin(onSelecionar: _navegar),
        ),
      ),
    );
  }

  Widget _campoBusca() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _buscaController,
      builder: (context, valor, child) => TextField(
        controller: _buscaController,
        decoration: InputDecoration(
          hintText: 'Buscar exercício',
          hintStyle: const TextStyle(color: Color(0xFF8A9492), fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: corInstitucional),
          suffixIcon: valor.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpar busca',
                  icon: const Icon(Icons.close),
                  onPressed: _buscaController.clear,
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: Color(0xFFBECBC8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: Color(0xFFBECBC8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: corInstitucional),
          ),
        ),
      ),
    );
  }

  Widget _conteudo(String consulta) {
    switch (widget.estado) {
      case EstadoBibliotecaExerciciosAdmin.carregando:
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(color: corInstitucional),
            ),
          ),
        );
      case EstadoBibliotecaExerciciosAdmin.erro:
      case EstadoBibliotecaExerciciosAdmin.semConexao:
        final semConexao =
            widget.estado == EstadoBibliotecaExerciciosAdmin.semConexao;
        return SliverToBoxAdapter(
          child: _EstadoBiblioteca(
            icone: semConexao ? Icons.cloud_off_outlined : Icons.error_outline,
            mensagem: semConexao
                ? 'Sem conexão. Confira sua internet e tente novamente.'
                : 'Não foi possível carregar os exercícios.',
            onTentarNovamente: widget.onTentarNovamente,
          ),
        );
      case EstadoBibliotecaExerciciosAdmin.vazio:
      case EstadoBibliotecaExerciciosAdmin.dados:
        final exercicios = _exerciciosFiltrados(consulta);
        if (exercicios.isEmpty) {
          final temBusca =
              consulta.isNotEmpty || _dificuldadesSelecionadas.isNotEmpty;
          return SliverToBoxAdapter(
            child: _ListaVazia(
              mensagem: temBusca
                  ? 'Nenhum exercício encontrado para os filtros selecionados.'
                  : 'Nenhum exercício disponível no momento.',
            ),
          );
        }
        return _ListaExercicios(
          exercicios: exercicios,
          onSelecionar: (exercicio) {
            final callback = widget.onSelecionarExercicio;
            if (callback != null) {
              callback(exercicio);
            } else {
              _avisar('Detalhes do exercício aguardando integração.');
            }
          },
        );
    }
  }

  List<ExercicioBibliotecaAdminItem> _exerciciosFiltrados(String consulta) {
    return widget.exercicios.where((exercicio) {
      final correspondeBusca =
          consulta.isEmpty || exercicio.nome.toLowerCase().contains(consulta);
      final correspondeDificuldade =
          _dificuldadesSelecionadas.isEmpty ||
          _dificuldadesSelecionadas.contains(exercicio.dificuldade);
      return correspondeBusca && correspondeDificuldade;
    }).toList();
  }

  void _alternarDificuldade(String dificuldade) {
    setState(() {
      if (!_dificuldadesSelecionadas.add(dificuldade)) {
        _dificuldadesSelecionadas.remove(dificuldade);
      }
    });
  }

  void _abrirTreinosLivres() {
    final callback = widget.onAbrirTreinosLivres;
    if (callback != null) {
      callback();
      return;
    }
    _avisar('Treinos livres aguardando integração.');
  }

  void _navegar(int indice) {
    if (indice == 3) return;
    final callback = widget.onNavegar;
    if (callback != null) {
      callback(indice);
      return;
    }
    const destinos = ['Início', 'Pessoas', 'Aulas'];
    _avisar('A área ${destinos[indice]} aguarda integração.');
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }
}

class _AbaBiblioteca extends StatelessWidget {
  const _AbaBiblioteca({
    required this.rotulo,
    required this.selecionada,
    this.onTap,
  });

  final String rotulo;
  final bool selecionada;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionada ? corInstitucional : corSuperficieSuave,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(
            rotulo,
            style: TextStyle(
              color: selecionada ? Colors.white : const Color(0xFF33413F),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _FiltroDificuldade extends StatelessWidget {
  const _FiltroDificuldade({
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
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(
            rotulo,
            style: TextStyle(
              color: selecionado ? Colors.white : const Color(0xFF33413F),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ListaExercicios extends StatelessWidget {
  const _ListaExercicios({
    required this.exercicios,
    required this.onSelecionar,
  });

  final List<ExercicioBibliotecaAdminItem> exercicios;
  final ValueChanged<ExercicioBibliotecaAdminItem>? onSelecionar;

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: exercicios.length,
      itemBuilder: (context, indice) => Material(
        color: Colors.white,
        child: Column(
          children: [
            if (indice > 0) const Divider(height: 1, color: corDivisor),
            InkWell(
              onTap: onSelecionar == null
                  ? null
                  : () => onSelecionar!(exercicios[indice]),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        exercicios[indice].nome,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF26312F),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: corSuperficieSuave,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        exercicios[indice].dificuldadeExibicao,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF46514F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaVazia extends StatelessWidget {
  const _ListaVazia({required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Text(
        mensagem,
        style: const TextStyle(fontSize: 13, color: Color(0xFF78827F)),
      ),
    );
  }
}

class _EstadoBiblioteca extends StatelessWidget {
  const _EstadoBiblioteca({
    required this.icone,
    required this.mensagem,
    this.onTentarNovamente,
  });

  final IconData icone;
  final String mensagem;
  final VoidCallback? onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icone, size: 32, color: corInstitucional),
          const SizedBox(height: 12),
          Text(mensagem, textAlign: TextAlign.center),
          if (onTentarNovamente != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onTentarNovamente,
              child: const Text('Tentar novamente'),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavegacaoAdmin extends StatelessWidget {
  const _NavegacaoAdmin({required this.onSelecionar});

  final ValueChanged<int> onSelecionar;

  static const _itens = [
    (Icons.home_outlined, 'Início'),
    (Icons.people_outline, 'Pessoas'),
    (Icons.directions_run, 'Aulas'),
    (Icons.fitness_center, 'Treinos'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: corInstitucional,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var indice = 0; indice < _itens.length; indice++)
                Expanded(
                  child: InkWell(
                    onTap: () => onSelecionar(indice),
                    child: Column(
                      children: [
                        Container(
                          width: 28,
                          height: 3,
                          color: indice == 3
                              ? Colors.white
                              : Colors.transparent,
                        ),
                        const SizedBox(height: 7),
                        Icon(_itens[indice].$1, size: 22, color: Colors.white),
                        const SizedBox(height: 3),
                        Text(
                          _itens[indice].$2,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
