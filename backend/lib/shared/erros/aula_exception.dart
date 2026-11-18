import 'package:shared/erros/codigo_erro.dart';

/// Falhas de regra de aula. Permissao negada usa `AcessoNegado`.
sealed class AulaException implements Exception {
  final CodigoErro codigo;

  /// Campo culpado, em snake_case.
  final String? campo;

  const AulaException(this.codigo, {this.campo});

  @override
  String toString() => 'AulaException(${codigo.valor}, campo: $campo)';
}

/// HTTP 400.
final class AulaValidationException extends AulaException {
  const AulaValidationException(super.codigo, {super.campo});
}

/// HTTP 409.
final class AulaConflictException extends AulaException {
  const AulaConflictException(super.codigo, {super.campo});
}

/// HTTP 404.
final class AulaNotFoundException extends AulaException {
  const AulaNotFoundException() : super(CodigoErro.registroNaoEncontrado);
}
