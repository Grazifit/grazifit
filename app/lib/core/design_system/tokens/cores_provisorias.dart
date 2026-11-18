// app/lib/core/design_system/tokens/cores_provisorias.dart
//
// FONTE ÚNICA das cores enquanto os tokens reais do design system não existem.
// Nenhuma tela deve declarar cor de marca própria: importe daqui.
//
// TODO(specs): trocar pelos tokens reais (core/design_system/tokens) e apagar
// este arquivo. Valores aproximados, lidos da paleta de marca.

import 'package:flutter/material.dart';

/// Verde institucional (botões, ícones, foco de campos, destaques).
const corInstitucional = Color(0xFF0F4C3A);

/// Laranja de destaque (ex.: nome do aluno na tela de boas-vindas).
const corDestaque = Color(0xFFE8622C);

/// Fundo suave (chips e badges neutros).
const corSuperficieSuave = Color(0xFFEAEFED);

/// Divisor entre itens de lista.
const corDivisor = Color(0xFFE6E6E6);

/// Alerta (ex.: "Últimas vagas", "Faltou", registro do dia em edição).
/// Valor aproximado, lido do mockup do professor.
const corAlerta = Color(0xFF8C5A00);

/// Erro e ação destrutiva (ex.: aula cancelada, "Cancelar aula").
/// Valor aproximado, lido do mockup do professor.
const corErro = Color(0xFFB3261E);