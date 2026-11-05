import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

/// Tela para registrar uma nova medida do aluno.
///
/// O peso é digitado; a altura vem da última avaliação (somente leitura) e o
/// IMC é calculado automaticamente. Ao salvar, devolve o peso (double) para a
/// tela anterior via `Navigator.pop`.
class TelaRegistrarMedidaAluno extends StatefulWidget {
  /// Altura da última avaliação, em metros.
  final double alturaM;

  const TelaRegistrarMedidaAluno({super.key, required this.alturaM});

  @override
  State<TelaRegistrarMedidaAluno> createState() =>
      _TelaRegistrarMedidaAlunoState();
}

class _TelaRegistrarMedidaAlunoState extends State<TelaRegistrarMedidaAluno> {
  static const Color kGreen = AppColors.verde;
  static const Color kBackground = AppColors.fundo;
  static const Color kCampoSomenteLeitura = Color(0xFFF7F7F7);

  static const double _pesoMax = 500;

  final _pesoController = TextEditingController();
  String? _erroPeso;

  @override
  void dispose() {
    _pesoController.dispose();
    super.dispose();
  }

  /// Peso digitado, ou nulo se vazio ou fora do intervalo (0, 500].
  double? get _pesoValido {
    final v = double.tryParse(_pesoController.text.trim().replaceAll(',', '.'));
    if (v == null || v <= 0 || v > _pesoMax) return null;
    return v;
  }

  String _fmt(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

  String get _alturaTexto =>
      widget.alturaM.toStringAsFixed(2).replaceAll('.', ',');

  String get _imcTexto {
    final peso = _pesoValido;
    if (peso == null) return '--';
    return _fmt(peso / (widget.alturaM * widget.alturaM));
  }

  void _salvar() {
    final peso = _pesoValido;
    if (peso == null) {
      setState(() => _erroPeso = 'Informe um peso entre 0 e 500 kg.');
      return;
    }
    // TODO: enviar a nova medida para o backend antes de fechar a tela.
    Navigator.of(context).pop(peso);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black87,
        titleSpacing: 0,
        title: const Text(
          'Registrar medida',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCampo(
                    rotulo: 'Peso (kg)',
                    ajuda: 'Entre 0 e 500',
                    campo: TextField(
                      controller: _pesoController,
                      autofocus: true,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      onChanged: (_) => setState(() => _erroPeso = null),
                      onSubmitted: (_) => _salvar(),
                      decoration: _decoracao(
                        fundo: Colors.white,
                        erro: _erroPeso,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildCampo(
                    rotulo: 'Altura (m)',
                    ajuda: 'Preenchida da última avaliação',
                    campo: InputDecorator(
                      decoration: _decoracao(fundo: kCampoSomenteLeitura),
                      child: Text(
                        _alturaTexto,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildCampo(
                    rotulo: 'IMC',
                    ajuda: 'Calculado automaticamente',
                    campo: InputDecorator(
                      decoration: _decoracao(fundo: kCampoSomenteLeitura),
                      child: Text(
                        _imcTexto,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Salvar medida',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampo({
    required String rotulo,
    required String ajuda,
    required Widget campo,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        campo,
        const SizedBox(height: 6),
        Text(
          ajuda,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }

  InputDecoration _decoracao({required Color fundo, String? erro}) {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: cor),
        );
    return InputDecoration(
      filled: true,
      fillColor: fundo,
      isDense: true,
      errorText: erro,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: borda(Colors.transparent),
      focusedBorder: borda(kGreen),
      errorBorder: borda(const Color(0xFFB3261E)),
      focusedErrorBorder: borda(const Color(0xFFB3261E)),
    );
  }
}