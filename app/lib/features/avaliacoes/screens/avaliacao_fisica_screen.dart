import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/auth_controller.dart';
import '../data/avaliacao_repository.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/botao_primario.dart';
import '../../../core/design_system/components/campo_texto.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/design_system/tokens/cores_provisorias.dart';

class AvaliacaoFisicaScreen extends ConsumerStatefulWidget {
  const AvaliacaoFisicaScreen({
    super.key,
    this.nomeAluno = '',
    this.dataRegistro = '',
    this.peso = '',
    this.altura = '',
  });

  // Valores opcionais de apresentação; o aluno é identificado pela sessão.
  final String nomeAluno;
  final String dataRegistro;
  final String peso;
  final String altura;

  @override
  ConsumerState<AvaliacaoFisicaScreen> createState() =>
      _AvaliacaoFisicaScreenState();
}

class _AvaliacaoFisicaScreenState extends ConsumerState<AvaliacaoFisicaScreen> {
  bool _carregando = true;
  bool _salvando = false;

  final _formKey = GlobalKey<FormState>();
  late final _pesoController = TextEditingController(text: widget.peso);
  late final _alturaController = TextEditingController(text: widget.altura);
  final _imcController = TextEditingController();
  final _observacaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final sessao = ref.read(authControllerProvider).sessao;
      if (sessao == null || sessao.papel != 'aluno') return;
      final atual = await ref
          .read(avaliacaoRepositoryProvider)
          .atual(sessao.id);
      if (!mounted || atual == null) return;
      _pesoController.text = atual.peso.toString().replaceAll('.', ',');
      _alturaController.text = atual.altura.toString().replaceAll('.', ',');
      _observacaoController.text = atual.observacao ?? '';
      _imcController.text = atual.imc.toStringAsFixed(2).replaceAll('.', ',');
    } catch (erro) {
      if (mounted) _mensagem(mensagemAvaliacao(erro));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mensagem(String texto) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(texto)));

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

  String? _validarMedida(String? texto, double limite) {
    final valor = _numero(texto);
    if (valor == null ||
        !valor.isFinite ||
        valor <= 0 ||
        valor >= limite ||
        (valor * 100 - (valor * 100).round()).abs() > 0.0000001) {
      return 'Informe um valor maior que zero e menor que $limite, com até duas casas decimais.';
    }
    return null;
  }

  Future<void> _atualizar() async {
    if (_salvando || !_formKey.currentState!.validate()) return;
    final sessao = ref.read(authControllerProvider).sessao;
    if (sessao == null || sessao.papel != 'aluno') {
      _mensagem('Entre como aluno para registrar sua avaliação.');
      return;
    }
    setState(() => _salvando = true);
    try {
      final medida = await ref
          .read(avaliacaoRepositoryProvider)
          .salvar(
            sessao.id,
            peso: _numero(_pesoController.text)!,
            altura: _numero(_alturaController.text)!,
            observacao: _observacaoController.text,
          );
      if (!mounted) return;
      _imcController.text = medida.imc.toStringAsFixed(2).replaceAll('.', ',');
      ref.invalidate(historicoAvaliacoesProvider);
      _mensagem('Avaliação registrada.');
      Navigator.of(context).pop(true);
    } catch (erro) {
      if (mounted) _mensagem(mensagemAvaliacao(erro));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
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
                  ref.watch(authControllerProvider).sessao?.nome ??
                      widget.nomeAluno,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Registro de hoje',
                  style: const TextStyle(fontSize: 12, color: corAlerta),
                ),
                const SizedBox(height: 20),
                CampoTexto(
                  label: 'Peso (kg)',
                  controller: _pesoController,
                  helper: 'Entre 0 e 500',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  validator: (v) => _validarMedida(v, 500),
                ),
                const SizedBox(height: 20),
                CampoTexto(
                  label: 'Altura (m)',
                  validator: (v) => _validarMedida(v, 3),
                  controller: _alturaController,
                  helper: 'Preenchida da última avaliação',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                ),
                const SizedBox(height: 20),
                _bloqueado(
                  CampoTexto(
                    label: 'IMC',
                    controller: _imcController,
                    helper: 'Calculado pelo banco ao salvar a avaliação',
                  ),
                ),
                const SizedBox(height: 20),
                CampoTexto(
                  label: 'Observação',
                  validator: (v) => (v?.length ?? 0) > 2000
                      ? 'Use até 2000 caracteres.'
                      : null,
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
          onPressed: _carregando || _salvando ? null : _atualizar,
        ),
      ),
    );
  }
}
