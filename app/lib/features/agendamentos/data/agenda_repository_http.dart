import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'agenda_repository.dart';
import 'agendamento.dart';
import 'aula.dart';

/// Implementação real de [AgendaRepository].
///
/// **O backend de aulas/agendamentos ainda não existe**: cada método lança
/// [ApiException.pendente]. Ao integrar, use `Modalidade.fromJson`,
/// `Aula.fromJson` e `Agendamento.fromJson` (as chaves desses modelos são
/// suposição: ajustar ao contrato real). Erros esperados pelo `codigo`:
/// AULA_SEM_VAGAS, AGENDAMENTO_DUPLICADO, HORARIO_CONFLITANTE, AULA_INATIVA.
class AgendaRepositoryHttp implements AgendaRepository {
  const AgendaRepositoryHttp(this._api);

  // ignore: unused_field
  final ApiClient _api;

  @override
  Future<List<Modalidade>> buscarModalidades() async {
    // TODO(backend): modalidades (filtro da agenda).
    throw const ApiException.pendente();
  }

  @override
  Future<List<Aula>> buscarAulas() async {
    // TODO(backend): aulas + vw_aula_ocupacao.
    throw const ApiException.pendente();
  }

  @override
  Future<void> agendarAula(String aulaId) async {
    // TODO(backend): cria agendamento.
    throw const ApiException.pendente();
  }

  @override
  Future<List<Agendamento>> buscarMeusAgendamentos() async {
    // TODO(backend): agendamentos do aluno logado.
    throw const ApiException.pendente();
  }

  @override
  Future<void> cancelarAgendamento(String agendamentoId) async {
    // TODO(backend): cancela agendamento.
    throw const ApiException.pendente();
  }
}
