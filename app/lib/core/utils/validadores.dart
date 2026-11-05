// app/lib/core/utils/validadores.dart
//
// Validações de FORMATO apenas, para UX. Regra de negócio (CPF/e-mail em uso,
// CPF inválido etc.) é contrato de backend: CPF_EM_USO, EMAIL_EM_USO,
// CPF_INVALIDO, EMAIL_INVALIDO (arquitetura §7).

abstract final class Validadores {
  /// TODO(specs): regra de senha provisória (a do cadastro de professor).
  /// Não consta em nenhum RF/RNF nem em D59 (que só fixa Argon2id + pepper no
  /// hash). Confirmar com o time/backend; vale para professor E aluno.
  static const textoRegraSenha =
      'Mínimo 8 caracteres, 1 maiúscula e 1 caractere especial';

  static String _digitos(String? v) => (v ?? '').replaceAll(RegExp(r'\D'), '');

  static String? nome(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Informe o nome completo' : null;

  static String? cpf(String? v) =>
      _digitos(v).length == 11 ? null : 'CPF deve ter 11 dígitos';

  static String? email(String? v) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch((v ?? '').trim()) ? null : 'E-mail inválido';
  }

  static String? senha(String? v) {
    final valor = v ?? '';
    if (valor.length < 8) return 'Mínimo de 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(valor)) {
      return 'Inclua ao menos 1 letra maiúscula';
    }
    if (!RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=/\\\[\];~`]''')
        .hasMatch(valor)) {
      return 'Inclua ao menos 1 caractere especial';
    }
    return null;
  }

  static String? telefone(String? v) =>
      _digitos(v).length >= 10 ? null : 'Telefone obrigatório';

  /// dd/mm/aaaa, data real e anterior a hoje.
  static String? nascimento(String? v) {
    final d = _digitos(v);
    if (d.length != 8) return 'Use o formato dd/mm/aaaa';
    final dia = int.parse(d.substring(0, 2));
    final mes = int.parse(d.substring(2, 4));
    final ano = int.parse(d.substring(4, 8));
    final data = DateTime(ano, mes, dia);
    if (data.day != dia || data.month != mes || ano < 1900) {
      return 'Data inválida';
    }
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    if (!data.isBefore(hoje)) return 'Informe uma data anterior a hoje';
    return null;
  }
}