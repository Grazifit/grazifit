Map<String, dynamic> professorToPublicJson({
  required int idProfessor,
  required String nome,
  required String email,
  required String telefone,
  required bool status,
}) {
  return {
    'id_professor': idProfessor,
    'nome': nome,
    'email': email,
    'telefone': telefone,
    'status': status,
  };
}