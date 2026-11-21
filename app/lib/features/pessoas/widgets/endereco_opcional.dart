// app/lib/features/pessoas/widgets/endereco_opcional.dart
//
// Sub-form "Endereço (opcional)", compartilhado por professor e aluno (D18:
// endereço é sub-form opcional, não feature própria).
//
// Os campos e limites seguem a tabela `endereco` de
// database/schema/grazi_db_init_schema.sql (rua, numero, complemento, bairro,
// cidade, uf, cep, pais). O schema é a autoridade (D58).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/components/campo_texto.dart';
import '../../../core/design_system/tokens/cores_provisorias.dart';

/// Guarda o que foi digitado no sub-form e sabe validar e serializar.
///
/// Regra: endereço é opcional **inteiro**. Se nada foi preenchido, não há
/// endereço ([toJson] devolve `null`). Se qualquer campo foi preenchido, os
/// obrigatórios do schema (tudo menos `complemento` e `pais`) passam a ser
/// exigidos.
class EnderecoController {
  final cep = TextEditingController();
  final rua = TextEditingController();
  final numero = TextEditingController();
  final complemento = TextEditingController();
  final bairro = TextEditingController();
  final cidade = TextEditingController();
  final uf = TextEditingController();
  final pais = TextEditingController(text: 'Brasil');

  List<TextEditingController> get _obrigatorios =>
      [cep, rua, numero, bairro, cidade, uf];

  /// `true` quando o usuário digitou algo além do país padrão.
  bool get preenchido =>
      [..._obrigatorios, complemento].any((c) => c.text.trim().isNotEmpty);

  String get cepDigitos => cep.text.replaceAll(RegExp(r'\D'), '');

  /// Mensagem de campo obrigatório, só quando o endereço está em preenchimento.
  String? obrigatorio(String? valor) {
    if (!preenchido) return null;
    return (valor == null || valor.trim().isEmpty) ? 'Obrigatório' : null;
  }

  String? validarCep(String? valor) {
    if (!preenchido) return null;
    return cepDigitos.length == 8 ? null : 'CEP com 8 dígitos';
  }

  String? validarUf(String? valor) {
    if (!preenchido) return null;
    final v = (valor ?? '').trim();
    return RegExp(r'^[A-Za-z]{2}$').hasMatch(v) ? null : 'Use a sigla (ex.: PR)';
  }

  /// Corpo no formato das colunas de `endereco`. `null` = sem endereço.
  Map<String, dynamic>? toJson() {
    if (!preenchido) return null;
    final comp = complemento.text.trim();
    final p = pais.text.trim();
    return {
      'rua': rua.text.trim(),
      'numero': numero.text.trim(),
      if (comp.isNotEmpty) 'complemento': comp,
      'bairro': bairro.text.trim(),
      'cidade': cidade.text.trim(),
      'uf': uf.text.trim().toUpperCase(),
      'cep': cepDigitos,
      if (p.isNotEmpty) 'pais': p,
    };
  }

  void dispose() {
    for (final c in [..._obrigatorios, complemento, pais]) {
      c.dispose();
    }
  }
}

class EnderecoOpcional extends StatefulWidget {
  const EnderecoOpcional({super.key, this.controller, this.nota});

  /// Quem precisa ler os valores (a tela de cadastro) passa o seu. Sem ele,
  /// o sub-form cuida do próprio estado.
  final EnderecoController? controller;

  /// Nota de escopo exibida sob o título (texto real da tela, vindo do
  /// mockup — não é comentário de dev).
  final String? nota;

  @override
  State<EnderecoOpcional> createState() => _EnderecoOpcionalState();
}

class _EnderecoOpcionalState extends State<EnderecoOpcional> {
  late final EnderecoController _ctrl;
  late final bool _donoDoController;
  late bool _aberto;

  @override
  void initState() {
    super.initState();
    _donoDoController = widget.controller == null;
    _ctrl = widget.controller ?? EnderecoController();
    _aberto = _ctrl.preenchido;
  }

  @override
  void dispose() {
    if (_donoDoController) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _aberto = !_aberto),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Endereço (opcional)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              AnimatedRotation(
                turns: _aberto ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: corInstitucional,
                ),
              ),
            ],
          ),
        ),
        if (widget.nota != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              widget.nota!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        // Mantém os campos montados (Offstage) para que o Form os valide e
        // o texto digitado não se perca ao recolher o bloco.
        Offstage(
          offstage: !_aberto,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                CampoTexto(
                  label: 'CEP',
                  controller: _ctrl.cep,
                  hint: '00000-000',
                  keyboardType: TextInputType.number,
                  inputFormatters: [_CepInputFormatter()],
                  validator: _ctrl.validarCep,
                ),
                const SizedBox(height: 16),
                CampoTexto(
                  label: 'Rua',
                  controller: _ctrl.rua,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [LengthLimitingTextInputFormatter(150)],
                  validator: _ctrl.obrigatorio,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CampoTexto(
                        label: 'Número',
                        controller: _ctrl.numero,
                        inputFormatters: [LengthLimitingTextInputFormatter(10)],
                        validator: _ctrl.obrigatorio,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: CampoTexto(
                        label: 'Complemento',
                        controller: _ctrl.complemento,
                        helper: 'Opcional',
                        inputFormatters: [LengthLimitingTextInputFormatter(60)],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CampoTexto(
                  label: 'Bairro',
                  controller: _ctrl.bairro,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [LengthLimitingTextInputFormatter(100)],
                  validator: _ctrl.obrigatorio,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: CampoTexto(
                        label: 'Cidade',
                        controller: _ctrl.cidade,
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [LengthLimitingTextInputFormatter(100)],
                        validator: _ctrl.obrigatorio,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CampoTexto(
                        label: 'UF',
                        controller: _ctrl.uf,
                        hint: 'PR',
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(2),
                          FilteringTextInputFormatter.allow(RegExp('[A-Za-z]')),
                        ],
                        validator: _ctrl.validarUf,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CampoTexto(
                  label: 'País',
                  controller: _ctrl.pais,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [LengthLimitingTextInputFormatter(60)],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Máscara 00000-000.
class _CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue antigo,
    TextEditingValue novo,
  ) {
    final d = novo.text.replaceAll(RegExp(r'\D'), '');
    final limitado = d.length > 8 ? d.substring(0, 8) : d;
    final texto = limitado.length > 5
        ? '${limitado.substring(0, 5)}-${limitado.substring(5)}'
        : limitado;
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
