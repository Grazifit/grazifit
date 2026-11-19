import 'package:flutter/material.dart';

import '../data/agenda_repository.dart';
import '../data/agendamento.dart';
import '../../treinos/screens/tela_treino_aluno.dart';
import '../../pessoas/screens/tela_perfil_aluno.dart';
import '../../avaliacoes/screens/tela_evolucao_aluno.dart';
import '../../../core/data/repositorios.dart';
import '../../../core/theme/app_colors.dart';

// Cores da tela (ajuste para o tema do app, se já tiver um).
const _verde = AppColors.verde;
const _verdeClaro = AppColors.verdeClaro;
const _vermelho = AppColors.vermelho;
const _fundo = AppColors.fundo;

/// Tela "Meus agendamentos" do aluno, com opção de cancelar.
///
/// Os dados vêm de um [AgendaRepository]. Se nenhum for informado, usa o
/// definido em `core/data/repositorios.dart`.
class TelaMeusAgendamentosAluno extends StatefulWidget {
  final AgendaRepository? repository;

  const TelaMeusAgendamentosAluno({super.key, this.repository});

  @override
  State<TelaMeusAgendamentosAluno> createState() => _TelaMeusAgendamentosAlunoState();
}

class _TelaMeusAgendamentosAlunoState extends State<TelaMeusAgendamentosAluno> {
  int _abaSelecionada = 1; // 0 = Agenda, 1 = Meus agendamentos
  int _navIndex = 0;

  late final AgendaRepository _repo;
  late Future<List<Agendamento>> _future;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? Repositorios.agenda;
    _future = _repo.buscarMeusAgendamentos();
  }

  void _recarregar() {
    setState(() {
      _future = _repo.buscarMeusAgendamentos();
    });
  }

  void _selecionarNav(int i) {
    if (i == 0) {
      // Agenda: volta para a tela anterior.
      Navigator.of(context).pop();
    } else if (i == 1) {
      // Treinos: troca esta tela pela de treinos, para que o "voltar"
      // da barra leve de volta à Agenda.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TelaTreinosAluno()),
      );
    } else if (i == 2) {
      // Evolução: troca esta tela pela de evolução.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TelaEvolucaoAluno()),
      );
    } else if (i == 3) {
      // Perfil: troca esta tela pela de perfil.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TelaPerfilAluno()),
      );
    } else {
      setState(() => _navIndex = i);
    }
  }

  Future<void> _cancelar(Agendamento item) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar agendamento?'),
        content: Text(
          'Você vai cancelar a aula das ${item.horario} com ${item.professor}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: _vermelho),
            child: const Text('Cancelar aula'),
          ),
        ],
      ),
    );

    if (confirmou != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.cancelarAgendamento(item.id);
      if (!mounted) return;
      _recarregar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Agendamento cancelado.')),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível cancelar. Tente novamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Agenda',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _AbaChip(
                    label: 'Agenda',
                    selecionada: _abaSelecionada == 0,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  _AbaChip(
                    label: 'Meus agendamentos',
                    selecionada: _abaSelecionada == 1,
                    onTap: () => setState(() => _abaSelecionada = 1),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _abaSelecionada == 1
                    ? _listaMeusAgendamentos()
                    : const Center(child: Text('Aulas disponíveis')),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BarraInferior(
        indexAtual: _navIndex,
        onTap: _selecionarNav,
      ),
    );
  }

  Widget _listaMeusAgendamentos() {
    return FutureBuilder<List<Agendamento>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: _verde));
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _buildErro();
        }
        final agendamentos = snapshot.data!;
        if (agendamentos.isEmpty) {
          return const Center(child: Text('Você não tem agendamentos.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: agendamentos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final item = agendamentos[i];
            return _CardAgendamento(
              agendamento: item,
              destaque: i == 0,
              onCancelar: () => _cancelar(item),
            );
          },
        );
      },
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
              'Não foi possível carregar seus agendamentos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _recarregar,
              style: OutlinedButton.styleFrom(
                foregroundColor: _verde,
                side: const BorderSide(color: _verde),
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AbaChip extends StatelessWidget {
  final String label;
  final bool selecionada;
  final VoidCallback onTap;

  const _AbaChip({
    required this.label,
    required this.selecionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionada ? _verde : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selecionada ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardAgendamento extends StatelessWidget {
  final Agendamento agendamento;
  final bool destaque;
  final VoidCallback onCancelar;

  const _CardAgendamento({
    required this.agendamento,
    required this.onCancelar,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: destaque ? Border.all(color: _verde, width: 1.5) : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
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
                agendamento.horario,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _verde,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Agendado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.sports_gymnastics, size: 18, color: _verde),
              const SizedBox(width: 6),
              Text(
                agendamento.modalidade,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _verdeClaro,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  agendamento.tipo,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            agendamento.professor,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 10),
          Text(
            '${agendamento.vagasOcupadas} de ${agendamento.vagasTotais} vagas',
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          if (agendamento.aviso != null) ...[
            const SizedBox(height: 6),
            Text(
              agendamento.aviso!,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCancelar,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Cancelar agendamento'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _vermelho,
                side: const BorderSide(color: _vermelho),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraInferior extends StatelessWidget {
  final int indexAtual;
  final ValueChanged<int> onTap;

  const _BarraInferior({required this.indexAtual, required this.onTap});

  static const _itens = [
    (Icons.calendar_today, 'Agenda'),
    (Icons.fitness_center, 'Treinos'),
    (Icons.trending_up, 'Evolução'),
    (Icons.person, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _verde,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_itens.length, (i) {
              final selecionado = i == indexAtual;
              final cor = selecionado ? Colors.white : Colors.white60;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_itens[i].$1, color: cor),
                      const SizedBox(height: 4),
                      Text(
                        _itens[i].$2,
                        style: TextStyle(
                          color: cor,
                          fontSize: 11,
                          fontWeight: selecionado
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}