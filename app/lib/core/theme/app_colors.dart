import 'package:flutter/material.dart';

/// Cores compartilhadas do app. Para mudar a cor de uma barra, chip ou
/// fundo em todas as telas de uma vez, altere o valor aqui.
class AppColors {
  AppColors._();

  /// Verde principal: barra inferior, abas e chips selecionados, botões.
  static const Color verde = Color(0xFF1B5E3C);

  /// Verde claro usado em tags e destaques suaves.
  static const Color verdeClaro = Color(0xFFE3EFEA);

  /// Fundo padrão das telas.
  static const Color fundo = Color(0xFFF3F4F6);

  /// Vermelho para ações destrutivas (ex.: cancelar agendamento).
  static const Color vermelho = Color(0xFFB3261E);
}