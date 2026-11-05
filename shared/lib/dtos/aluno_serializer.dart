/// Aluno como o **admin** o enxerga.
///
/// `status`: `true` ativo, `false` inativo — o admin precisa ver qual dos
/// dois para decidir entre reativar e excluir.
Map<String, dynamic> alunoToPublicJson({
  required int idAluno,
  required String nome,
  required String email,
  required String telefone,
  required bool status,
}) {
  return {
    'id_aluno': idAluno,
    'nome': nome,
    'email': email,
    'telefone': telefone,
    'status': status,
  };
}
