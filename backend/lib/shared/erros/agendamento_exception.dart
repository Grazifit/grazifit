import 'package:shared/erros/codigo_erro.dart';

/// Falhas de regra de agendamento. Permissao generica usa `AcessoNegado`.
sealed class AgendamentoException implements Exception {
  final CodigoErro codigo;

  /// Campo culpado, em snake_case.
  final String? campo;

  /// Texto de apoio; quando nulo, o controller usa o padrao do codigo.
  final String? mensagem;

  const AgendamentoException(this.codigo, {this.campo, this.mensagem});

  @override
  String toString() => 'AgendamentoException(${codigo.valor}, campo: $campo)';
}

/// HTTP 409.
final class AgendamentoConflictException extends AgendamentoException {
  const AgendamentoConflictException(super.codigo);
}

/// HTTP 404.
final class AgendamentoNotFoundException extends AgendamentoException {
  const AgendamentoNotFoundException(String mensagem)
    : super(CodigoErro.registroNaoEncontrado, mensagem: mensagem);
}

/// Falha da chamada com texto proprio. O controller de aulas a traduz para
/// o envelope de erro.
class ChamadaException implements Exception {
  final CodigoErro codigo;
  final String? campo;
  final String mensagem;

  const ChamadaException(this.codigo, {required this.mensagem, this.campo});

  @override
  String toString() => 'ChamadaException(${codigo.valor}, campo: $campo)';
}
