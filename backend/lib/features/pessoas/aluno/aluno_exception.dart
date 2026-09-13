import 'package:shared/erros/codigo_erro.dart';

sealed class AlunoException implements Exception {
  /// O codigo do envelope `{ codigo, mensagem, campo? }`.
  final CodigoErro codigo;

  /// Nome do campo culpado, em snake_case, como o cliente o enviou.
  /// Nulo quando a falha nao e atribuivel a um campo.
  final String? campo;

  const AlunoException(this.codigo, {this.campo});

  @override
  String toString() => 'AlunoException(${codigo.valor}, campo: $campo)';
}

/// Dado rejeitado **antes** de chegar ao banco. Vira HTTP 400.
final class AlunoValidationException extends AlunoException {
  const AlunoValidationException(super.codigo, {super.campo});
}

/// Registro que ja existe. Vira HTTP 409.
final class AlunoConflictException extends AlunoException {
  const AlunoConflictException(super.codigo, {super.campo});
}
