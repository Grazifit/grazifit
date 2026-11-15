/// Dados que a tela de inativos recebe da camada de estado.
///
/// A lista já deve vir filtrada pela regra D23. A tela apenas apresenta os
/// valores e não calcula o corte de 30 dias.
class InativosAdminData {
  const InativosAdminData({required this.alunos, required this.professores});

  static const vazio = InativosAdminData(
    alunos: [],
    professores: [],
  );

  final List<PessoaInativaAdminData> alunos;
  final List<PessoaInativaAdminData> professores;
}

class PessoaInativaAdminData {
  const PessoaInativaAdminData({
    required this.id,
    required this.nome,
    required this.diasSemAcesso,
  });

  final int id;
  final String nome;

  /// Nulo representa alguém que nunca acessou, conforme D23.
  final int? diasSemAcesso;

  String get resumoAcesso => diasSemAcesso == null
      ? 'Nunca acessou'
      : '$diasSemAcesso dias sem acesso';
}
