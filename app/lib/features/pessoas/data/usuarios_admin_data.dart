/// Dados de apresentação da tela administrativa de usuários.
///
/// O conteúdo demonstrativo fica separado da tela e pode ser substituído por
/// dados preparados pela camada de estado/repositório quando ela existir.
class UsuariosAdminData {
  const UsuariosAdminData({
    required this.alunos,
    required this.professores,
  });

  static const demonstracao = UsuariosAdminData(
    alunos: [
      UsuarioAdminData(
        nome: 'Ana Beatriz Ramos',
        ativo: true,
        statusLegivel: 'Ativa',
        complemento: 'Prof. Marina Alves',
      ),
      UsuarioAdminData(
        nome: 'Carlos Menezes',
        ativo: true,
        statusLegivel: 'Ativo',
        complemento: 'sem professor',
      ),
      UsuarioAdminData(
        nome: 'Júlia Prado',
        ativo: true,
        statusLegivel: 'Ativa',
        complemento: 'Prof. Marina Alves',
      ),
      UsuarioAdminData(
        nome: 'Rafael Moura',
        ativo: false,
        statusLegivel: 'Inativo',
        complemento: 'sem professor',
      ),
      UsuarioAdminData(
        nome: 'Beatriz Martins',
        ativo: false,
        statusLegivel: 'Inativa',
        complemento: 'Prof. Marina Alves',
      ),
    ],
    professores: [
      UsuarioAdminData(
        nome: 'Marina Alves',
        ativo: true,
        statusLegivel: 'Ativa',
      ),
      UsuarioAdminData(
        nome: 'Rafael Costa',
        ativo: true,
        statusLegivel: 'Ativo',
      ),
      UsuarioAdminData(
        nome: 'Paula Nunes',
        ativo: false,
        statusLegivel: 'Inativa',
      ),
    ],
  );

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
