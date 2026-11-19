import 'package:flutter/material.dart';

import '../data/agenda_repository.dart';
import '../data/aula.dart';

/// Tela de detalhe da aula: resumo da aula, ocupação das vagas
/// e botão para confirmar o agendamento.
///
/// Recebe a [Aula] já carregada e o [AgendaRepository] usado para confirmar
/// o agendamento (o mesmo da tela de agenda).
class TelaDetalheAula extends StatefulWidget {
  final Aula aula;
  final AgendaRepository repository;

  const TelaDetalheAula({
    super.key,
    required this.aula,
    required this.repository,
  });

  @override
  State<TelaDetalheAula> createState() => _TelaDetalheAulaState();
}

class _TelaDetalheAulaState extends State<TelaDetalheAula> {
  static const Color kGreen = Color(0xFF1B5E3C);
  static const Color kBackground = Color(0xFFF3F4F6);

  bool _confirmando = false;

  Aula get _aula => widget.aula;

  bool get _lotada => _aula.status == StatusAula.lotada;

  Future<void> _confirmar() async {
    setState(() => _confirmando = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await widget.repository.agendarAula(_aula.id);
      if (!mounted) return;
      navigator.pop(true);
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: kGreen,
          content: Text(
            'Aula de ${_aula.modalidade} às ${_aula.horarioInicio} confirmada!',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _confirmando = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível confirmar a aula. Tente novamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildCabecalho(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardResumo(),
                    const SizedBox(height: 20),
                    const Text(
                      'Vagas',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_aula.vagasOcupadas} ocupadas de ${_aula.vagasTotais}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildGradeVagas(),
                    const SizedBox(height: 12),
                    _buildLegenda(),
                  ],
                ),
              ),
            ),
            _buildRodape(),
          ],
        ),
      ),
    );
  }

  Widget _buildCabecalho(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.chevron_left, size: 30, color: kGreen),
            tooltip: 'Voltar',
          ),
          const Text(
            'Detalhe da aula',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardResumo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          Text(
            '${_aula.horarioInicio} – ${_aula.horarioFim}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.fitness_center, size: 15, color: Colors.black54),
              const SizedBox(width: 6),
              Text(
                _aula.modalidade,
                style: const TextStyle(fontSize: 13.5, color: Colors.black87),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEDED),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _aula.tipo,
                  style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _aula.professor,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            '${_aula.vagasOcupadas} de ${_aula.vagasTotais} vagas',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Grade com uma célula por vaga: ocupadas em cinza, livres em destaque.
  Widget _buildGradeVagas() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: List.generate(_aula.vagasTotais, (index) {
        final ocupada = index < _aula.vagasOcupadas;
        return Container(
          decoration: BoxDecoration(
            color: ocupada ? const Color(0xFFE5E7EB) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ocupada ? Colors.transparent : kGreen,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: ocupada
              ? const Icon(Icons.person, size: 22, color: Colors.black38)
              : Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kGreen,
                  ),
                ),
        );
      }),
    );
  }

  Widget _buildLegenda() {
    Widget item(Color fundo, Color borda, String texto) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: fundo,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borda, width: 1.5),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      );
    }

    return Row(
      children: [
        item(Colors.white, kGreen, 'Livre'),
        const SizedBox(width: 16),
        item(const Color(0xFFE5E7EB), Colors.transparent, 'Ocupada'),
      ],
    );
  }

  Widget _buildRodape() {
    final horas = _aula.antecedenciaCancelamentoHoras;
    return Container(
      color: kBackground,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_lotada || _confirmando) ? null : _confirmar,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.black12,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _confirmando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _lotada ? 'Aula lotada' : 'Confirmar aula',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cancelamento permitido até $horas ${horas == 1 ? 'hora' : 'horas'} antes da aula',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
