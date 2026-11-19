import 'perfil_aluno.dart';

/// Contrato de acesso aos dados do perfil do aluno. As telas só conhecem esta
/// interface.
///
/// Para integrar com o backend, crie uma classe que a implemente (ex.:
/// `PerfilRepositoryHttp`), usando `PerfilAluno.fromJson`, e troque a linha de
/// perfil em `core/data/repositorios.dart`.
abstract class PerfilRepository {
  /// Perfil do aluno logado.
  Future<PerfilAluno> buscarPerfil();

  /// Atualiza os dados do perfil. [novaSenha] é nula quando o aluno não quer
  /// trocar a senha. Deve lançar uma exceção se não for possível salvar.
  Future<void> atualizarPerfil({
    required String nome,
    required String cpf,
    required String email,
    required String nascimento,
    String? novaSenha,
  });

  /// Encerra a sessão do aluno (ex.: invalida o token e limpa os dados salvos
  /// no aparelho). Deve lançar uma exceção se não for possível sair.
  Future<void> sair();
}
