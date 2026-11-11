import 'aula.dart';

/// Contrato de acesso aos dados da agenda do aluno.
///
/// A tela só conhece esta interface. Para integrar com o backend, basta criar
/// uma classe que a implemente (ex.: `AgendaRepositoryHttp`), usando
/// `Modalidade.fromJson` e `Aula.fromJson`, e trocar a implementação em
/// `_criarRepositorio` na `TelaAgendaAluno`.
abstract class AgendaRepository {
  /// Modalidades disponíveis para o filtro da tela.
  Future<List<Modalidade>> buscarModalidades();

  /// Aulas disponíveis para agendamento.
  ///
  /// TODO: a tela ainda não tem seleção de dia. Quando houver, incluir aqui um
  /// parâmetro de data.
  Future<List<Aula>> buscarAulas();
}