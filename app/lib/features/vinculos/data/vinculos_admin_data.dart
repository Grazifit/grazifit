/// Dados de apresentação usados pelo painel Admin de vínculos.
class VinculosAdminData {
  const VinculosAdminData({required this.ativos, required this.encerrados});

  static const vazio = VinculosAdminData(
    ativos: [],
    encerrados: [],
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
