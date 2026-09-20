import 'package:shared/erros/codigo_erro.dart';

sealed class ProfessorException implements Exception {
  final CodigoErro codigo;
  final String? campo;

  const ProfessorException(this.codigo, {this.campo});

  @override
  String toString() => 'ProfessorException(${codigo.valor}, campo: $campo)';
}

final class ProfessorValidationException extends ProfessorException {
  const ProfessorValidationException(super.codigo, {super.campo});
}

final class ProfessorConflictException extends ProfessorException {
  const ProfessorConflictException(super.codigo, {super.campo});
}