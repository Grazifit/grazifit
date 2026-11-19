import 'agendamento.dart';
import 'aula.dart';

/// Contrato de acesso aos dados de agenda do aluno: aulas disponíveis e
/// agendamentos. As telas só conhecem esta interface.
///
/// Para integrar com o backend, crie uma classe que a implemente (ex.:
/// `AgendaRepositoryHttp`), usando `Modalidade.fromJson`, `Aula.fromJson` e
/// `Agendamento.fromJson`, e troque a linha da agenda em
/// `core/data/repositorios.dart`.
///
/// Os métodos devem lançar uma exceção quando a operação falhar; as telas
/// tratam isso mostrando mensagem de erro.
abstract class AgendaRepository {
  /// Modalidades disponíveis para o filtro da tela.
  Future<List<Modalidade>> buscarModalidades();

  /// Aulas disponíveis para agendamento.
  ///
  /// TODO: a tela ainda não tem seleção de dia. Quando houver, incluir aqui um
  /// parâmetro de data.
  Future<List<Aula>> buscarAulas();

  /// Confirma o agendamento do aluno na aula [aulaId].
  /// Deve lançar uma exceção se não for possível agendar (ex.: aula lotada).
  Future<void> agendarAula(String aulaId);

  /// Agendamentos do aluno.
  Future<List<Agendamento>> buscarMeusAgendamentos();

  /// Cancela o agendamento [agendamentoId].
  /// Deve lançar uma exceção se não for possível cancelar (ex.: fora do prazo).
  Future<void> cancelarAgendamento(String agendamentoId);
}
