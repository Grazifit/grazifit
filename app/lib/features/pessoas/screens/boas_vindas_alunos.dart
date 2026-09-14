import 'package:flutter/material.dart';

/// Tela de boas-vindas / anamnese rápida do aluno.
/// Exibida antes de iniciar o fluxo de treino, para coletar
/// restrições médicas e observações de saúde.
class TelaBoasVindasAluno extends StatefulWidget {
  final String nomeAluno;
  final void Function(String restricaoMedica, String observacoesSaude)
      onContinuar;

  /// Chamado quando o aluno opta por "Preencher depois".
  /// Se não for informado, o botão pula direto chamando [onContinuar]
  /// com os campos vazios.
  final VoidCallback? onPular;

  const TelaBoasVindasAluno({
    super.key,
    required this.nomeAluno,
    required this.onContinuar,
    this.onPular,
  });

  @override
  State<TelaBoasVindasAluno> createState() => _TelaBoasVindasAlunoState();
}

class _TelaBoasVindasAlunoState extends State<TelaBoasVindasAluno> {
  final _restricaoController = TextEditingController();
  final _observacoesController = TextEditingController();

  static const Color corDestaque = Color(0xFFE8622C); // laranja do nome
  static const Color corBotao = Color(0xFF0F3D3E); // verde escuro do botão

  @override
  void dispose() {
    _restricaoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.3, -0.6),
            radius: 1.3,
            colors: [
              Color(0xFFFDFCFB), // centro, mais claro
              Color(0xFFEDEBE7), // borda, levemente mais escuro
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bem-vinda,',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                widget.nomeAluno,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: corDestaque,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Antes de começar, conte se há algo que seu professor '
                'precisa saber. Isso ajuda a montar um treino seguro '
                'para você.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              _campoTexto(
                label: 'Restrição médica',
                hint: 'Toque para escrever',
                helper: 'Lesões, cirurgias, limitações. Opcional.',
                controller: _restricaoController,
              ),
              const SizedBox(height: 20),
              _campoTexto(
                label: 'Observações de saúde',
                hint: 'Toque para escrever',
                helper: 'Medicamentos, condições, o que achar relevante. '
                    'Opcional.',
                controller: _observacoesController,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: corBotao,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    widget.onContinuar(
                      _restricaoController.text.trim(),
                      _observacoesController.text.trim(),
                    );
                  },
                  child: const Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    if (widget.onPular != null) {
                      widget.onPular!();
                    } else {
                      widget.onContinuar('', '');
                    }
                  },
                  child: const Text(
                    'Preencher depois',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black45,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _campoTexto({
    required String label,
    required String hint,
    required String helper,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 2,
          minLines: 1,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFDFDCD6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFDFDCD6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: corBotao, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          helper,
          style: const TextStyle(fontSize: 11.5, color: Colors.black38),
        ),
      ],
    );
  }
}