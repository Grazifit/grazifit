import 'evolucao_aluno.dart';

/// Contrato de acesso aos dados de evolução do aluno (altura e medidas de
/// peso). As telas só conhecem esta interface.
///
/// Para integrar com o backend, crie uma classe que a implemente (ex.:
/// `AvaliacoesRepositoryHttp`), usando `EvolucaoAluno.fromJson`, e troque a
/// linha de avaliações em `core/data/repositorios.dart`.
abstract class AvaliacoesRepository {
  /// Altura da última avaliação e histórico de medidas.
  Future<EvolucaoAluno> buscarEvolucao();

  /// Registra uma nova medida de peso (em kg) do aluno.
  /// Deve lançar uma exceção se não for possível registrar.
  Future<void> registrarMedida(double peso);
}
