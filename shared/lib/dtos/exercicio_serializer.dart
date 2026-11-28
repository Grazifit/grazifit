/// Exercicio como o catalogo o expoe.
///
/// Recebe valores soltos pelo mesmo motivo de `admin_serializer.dart`: esta
/// pasta nao importa nada do projeto.
Map<String, dynamic> exercicioToPublicJson({
  required int idExercicio,
  required String nome,
  required String instrucoes,
  String? descricao,
  required String dificuldade,
}) {
  return {
    'id_exercicio': idExercicio,
    'nome': nome,
    'instrucoes': instrucoes,
    'descricao': descricao,
    'dificuldade': dificuldade,
  };
}
