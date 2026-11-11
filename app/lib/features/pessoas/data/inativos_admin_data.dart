/// Dados que a tela de inativos recebe da camada de estado.
///
/// A lista já deve vir filtrada pela regra D23. A tela apenas apresenta os
/// valores e não calcula o corte de 30 dias.
class InativosAdminData {
  const InativosAdminData({required this.alunos, required this.professores});

  static const demonstracao = InativosAdminData(
    alunos: [
      PessoaInativaAdminData(id: 1, nome: 'Carlos Menezes', diasSemAcesso: 47),
      PessoaInativaAdminData(id: 2, nome: 'Júlia Prado', diasSemAcesso: 38),
      PessoaInativaAdminData(id: 3, nome: 'Rafael Moura', diasSemAcesso: 31),
    ],
    professores: [
      PessoaInativaAdminData(id: 4, nome: 'Marina Alves', diasSemAcesso: 47),
      PessoaInativaAdminData(id: 5, nome: 'Rafael Nunes', diasSemAcesso: 38),
      PessoaInativaAdminData(id: 6, nome: 'Beatriz Lima', diasSemAcesso: 31),
    ],
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
