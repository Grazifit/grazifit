import '../../features/agendamentos/data/agenda_repository.dart';
import '../../features/agendamentos/data/agenda_repository_mock.dart';
import '../../features/avaliacoes/data/avaliacoes_repository.dart';
import '../../features/avaliacoes/data/avaliacoes_repository_mock.dart';
import '../../features/pessoas/data/perfil_repository.dart';
import '../../features/pessoas/data/perfil_repository_mock.dart';
import '../../features/treinos/data/treinos_repository.dart';

/// Ponto único de onde as telas obtêm os repositórios de dados.
///
/// Hoje todos apontam para os mocks (dados de exemplo). Para integrar com o
/// backend, crie a implementação real de cada contrato (ex.:
/// `AgendaRepositoryHttp`) e troque a linha correspondente aqui. As telas não
/// precisam ser alteradas.
///
/// Cada tela também aceita um `repository` pelo construtor, o que permite
/// injetar uma implementação diferente em testes.
class Repositorios {
  Repositorios._();

  // TODO: trocar cada mock pela implementação que chama o backend.
  static final AgendaRepository agenda = AgendaRepositoryMock();
  static final TreinosRepository treinos = TreinosRepositoryMock();
  static final AvaliacoesRepository avaliacoes = AvaliacoesRepositoryMock();
  static final PerfilRepository perfil = PerfilRepositoryMock();
}
