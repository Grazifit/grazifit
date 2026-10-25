// app/lib/core/design_system/components/campo_texto.dart
//
// Campo de formulário padrão: rotulo acima, caixa branca sem borda,
// Borda verde no foco e texto abaixo

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/cores_provisorias.dart';
import '../../utils/validadores.dart';

class CampoTexto extends StatelessWidget {
  const CampoTexto({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helper;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final int maxLines;
  final int? minLines;

  OutlineInputBorder _borda([BorderSide lado = BorderSide.none]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: lado,
      );


  @override
  Widget build(BuildContext context) {
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
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          validator: validator,
          obscureText: obscureText,
          maxLines: maxLines,
          minLines: minLines,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: _borda(),
            enabledBorder: _borda(),
            focusedBorder: 
              _borda(const BorderSide(color: corInstitucional, width: 1.5)),
            errorBorder:
                _borda(const BorderSide(color: Colors.redAccent, width: 1)),
            focusedErrorBorder:
                _borda(const BorderSide(color: Colors.redAccent, width: 1.5)),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper!,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }
}
 
/// Campo de senha com alternância mostrar/ocultar.
class CampoSenha extends StatefulWidget {
  const CampoSenha({
    super.key,
    required this.controller,
    this.validator,
    this.label = 'Senha',
    this.helper = Validadores.textoRegraSenha,
  });
 
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String label;
  final String? helper;
 
  @override
  State<CampoSenha> createState() => _CampoSenhaState();
}
 
class _CampoSenhaState extends State<CampoSenha> {
  bool _visivel = false;
 
  @override
  Widget build(BuildContext context) {
    return CampoTexto(
      label: widget.label,
      controller: widget.controller,
      hint: '••••••••',
      helper: widget.helper,
      validator: widget.validator,
      obscureText: !_visivel,
      suffixIcon: IconButton(
        icon: Icon(
          _visivel ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey.shade500,
          size: 20,
        ),
        onPressed: () => setState(() => _visivel = !_visivel),
      ),
    );
  }
}