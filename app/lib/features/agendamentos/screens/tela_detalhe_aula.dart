import 'package:flutter/material.dart';

/// Tela de detalhe da aula: resumo da aula, ocupação das vagas
/// e botão para confirmar o agendamento.
class TelaDetalheAula extends StatelessWidget {
  static const Color kGreen = Color(0xFF1B5E3C);
  static const Color kBackground = Color(0xFFF3F4F6);

  final String horarioInicio;
  final String horarioFim;
  final String modalidade;
  final String professor;
  final int vagasOcupadas;
  final int vagasTotais;

  const TelaDetalheAula({
    super.key,
    required this.horarioInicio,
    required this.horarioFim,
    required this.modalidade,
    required this.professor,
    required this.vagasOcupadas,
    required this.vagasTotais,
  });

  bool get _lotada => vagasOcupadas >= vagasTotais;

  void _confirmar(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(true);
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: kGreen,
        content: Text('Aula de $modalidade às $horarioInicio confirmada!'),
      ),
    );
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
                      '$vagasOcupadas ocupadas de $vagasTotais',
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
            _buildRodape(context),
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
            '$horarioInicio – $horarioFim',
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
                modalidade,
                style: const TextStyle(fontSize: 13.5, color: Colors.black87),
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
          const SizedBox(height: 10),
          Text(
            professor,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            '$vagasOcupadas de $vagasTotais vagas',
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
      children: List.generate(vagasTotais, (index) {
        final ocupada = index < vagasOcupadas;
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

  Widget _buildRodape(BuildContext context) {
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
              onPressed: _lotada ? null : () => _confirmar(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.black12,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _lotada ? 'Aula lotada' : 'Confirmar aula',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cancelamento permitido até 2 horas antes da aula',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}