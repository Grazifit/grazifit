import 'package:shared/erros/codigo_erro.dart';

sealed class ExercicioException implements Exception {
  /// O codigo do envelope `{ codigo, mensagem, campo? }`.
  final CodigoErro codigo;

  /// Nome do campo culpado, em snake_case, como o cliente o enviou.
  /// Nulo quando a falha nao e atribuivel a um campo.
  final String? campo;

  const ExercicioException(this.codigo, {this.campo});

  @override
  String toString() => 'ExercicioException(${codigo.valor}, campo: $campo)';
}

/// Dado rejeitado **antes** de chegar ao banco. Vira HTTP 400.
final class ExercicioValidationException extends ExercicioException {
  const ExercicioValidationException(super.codigo, {super.campo});
}

/// Registro que ja existe. Vira HTTP 409.
final class ExercicioConflictException extends ExercicioException {
  const ExercicioConflictException(super.codigo, {super.campo});
}

/// Exercicio que nao existe. Vira HTTP 404.
///
/// O codigo e sempre `registroNaoEncontrado` (`docs/arquitetura.md` §7.5).
final class ExercicioNotFoundException extends ExercicioException {
  const ExercicioNotFoundException() : super(CodigoErro.registroNaoEncontrado);
}
