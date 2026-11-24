import '../../shared/autorizacao/identidade.dart';
import 'treino_repository.dart';

class TreinoService {
  TreinoService(this._repository);

  final TreinoRepository _repository;

  /// Treinos livres sao disponiveis a todos os perfis autenticados.
  Future<({List<TreinoLivre> itens, int total})> listarLivres(
    Identidade identidade, {
    required int limit,
    required int offset,
  }) async {
    final itens = await _repository.listarLivres(limit: limit, offset: offset);
    final total = await _repository.contarLivres();
    return (itens: itens, total: total);
  }
}
