import 'package:shared/erros/codigo_erro.dart';

class CronogramaException implements Exception {
  const CronogramaException(this.codigo, {this.campo});
  final CodigoErro codigo;
  final String? campo;
}

/// Contrato local ao backend; datas civis e horarios nao carregam fuso.
class Cronograma {
  Cronograma(this.dados);
  final Map<String, dynamic> dados;
  Map<String, dynamic> toJson() => Map.of(dados);
}
