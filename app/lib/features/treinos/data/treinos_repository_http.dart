import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'treino_detalhe.dart';
import 'treino_resumo.dart';
import 'treinos_repository.dart';

/// Implementação real de [TreinosRepository].
///
/// **O backend de treinos ainda não existe** (`backend/lib/features/treinos`
/// só tem README), então cada método lança [ApiException.pendente] e a tela
/// mostra o estado de erro. Quando o time de backend entregar os endpoints,
/// troque o `throw` pela chamada de [_api] e use `TreinosDoAluno.fromJson` /
/// `TreinoDetalhe.fromJson`.
class TreinosRepositoryHttp implements TreinosRepository {
  // ignore: unused_field
  const TreinosRepositoryHttp(this._api);

  // ignore: unused_field
  final ApiClient _api;

  @override
  Future<TreinosDoAluno> buscarTreinos() async {
    // TODO(backend): treinos do aluno logado (do professor e livres).
    throw const ApiException.pendente();
  }

  @override
  Future<TreinoDetalhe> buscarTreino(String id) async {
    // TODO(backend): treino com exercícios.
    throw const ApiException.pendente();
  }

  @override
  Future<void> confirmarExecucao(String treinoId) async {
    // TODO(backend): grava historico_treino.
    throw const ApiException.pendente();
  }
}
