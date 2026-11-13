import 'package:shared/erros/codigo_erro.dart';

class AvaliacaoException implements Exception {
  const AvaliacaoException(this.codigo, {this.campo});
  final CodigoErro codigo;
  final String? campo;
}
