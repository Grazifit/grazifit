// app/lib/features/avaliacoes/screens/avaliacao_fisica_screen.dart
//
// PROTÓTIPO VISUAL — sem integração com backend. Dados fictícios do mockup.
// Integração com o backend: ver docs/handoff-front-professor.md
//
// Avaliação física do aluno, edição do dia (professor): peso, altura, IMC
// calculado automaticamente e observação. Aberta pelo item "Avaliação física"
// do Detalhe do aluno. Não é a mesma tela que "Registrar medida do aluno"
// (essa é a do próprio aluno, com altura travada).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/botao_primario.dart';
import '../../../core/design_system/components/campo_texto.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/design_system/tokens/cores_provisorias.dart';

class AvaliacaoFisicaScreen extends StatefulWidget {
  const AvaliacaoFisicaScreen({
    super.key,
    this.nomeAluno = 'Ana Beatriz Ramos',
    this.dataRegistro = '01/09',
    this.peso = '72,5',
    this.altura = '1,68',
  });

  // Valores padrão = dados fictícios do mockup.
  final String nomeAluno;
  final String dataRegistro;
  final String peso;
  final String altura;

  @override
  State<AvaliacaoFisicaScreen> createState() => _AvaliacaoFisicaScreenState();
}

class _AvaliacaoFisicaScreenState extends State<AvaliacaoFisicaScreen> {
  static const double _pesoMax = 500;

  final _formKey = GlobalKey<FormState>();
  late final _pesoController = TextEditingController(text: widget.peso);
  late final _alturaController = TextEditingController(text: widget.altura);
  final _imcController = TextEditingController();
  final _observacaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pesoController.addListener(_recalcularImc);
    _alturaController.addListener(_recalcularImc);
    _recalcularImc();
  }

  @override
  void dispose() {
    _pesoController.dispose();
    _alturaController.dispose();
    _imcController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  double? _numero(String? texto) =>
      double.tryParse((texto ?? '').trim().replaceAll(',', '.'));

  void _recalcularImc() {
    final peso = _numero(_pesoController.text);
    final altura = _numero(_alturaController.text);
    if (peso == null || altura == null || peso <= 0 || altura <= 0) {
      _imcController.text = '--';
      return;
    }
    final imc = peso / (altura * altura);
    _imcController.text = imc.toStringAsFixed(1).replaceAll('.', ',');
  }

  String? _validarPeso(String? valor) {
    final peso = _numero(valor);
    if (peso == null || peso <= 0 || peso > _pesoMax) {
      return 'Informe um peso entre 0 e 500 kg.';
    }
    return null;
  }

  // TODO(backend): "editando o registro de hoje" = atualizar a avaliação do
  // dia (há uma por aluno por data: uq_avaliacao_aluno_data, erro
  // AVALIACAO_JA_REGISTRADA, D6). Confirmar se é PATCH ou upsert.
  // O IMC é calculado no banco; aqui é só exibição. Falta validar a altura
  // (o mockup não define o intervalo).
  void _atualizar() {
    _formKey.currentState?.validate();
  }

  // TODO(specs): CampoTexto ainda não tem modo somente leitura. Mesma solução
  // provisória da tela Editar perfil do professor.
  Widget _bloqueado(Widget campo) => Opacity(
        opacity: 0.6,
        child: IgnorePointer(child: ExcludeFocus(child: campo)),
      );

  @override
  Widget build(BuildContext context) {
    return FundoTela(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBarInterna(context, 'Avaliação física'),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                Text(
                  widget.nomeAluno,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Editando o registro de hoje, ${widget.dataRegistro}',
                  style: const TextStyle(fontSize: 12, color: corAlerta),
                ),
                const SizedBox(height: 20),
                CampoTexto(
                  label: 'Peso (kg)',
                  controller: _pesoController,
                  helper: 'Entre 0 e 500',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  validator: _validarPeso,
                ),
                const SizedBox(height: 20),
                CampoTexto(
                  label: 'Altura (m)',
                  controller: _alturaController,
                  helper: 'Preenchida da última avaliação',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                ),
                const SizedBox(height: 20),
                _bloqueado(
                  CampoTexto(
                    label: 'IMC',
                    controller: _imcController,
                    helper: 'Calculado automaticamente a partir de peso e altura',
                  ),
                ),
                const SizedBox(height: 20),
                CampoTexto(
                  label: 'Observação',
                  controller: _observacaoController,
                  hint: 'Toque para escrever',
                  helper: 'Opcional',
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  minLines: 3,
                  maxLines: 5,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BarraAcaoInferior(
          texto: 'Atualizar avaliação',
          onPressed: _atualizar,
        ),
      ),
    );
  }
}