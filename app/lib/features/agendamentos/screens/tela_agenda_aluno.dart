import 'package:flutter/material.dart';

import 'tela_detalhe_aula.dart';

/// Tela de agenda do aluno: abas (Agenda / Meus agendamentos),
/// filtros por modalidade e lista de aulas disponíveis.
class TelaAgendaAluno extends StatefulWidget {
  const TelaAgendaAluno({super.key});

  @override
  State<TelaAgendaAluno> createState() => _TelaAgendaAlunoState();
}

class _TelaAgendaAlunoState extends State<TelaAgendaAluno> {
  static const Color kGreen = Color(0xFF1B5E3C);
  static const Color kBackground = Color(0xFFF3F4F6);

  int _abaSelecionada = 0; // 0 = Agenda, 1 = Meus agendamentos
  int _filtroSelecionado = 0; // índice da modalidade ativa
  int _navSelecionado = 0;

  final List<_Modalidade> _modalidades = const [
    _Modalidade('Funcional', Icons.fitness_center),
    _Modalidade('Musculação', Icons.sports_gymnastics),
    _Modalidade('Pilates', Icons.self_improvement),
  ];

  final List<_Aula> _aulas = const [
    _Aula(
      horarioInicio: '07:00',
      horarioFim: '08:00',
      modalidade: 'Funcional',
      professor: 'Prof. Marina Alves',
      vagasOcupadas: 8,
      vagasTotais: 12,
      status: _StatusAula.normal,
    ),
    _Aula(
      horarioInicio: '09:00',
      horarioFim: '10:00',
      modalidade: 'Funcional',
      professor: 'Prof. Marina Alves',
      vagasOcupadas: 11,
      vagasTotais: 12,
      status: _StatusAula.ultimasVagas,
    ),
    _Aula(
      horarioInicio: '18:00',
      horarioFim: '19:00',
      modalidade: 'Funcional',
      professor: 'Prof. Marina Alves',
      vagasOcupadas: 12,
      vagasTotais: 12,
      status: _StatusAula.lotada,
    ),
  ];

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
            _buildFiltros(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: _aulas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final aula = _aulas[index];
                  return GestureDetector(
                    onTap: aula.status == _StatusAula.lotada
                        ? null
                        : () => _abrirDetalhe(aula),
                    child: _buildCardAula(aula),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavInferior(),
    );
  }

  void _abrirDetalhe(_Aula aula) {
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
      onTap: () => setState(() => _abaSelecionada = index),
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

  Widget _buildFiltros() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        itemCount: _modalidades.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final modalidade = _modalidades[index];
          final selecionada = _filtroSelecionado == index;
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
                    modalidade.icone,
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

  Widget _buildCardAula(_Aula aula) {
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
              const Icon(Icons.fitness_center, size: 14, color: Colors.black54),
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
                child: const Text(
                  'Em grupo',
                  style: TextStyle(fontSize: 11.5, color: Colors.black54),
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
              color: aula.status == _StatusAula.ultimasVagas
                  ? const Color(0xFFB07300)
                  : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeStatus(_StatusAula status) {
    switch (status) {
      case _StatusAula.ultimasVagas:
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
      case _StatusAula.lotada:
        return const Text(
          'Lotada',
          style: TextStyle(fontSize: 12.5, color: Colors.black45),
        );
      case _StatusAula.normal:
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
              onTap: () => setState(() => _navSelecionado = index),
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

/// Cabeçalho da tela: título "Agenda" à esquerda e o logo
/// colorido (pinwheel de 4 pétalas) centralizado.
class _CabecalhoAgenda extends StatelessWidget {
  const _CabecalhoAgenda();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF3F4F6),
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

class _Modalidade {
  final String nome;
  final IconData icone;
  const _Modalidade(this.nome, this.icone);
}

enum _StatusAula { normal, ultimasVagas, lotada }

class _Aula {
  final String horarioInicio;
  final String horarioFim;
  final String modalidade;
  final String professor;
  final int vagasOcupadas;
  final int vagasTotais;
  final _StatusAula status;

  const _Aula({
    required this.horarioInicio,
    required this.horarioFim,
    required this.modalidade,
    required this.professor,
    required this.vagasOcupadas,
    required this.vagasTotais,
    required this.status,
  });
}