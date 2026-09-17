/// Aluno como o **admin** o enxerga.
/// 
Map<String, dynamic> alunoToPublicJson({
  required int idAluno,
  required String nome,
  required String email,
  required String telefone,
}) {
  return {
    'id_aluno': idAluno,
    'nome': nome,
    'email': email,
    'telefone': telefone,
  };
}
