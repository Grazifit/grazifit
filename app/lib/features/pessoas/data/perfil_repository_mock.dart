import 'perfil_aluno.dart';
import 'perfil_repository.dart';

/// Implementação de exemplo, com dados fixos em memória, para desenvolver as
/// telas sem backend. Atualizar o perfil altera os dados mantidos aqui.
///
/// Quando a integração estiver pronta, este arquivo pode ser apagado junto com
/// o seu uso em `core/data/repositorios.dart`.
class PerfilRepositoryMock implements PerfilRepository {
  PerfilAluno _perfil = const PerfilAluno(
    nome: 'Ana Beatriz Ramos',
    desde: '12/03/2025',
    email: 'ana.ramos@exemplo.com',
    telefone: '(45) 90000-0000',
    cpf: '000.000.000-00',
    nascimento: '14/07/1996',
  );

  @override
  Future<void> sair() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<PerfilAluno> buscarPerfil() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _perfil;
  }

  @override
  Future<void> atualizarPerfil({
    required String nome,
    required String cpf,
    required String email,
    required String nascimento,
    String? novaSenha,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _perfil = PerfilAluno(
      nome: nome,
      desde: _perfil.desde,
      email: email,
      telefone: _perfil.telefone,
      cpf: cpf,
      nascimento: nascimento,
      restricaoMedica: _perfil.restricaoMedica,
      observacoesSaude: _perfil.observacoesSaude,
    );
  }
}
