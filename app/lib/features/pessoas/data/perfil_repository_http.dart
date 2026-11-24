import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'perfil_aluno.dart';
import 'perfil_repository.dart';

/// Implementação real de [PerfilRepository]: `GET`/`PATCH /aluno/<id>` e
/// `POST /auth/logout`.
///
/// Lacunas do backend (ver docs/integracao-frontend.md):
/// - o DTO público do aluno não traz CPF, nascimento nem data de cadastro, e
///   o aluno não tem restrição médica/observações no DTO: esses campos chegam
///   vazios;
/// - o `PATCH` só aceita nome, e-mail e telefone: CPF, nascimento e senha
///   digitados na edição **não são enviados**.
class PerfilRepositoryHttp implements PerfilRepository {
  const PerfilRepositoryHttp(this._api, this._idAluno, this._aoSair);

  final ApiClient _api;
  final int? Function() _idAluno;

  /// Limpa a sessão local (token e usuário).
  final void Function() _aoSair;

  int get _id {
    final id = _idAluno();
    if (id == null) throw const ApiException(statusCode: 401);
    return id;
  }

  @override
  Future<PerfilAluno> buscarPerfil() async {
    final json = await _api.get('/aluno/$_id');
    return PerfilAluno(
      nome: json['nome'] as String,
      desde: '',
      email: json['email'] as String,
      telefone: json['telefone'] as String,
      cpf: '',
      nascimento: '',
    );
  }

  @override
  Future<void> atualizarPerfil({
    required String nome,
    required String cpf,
    required String email,
    required String nascimento,
    String? novaSenha,
  }) async {
    await _api.patch('/aluno/$_id', {'nome': nome.trim(), 'email': email.trim()});
  }

  @override
  Future<void> sair() async {
    try {
      await _api.post('/auth/logout', const {});
    } on ApiException {
      // Token já expirado ou sem rede: a sessão local sai do mesmo jeito.
    }
    _aoSair();
  }
}
