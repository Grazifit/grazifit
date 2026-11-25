/// Dados de apresentação da tela administrativa de usuários.
///
/// Os dados vêm de `Repositorios.admin`.
class UsuariosAdminData {
  const UsuariosAdminData({
    required this.alunos,
    required this.professores,
  });

  static const vazio = UsuariosAdminData(alunos: [], professores: []);

  final List<UsuarioAdminData> alunos;
  final List<UsuarioAdminData> professores;
}

/// Resumo público de usuário usado pelas linhas e pelo detalhe local.
class UsuarioAdminData {
  const UsuarioAdminData({
    required this.nome,
    required this.ativo,
    this.statusLegivel,
    this.complemento,
  });

  final String nome;
  final bool ativo;
  final String? statusLegivel;
  final String? complemento;

  String get status => statusLegivel ?? (ativo ? 'Ativo' : 'Inativo');
}
