import 'package:flutter/material.dart';

import '../../treinos/screens/tela_treino_aluno.dart';
import '../../../core/theme/app_colors.dart';

// Cores da tela (ajuste para o tema do app, se já tiver um).
const _verde = AppColors.verde;
const _verdeClaro = AppColors.verdeClaro;
const _vermelho = AppColors.vermelho;
const _fundo = AppColors.fundo;

class Agendamento {
  final String id;
  final String horario;
  final String modalidade;
  final String tipo;
  final String professor;
  final int vagasOcupadas;
  final int vagasTotal;
  final String? aviso;

  const Agendamento({
    required this.id,
    required this.horario,
    required this.modalidade,
    required this.tipo,
    required this.professor,
    required this.vagasOcupadas,
    required this.vagasTotal,
    this.aviso,
  });
}

class TelaMeusAgendamentosAluno extends StatefulWidget {
  const TelaMeusAgendamentosAluno({super.key});

  @override
  State<TelaMeusAgendamentosAluno> createState() => _TelaMeusAgendamentosAlunoState();
}

class _TelaMeusAgendamentosAlunoState extends State<TelaMeusAgendamentosAluno> {
  int _abaSelecionada = 1; // 0 = Agenda, 1 = Meus agendamentos
  int _navIndex = 0;

  // Dados de exemplo. Troque pela chamada ao backend.
  final List<Agendamento> _agendamentos = [
    const Agendamento(
      id: '1',
      horario: '07:00 - 08:00',
      modalidade: 'Funcional',
      tipo: 'Em grupo',
      professor: 'Prof. Marina Alves',
      vagasOcupadas: 8,
      vagasTotal: 12,
    ),
    const Agendamento(
      id: '2',
      horario: '09:00 - 10:00',
      modalidade: 'Funcional',
      tipo: 'Em grupo',
      professor: 'Prof. Marina Alves',
      vagasOcupadas: 8,
      vagasTotal: 12,
      aviso: 'Agendamento encerra 2 horas antes da aula',
    ),
  ];

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

    // TODO: chamar o backend para cancelar o agendamento.
    setState(() => _agendamentos.removeWhere((a) => a.id == item.id));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Agendamento cancelado.')),
    );
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
    if (_agendamentos.isEmpty) {
      return const Center(child: Text('Você não tem agendamentos.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _agendamentos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final item = _agendamentos[i];
        return _CardAgendamento(
          agendamento: item,
          destaque: i == 0,
          onCancelar: () => _cancelar(item),
        );
      },
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
            '${agendamento.vagasOcupadas} de ${agendamento.vagasTotal} vagas',
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
    (Icons.calendar_month, 'Agenda'),
    (Icons.fitness_center, 'Treinos'),
    (Icons.bar_chart, 'Evolução'),
    (Icons.person_outline, 'Perfil'),
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