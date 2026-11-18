/// Dados preenchidos no formulário de cadastro de exercício do Admin.
/// O envio e a validação de unicidade ficam a cargo da integração/backend.
class NovoExercicioAdminInput {
  const NovoExercicioAdminInput({
    required this.nome,
    required this.instrucoes,
    required this.dificuldade,
    this.descricao,
  });

  final String nome;
  final String instrucoes;
  final String? descricao;
  final String dificuldade;
}
