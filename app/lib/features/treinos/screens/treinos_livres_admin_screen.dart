import 'package:flutter/material.dart';

import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/design_system/tokens/cores_provisorias.dart';
import '../state/treinos_livres_admin_state.dart';

/// Lista de treinos livres disponíveis aos alunos, na área do Admin.
/// Os dados e a navegação são fornecidos pela composição/integracão futura.
class TreinosLivresAdminScreen extends StatelessWidget {
  const TreinosLivresAdminScreen({
    super.key,
    this.estado = EstadoTreinosLivresAdmin.vazio,
    this.treinos = const [],
    this.onAbrirTreino,
    this.onAbrirExercicios,
    this.onTentarNovamente,
    this.onNavegar,
  });

  final EstadoTreinosLivresAdmin estado;
  final List<TreinoLivreAdminItem> treinos;
  final ValueChanged<TreinoLivreAdminItem>? onAbrirTreino;
  final VoidCallback? onAbrirExercicios;
  final VoidCallback? onTentarNovamente;
  final ValueChanged<int>? onNavegar;

  @override
  Widget build(BuildContext context) {
    return FundoTela(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
                            _AbaTreinos(
                              rotulo: 'Treinos livres',
                              selecionada: true,
                              onTap: null,
                            ),
                            const SizedBox(width: 8),
                            _AbaTreinos(
                              rotulo: 'Exercícios',
                              selecionada: false,
                              onTap: () => _abrirExercicios(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Disponíveis para todos os alunos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF78827F),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _conteudo(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: _NavegacaoAdmin(
              onSelecionar: (indice) => _navegar(context, indice),
            ),
          ),
        ),
      ),
    );
  }

  Widget _conteudo(BuildContext context) {
    switch (estado) {
      case EstadoTreinosLivresAdmin.carregando:
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator(color: corInstitucional)),
        );
      case EstadoTreinosLivresAdmin.erro:
      case EstadoTreinosLivresAdmin.semConexao:
        final offline = estado == EstadoTreinosLivresAdmin.semConexao;
        return _EstadoTreinos(
          icone: offline ? Icons.cloud_off_outlined : Icons.error_outline,
          mensagem: offline
              ? 'Sem conexão. Confira sua internet e tente novamente.'
              : 'Não foi possível carregar os treinos livres.',
          onTentarNovamente: onTentarNovamente,
        );
      case EstadoTreinosLivresAdmin.vazio:
      case EstadoTreinosLivresAdmin.dados:
        if (treinos.isEmpty) return const _ListaVazia();
        return _ListaTreinos(treinos: treinos, onSelecionar: onAbrirTreino);
    }
  }

  void _abrirExercicios(BuildContext context) {
    final callback = onAbrirExercicios;
    if (callback != null) {
      callback();
      return;
    }
    _avisar(context, 'Biblioteca de exercícios aguardando integração.');
  }

  void _navegar(BuildContext context, int indice) {
    if (indice == 3) return;
    final callback = onNavegar;
    if (callback != null) {
      callback(indice);
      return;
    }
    const destinos = ['Início', 'Pessoas', 'Aulas'];
    _avisar(context, 'A área ${destinos[indice]} aguarda integração.');
  }

  void _avisar(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }
}

class _AbaTreinos extends StatelessWidget {
  const _AbaTreinos({
    required this.rotulo,
    required this.selecionada,
    required this.onTap,
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

class _ListaTreinos extends StatelessWidget {
  const _ListaTreinos({required this.treinos, required this.onSelecionar});

  final List<TreinoLivreAdminItem> treinos;
  final ValueChanged<TreinoLivreAdminItem>? onSelecionar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Column(
        children: [
          for (var indice = 0; indice < treinos.length; indice++) ...[
            if (indice > 0) const Divider(height: 1, color: corDivisor),
            InkWell(
              onTap: onSelecionar == null
                  ? null
                  : () => onSelecionar!(treinos[indice]),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        treinos[indice].nome,
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
                        treinos[indice].tipoExibicao,
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
        ],
      ),
    );
  }
}

class _ListaVazia extends StatelessWidget {
  const _ListaVazia();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: const Text(
        'Nenhum treino livre disponível no momento.',
        style: TextStyle(fontSize: 13, color: Color(0xFF78827F)),
      ),
    );
  }
}

class _EstadoTreinos extends StatelessWidget {
  const _EstadoTreinos({
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
                          color: indice == 3 ? Colors.white : Colors.transparent,
                        ),
                        const SizedBox(height: 7),
                        Icon(
                          _itens[indice].$1,
                          size: 22,
                          color: Colors.white,
                        ),
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
