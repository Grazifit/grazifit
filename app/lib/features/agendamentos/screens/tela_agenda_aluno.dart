import 'package:flutter/material.dart';

import 'tela_detalhe_aula.dart';
import 'tela_meus_agendamentos_aluno.dart';
import '../data/agenda_repository.dart';
import '../data/agenda_repository_mock.dart';
import '../data/aula.dart';
import '../../treinos/screens/tela_treino_aluno.dart';
import '../../avaliacoes/screens/tela_evolucao_aluno.dart';
import '../../pessoas/screens/tela_perfil_aluno.dart';
import '../../../core/theme/app_colors.dart';

/// Tela de agenda do aluno: abas (Agenda / Meus agendamentos),
/// filtros por modalidade e lista de aulas disponíveis.
///
/// Os dados vêm de um [AgendaRepository]. Se nenhum for informado, usa o
/// definido em `_criarRepositorio`.
class TelaAgendaAluno extends StatefulWidget {
  final AgendaRepository? repository;

  const TelaAgendaAluno({super.key, this.repository});

  @override
  State<TelaAgendaAluno> createState() => _TelaAgendaAlunoState();
}

class _TelaAgendaAlunoState extends State<TelaAgendaAluno> {
  static const Color kGreen = AppColors.verde;
  static const Color kBackground = AppColors.fundo;

  int _abaSelecionada = 0; // 0 = Agenda, 1 = Meus agendamentos
  int _filtroSelecionado = 0; // índice da modalidade ativa
  int _navSelecionado = 0;

  late final AgendaRepository _repo;
  late Future<_DadosAgenda> _future;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? _criarRepositorio();
    _future = _carregar();
  }

  /// Ponto único para trocar a origem dos dados.
  /// TODO: substituir o mock pela implementação que chama o backend.
  AgendaRepository _criarRepositorio() => AgendaRepositoryMock();

  Future<_DadosAgenda> _carregar() async {
    final resultados = await Future.wait<Object>([
      _repo.buscarModalidades(),
      _repo.buscarAulas(),
    ]);
    return _DadosAgenda(
      resultados[0] as List<Modalidade>,
      resultados[1] as List<Aula>,
    );
  }

  void _recarregar() {
    setState(() {
      _filtroSelecionado = 0;
      _future = _carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _CabecalhoAgenda(),
            _buildAbas(),
            Expanded(
              child: FutureBuilder<_DadosAgenda>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(color: kGreen),
                    );
                  }
                  if (snapshot.hasError || snapshot.data == null) {
                    return _buildErro();
                  }
                  return _buildCorpo(snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavInferior(),
    );
  }

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.black45),
            const SizedBox(height: 12),
            const Text(
              'Não foi possível carregar a agenda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _recarregar,
              style: OutlinedButton.styleFrom(
                foregroundColor: kGreen,
                side: const BorderSide(color: kGreen),
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorpo(_DadosAgenda dados) {
    final modalidades = dados.modalidades;
    final indiceFiltro =
        _filtroSelecionado < modalidades.length ? _filtroSelecionado : 0;
    final filtro = modalidades.isEmpty ? null : modalidades[indiceFiltro];
    final aulas = filtro == null
        ? dados.aulas
        : dados.aulas.where((a) => a.modalidade == filtro.nome).toList();

    return Column(
      children: [
        if (modalidades.isNotEmpty) _buildFiltros(modalidades, indiceFiltro),
        Expanded(
          child: aulas.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma aula disponível.',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: aulas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final aula = aulas[index];
                    return GestureDetector(
                      onTap: aula.status == StatusAula.lotada
                          ? null
                          : () => _abrirDetalhe(aula),
                      child: _buildCardAula(aula),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _abrirDetalhe(Aula aula) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TelaDetalheAula(
          horarioInicio: aula.horarioInicio,
          horarioFim: aula.horarioFim,
          modalidade: aula.modalidade,
          professor: aula.professor,
          vagasOcupadas: aula.vagasOcupadas,
          vagasTotais: aula.vagasTotais,
        ),
      ),
    );
  }

  void _selecionarAba(int index) {
    if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TelaMeusAgendamentosAluno()),
      );
      return;
    }
    setState(() => _abaSelecionada = index);
  }

  void _selecionarNav(int index) {
    if (index == 1) {
      // Treinos: abre a tela por cima; a Agenda continua marcada ao voltar.
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TelaTreinosAluno()),
      );
      return;
    }
    if (index == 2) {
      // Evolução: abre a tela por cima; a Agenda continua marcada ao voltar.
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TelaEvolucaoAluno()),
      );
      return;
    }
    if (index == 3) {
      // Perfil: abre a tela por cima; a Agenda continua marcada ao voltar.
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TelaPerfilAluno()),
      );
      return;
    }
    setState(() => _navSelecionado = index);
  }

  /// Ícone de cada modalidade. É só apresentação: modalidades novas, que não
  /// estejam aqui, usam o ícone padrão.
  IconData _iconeDaModalidade(String nome) {
    switch (nome) {
      case 'Musculação':
        return Icons.sports_gymnastics;
      case 'Pilates':
        return Icons.self_improvement;
      case 'Funcional':
      default:
        return Icons.fitness_center;
    }
  }

  Widget _buildAbas() {
    return Container(
      color: kBackground,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(child: _buildAba('Agenda', 0)),
          const SizedBox(width: 10),
          Expanded(child: _buildAba('Meus agendamentos', 1)),
        ],
      ),
    );
  }

  Widget _buildAba(String texto, int index) {
    final selecionada = _abaSelecionada == index;
    return GestureDetector(
      onTap: () => _selecionarAba(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selecionada ? kGreen : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selecionada ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildFiltros(List<Modalidade> modalidades, int indiceAtivo) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        itemCount: modalidades.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final modalidade = modalidades[index];
          final selecionada = indiceAtivo == index;
          return GestureDetector(
            onTap: () => setState(() => _filtroSelecionado = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selecionada ? kGreen : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconeDaModalidade(modalidade.nome),
                    size: 16,
                    color: selecionada ? Colors.white : Colors.black54,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    modalidade.nome,
                    style: TextStyle(
                      color: selecionada ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardAula(Aula aula) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${aula.horarioInicio} – ${aula.horarioFim}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              _buildBadgeStatus(aula.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _iconeDaModalidade(aula.modalidade),
                size: 14,
                color: Colors.black54,
              ),
              const SizedBox(width: 6),
              Text(
                aula.modalidade,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEDED),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  aula.tipo,
                  style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            aula.professor,
            style: const TextStyle(fontSize: 13.5, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            '${aula.vagasOcupadas} de ${aula.vagasTotais} vagas',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: aula.status == StatusAula.ultimasVagas
                  ? const Color(0xFFB07300)
                  : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeStatus(StatusAula status) {
    switch (status) {
      case StatusAula.ultimasVagas:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF2C572),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Últimas vagas',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B4300),
            ),
          ),
        );
      case StatusAula.lotada:
        return const Text(
          'Lotada',
          style: TextStyle(fontSize: 12.5, color: Colors.black45),
        );
      case StatusAula.normal:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavInferior() {
    final itens = [
      (Icons.calendar_today, 'Agenda'),
      (Icons.fitness_center, 'Treinos'),
      (Icons.trending_up, 'Evolução'),
      (Icons.person, 'Perfil'),
    ];
    return Container(
      color: kGreen,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(itens.length, (index) {
            final selecionado = _navSelecionado == index;
            final item = itens[index];
            return GestureDetector(
              onTap: () => _selecionarNav(index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.$1,
                    size: 22,
                    color: selecionado ? Colors.white : Colors.white54,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.$2,
                    style: TextStyle(
                      fontSize: 11,
                      color: selecionado ? Colors.white : Colors.white54,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Resultado do carregamento: modalidades dos filtros e aulas da lista.
class _DadosAgenda {
  final List<Modalidade> modalidades;
  final List<Aula> aulas;
  const _DadosAgenda(this.modalidades, this.aulas);
}

/// Cabeçalho da tela: título "Agenda" à esquerda e o logo
/// colorido (pinwheel de 4 pétalas) centralizado.
class _CabecalhoAgenda extends StatelessWidget {
  const _CabecalhoAgenda();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.fundo,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Agenda',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Image.asset(
            'lib/features/agendamentos/widgets/logo.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}