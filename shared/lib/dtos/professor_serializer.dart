Map<String, dynamic> professorToPublicJson({
  required int idProfessor,
  required String nome,
  required String email,
  required String telefone,
}) {
  return {
    'id_professor': idProfessor,
    'nome': nome,
    'email': email,
    'telefone': telefone,
  };
}