// app/lib/core/utils/formatadores.dart
//
// Máscaras de entrada (apenas exibição). A validação de domínio real vive no
// banco/backend (ex.: dom_cpf, §7 da arquitetura).
//
// Os separadores são escritos ANTES do próximo dígito (e não depois do
// anterior). Assim, ao apagar com backspace, o separador some junto e o campo
// não "trava" em valores como "123.".

import 'package:flutter/services.dart';

String _soDigitos(String texto, int maximo) {
  final digitos = texto.replaceAll(RegExp(r'\D'), '');
  return digitos.length > maximo ? digitos.substring(0, maximo) : digitos;
}

TextEditingValue _cursorNoFim(String texto) => TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );

/// 000.000.000-00
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = _soDigitos(newValue.text, 11);
    
    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digitos[i]);
    }
    return _cursorNoFim(buffer.toString());
  }
}

/// (00) 00000-0000 ou (00) 0000-0000
class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = _soDigitos(newValue.text, 11);
    final posicaoHiffen = digitos.length > 10 ? 7 : 6;

    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (i == posicaoHiffen) buffer.write('-');
      buffer.write(digitos[i]);
    }
    return _cursorNoFim(buffer.toString());
  }
}

/// dd/mm/aaaa
class DataInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = _soDigitos(newValue.text, 8);

    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(digitos[i]);
    }
    return _cursorNoFim(buffer.toString());
  }
}
