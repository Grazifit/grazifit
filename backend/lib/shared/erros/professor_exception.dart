import 'package:shared/erros/codigo_erro.dart';

sealed class ProfessorException implements Exception {
  /// Código do envelope `{ codigo, mensagem, campo? }`.
  final CodigoErro codigo;

  /// Campo culpado, em snake_case. Nulo quando não é atribuível a um campo.
  final String? campo;

  const ProfessorException(this.codigo, {this.campo});

  @override
  String toString() => 'ProfessorException(${codigo.valor}, campo: $campo)';
}

/// Dado rejeitado antes de chegar ao banco. Vira HTTP 400.
final class ProfessorValidationException extends ProfessorException {
  const ProfessorValidationException(super.codigo, {super.campo});
}

/// Registro que já existe. Vira HTTP 409.
final class ProfessorConflictException extends ProfessorException {
  const ProfessorConflictException(super.codigo, {super.campo});
}

/// Id inexistente. Vira HTTP 404.
final class ProfessorNotFoundException extends ProfessorException {
  const ProfessorNotFoundException()
    : super(CodigoErro.professorNaoEncontrado);
}