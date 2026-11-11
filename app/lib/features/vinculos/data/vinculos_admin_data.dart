/// Dados de apresentação usados pelo painel Admin de vínculos.
class VinculosAdminData {
  const VinculosAdminData({required this.ativos, required this.encerrados});

  static const demonstracao = VinculosAdminData(
    ativos: [
      VinculoAdminData(
        id: 1,
        alunoNome: 'Ana Beatriz Ramos',
        professorNome: 'Marina Alves',
      ),
      VinculoAdminData(
        id: 2,
        alunoNome: 'Carlos Menezes',
        professorNome: 'Rafael Nunes',
      ),
      VinculoAdminData(
        id: 3,
        alunoNome: 'Júlia Prado',
        professorNome: 'Marina Alves',
      ),
    ],
    encerrados: [
      VinculoAdminData(
        id: 4,
        alunoNome: 'Rafael Moura',
        professorNome: 'Beatriz Lima',
      ),
    ],
  );

  final List<VinculoAdminData> ativos;
  final List<VinculoAdminData> encerrados;
}

class VinculoAdminData {
  const VinculoAdminData({
    required this.id,
    required this.alunoNome,
    required this.professorNome,
  });

  final int id;
  final String alunoNome;
  final String professorNome;
}
