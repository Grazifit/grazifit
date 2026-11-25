import '../../features/agendamentos/data/agenda_repository.dart';
import '../../features/agendamentos/data/agenda_repository_http.dart';
import '../../features/avaliacoes/data/avaliacoes_repository.dart';
import '../../features/avaliacoes/data/avaliacoes_repository_http.dart';
import '../../features/pessoas/data/perfil_repository.dart';
import '../../features/pessoas/data/perfil_repository_http.dart';
import '../../features/treinos/data/treinos_repository.dart';
import '../../features/treinos/data/treinos_repository_http.dart';
import '../../features/aulas/data/aulas_professor_repository.dart';
import '../../features/pessoas/data/professor_repository.dart';
import '../../features/treinos/data/treinos_professor_repository.dart';
import '../../features/vinculos/data/vinculos_repository.dart';
import '../../features/inicio/data/admin_repository.dart';
import '../network/api_client.dart';

/// Ponto único de onde as telas obtêm os repositórios de dados.
///
/// Todos chamam o backend por [ApiClient]. Onde o endpoint ainda não existe, o
/// repositório lança `ApiException.pendente()` e a tela mostra o estado de
/// erro. Quando o backend entregar, só a implementação `*_http.dart` muda.
///
/// [inicializar] roda uma vez, na raiz do app (ver `main.dart`). Cada tela
/// também aceita um `repository` pelo construtor, para testes.
class Repositorios {
  Repositorios._();

  static late AgendaRepository agenda;
  static late TreinosRepository treinos;
  static late AvaliacoesRepository avaliacoes;
  static late PerfilRepository perfil;

  // Professor
  static late VinculosRepository vinculos;
  static late TreinosProfessorRepository treinosProfessor;
  static late AulasProfessorRepository aulasProfessor;
  static late ProfessorRepository professores;

  // Admin
  static late AdminRepository admin;

  /// [idUsuario] devolve o id do usuário logado (nulo sem sessão); [aoSair]
  /// limpa a sessão local.
  static void inicializar(
    ApiClient api, {
    required int? Function() idUsuario,
    required void Function() aoSair,
  }) {
    agenda = AgendaRepositoryHttp(api);
    treinos = TreinosRepositoryHttp(api);
    avaliacoes = AvaliacoesRepositoryHttp(api, idUsuario);
    perfil = PerfilRepositoryHttp(api, idUsuario, aoSair);
    vinculos = VinculosRepositoryHttp(api);
    treinosProfessor = TreinosProfessorRepositoryHttp(api);
    aulasProfessor = AulasProfessorRepositoryHttp(api);
    professores = ProfessorRepository(api);
    admin = AdminRepositoryHttp(api);
  }
}
