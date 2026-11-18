/// Item da lista de agendados de uma aula, para admin e professor. So
/// identifica o aluno pelo id e nome: CPF, contato e saude nao entram.
Map<String, dynamic> aulaAgendadoToJson({
  required int idAgendamento,
  required int idAluno,
  required String nomeAluno,
  required String status,
}) {
  return {
    'id_agendamento': idAgendamento,
    'id_aluno': idAluno,
    'nome_aluno': nomeAluno,
    'status': status,
  };
}
