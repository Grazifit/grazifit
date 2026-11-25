import 'treino_detalhe.dart';
import 'treino_resumo.dart';

/// Contrato de acesso aos dados de treinos. As telas só conhecem esta
/// interface. A implementação usada é definida em `core/data/repositorios.dart`.
abstract class TreinosRepository {
  /// Lista de treinos do aluno: os montados pelo professor e os livres.
  Future<TreinosDoAluno> buscarTreinos();

  /// Busca o treino com seus exercícios.
  Future<TreinoDetalhe> buscarTreino(String id);

  /// Registra que o aluno executou o treino.
  Future<void> confirmarExecucao(String treinoId);
}
