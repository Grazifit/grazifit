// app/lib/features/avaliacoes/screens/avaliacao_fisica_screen.dart
//
// Dados do aluno vêm de `alunoDetalheProvider`; salvar depende do backend de
// avaliações. Integração: ver docs/integracao-frontend.md
//
// Avaliação física do aluno, edição do dia (professor): peso, altura, IMC
// calculado automaticamente e observação. Aberta pelo item "Avaliação física"
// do Detalhe do aluno. Não é a mesma tela que "Registrar medida do aluno"
// (essa é a do próprio aluno, com altura travada).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/botao_primario.dart';
import '../../../core/design_system/components/campo_texto.dart';
import '../../../core/design_system/tokens/cores_provisorias.dart';
import '../../../core/state/estado_async.dart';
import '../../vinculos/state/vinculos_providers.dart';

class AvaliacaoFisicaScreen extends ConsumerStatefulWidget {
  const AvaliacaoFisicaScreen({super.key, required this.idAluno});

  final int idAluno;

  @override
  ConsumerState<AvaliacaoFisicaScreen> createState() =>
      _AvaliacaoFisicaScreenState();
}

class _AvaliacaoFisicaScreenState extends ConsumerState<AvaliacaoFisicaScreen> {
  static const double _pesoMax = 500;

  final _formKey = GlobalKey<FormState>();
  final _pesoController = TextEditingController();
  final _alturaController = TextEditingController();
  final _imcController = TextEditingController();
  final _observacaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pesoController.addListener(_recalcularImc);
    _alturaController.addListener(_recalcularImc);
    _recalcularImc();
    _preencherDaUltimaAvaliacao();
  }

  /// Pré-preenche peso e altura com a última avaliação do aluno.
  Future<void> _preencherDaUltimaAvaliacao() async {
    try {
      final aluno =
          await ref.read(alunoDetalheProvider(widget.idAluno).future);
      if (!mounted) return;
      String fmt(double? v, int casas) =>
          v == null ? '' : v.toStringAsFixed(casas).replaceAll('.', ',');
      if (_pesoController.text.isEmpty) {
        _pesoController.text = fmt(aluno.ultimoPeso, 1);
      }
      if (_alturaController.text.isEmpty) {
        _alturaController.text = fmt(aluno.ultimaAltura, 2);
      }
    } catch (_) {
      // Sem dado: os campos ficam em branco e o erro aparece na própria
      // tela (cabeçalho), pelo mesmo provider.
    }
  }

  String get _hoje {
    final d = DateTime.now();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(TextosEstado.pendente)),
    );
  }

  // TODO(specs): CampoTexto ainda não tem modo somente leitura. Mesma solução
  // provisória da tela Editar perfil do professor.
  Widget _bloqueado(Widget campo) => Opacity(
        opacity: 0.6,
        child: IgnorePointer(child: ExcludeFocus(child: campo)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: appBarInterna(context, 'Avaliação física'),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                Text(
                  ref.watch(alunoDetalheProvider(widget.idAluno)).valueOrNull?.nome ??
                      '—',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Editando o registro de hoje, $_hoje',
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
      );
  }
}