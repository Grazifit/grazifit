
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../widgets/cartao_aula.dart' show StatusAula;

/// Aula na agenda do professor.
class AulaProfessor {
  final int idAula;
  final String horario;
  final String modalidade;
  final String professor;
  final int vagasOcupadas;
  final int vagasTotais;
  final StatusAula status;

  /// `AAAA-MM-DD`, quando a aula foi cancelada.
  final String? dataCancelamento;

  const AulaProfessor({
    required this.idAula,
    required this.horario,
    required this.modalidade,
    required this.professor,
    required this.vagasOcupadas,
    required this.vagasTotais,
    required this.status,
    this.dataCancelamento,
  });

  bool get cancelada => status == StatusAula.cancelada;

  factory AulaProfessor.fromJson(Map<String, dynamic> json) => AulaProfessor(
        idAula: json['id_aula'] as int,
        horario: json['horario'] as String,
        modalidade: json['modalidade'] as String,
        professor: json['professor'] as String,
        vagasOcupadas: (json['vagas_ocupadas'] as num).toInt(),
        vagasTotais: (json['vagas_totais'] as num).toInt(),
        status: switch (json['status']) {
          'ultimas_vagas' => StatusAula.ultimasVagas,
          'cancelada' => StatusAula.cancelada,
          _ => StatusAula.normal,
        },
        dataCancelamento: json['data_cancelamento'] as String?,
      );
}

class AgendaProfessor {
  /// Dia da agenda, `AAAA-MM-DD`.
  final String data;
  final List<AulaProfessor> aulas;

  const AgendaProfessor({required this.data, required this.aulas});

  factory AgendaProfessor.fromJson(Map<String, dynamic> json) =>
      AgendaProfessor(
        data: json['data'] as String,
        aulas: (json['aulas'] as List<dynamic>)
            .map((e) => AulaProfessor.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AlunoNaAula {
  final int idAluno;
  final String nome;

  const AlunoNaAula({required this.idAluno, required this.nome});

  factory AlunoNaAula.fromJson(Map<String, dynamic> json) => AlunoNaAula(
        idAluno: json['id_aluno'] as int,
        nome: json['nome'] as String,
      );
}

class AulaProfessorDetalhe {
  final AulaProfessor aula;

  /// Dia da aula, `AAAA-MM-DD`.
  final String data;
  final List<AlunoNaAula> alunos;

  const AulaProfessorDetalhe({
    required this.aula,
    required this.data,
    required this.alunos,
  });

  factory AulaProfessorDetalhe.fromJson(Map<String, dynamic> json) =>
      AulaProfessorDetalhe(
        aula: AulaProfessor.fromJson(json),
        data: json['data'] as String,
        alunos: (json['alunos'] as List<dynamic>)
            .map((e) => AlunoNaAula.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

abstract class AulasProfessorRepository {
  /// Aulas do dia do professor logado (F-10).
  Future<AgendaProfessor> agendaDoDia();

  Future<AulaProfessorDetalhe> detalhe(int idAula);

  /// Cancela a aula e, em cascata, os agendamentos (F-12/D9).
  Future<void> cancelar(int idAula);

  /// Encerra a chamada (F-11). Uma posição por aluno, na ordem de `alunos`:
  /// true = presente, false = faltou, null = sem marcar (regra do que fazer
  /// com "sem marcar" ainda não definida pelo produto).
  Future<void> encerrarChamada(int idAula, Map<int, bool?> presencas);
}

/// **Sem backend de `aulas`/`agendamentos`** ainda: falha com
/// [ApiException.pendente]. Ver docs/integracao-frontend.md.
class AulasProfessorRepositoryHttp implements AulasProfessorRepository {
  // ignore: unused_field
  final ApiClient _api;

  const AulasProfessorRepositoryHttp(this._api);

  @override
  Future<AgendaProfessor> agendaDoDia() async {
    // TODO(backend): aulas do dia do professor logado.
    throw const ApiException.pendente();
  }

  @override
  Future<AulaProfessorDetalhe> detalhe(int idAula) async {
    // TODO(backend): aula + alunos agendados.
    throw const ApiException.pendente();
  }

  @override
  Future<void> cancelar(int idAula) async {
    // TODO(backend): AulaService.cancelar → cancelarEmCascata.
    throw const ApiException.pendente();
  }

  @override
  Future<void> encerrarChamada(int idAula, Map<int, bool?> presencas) async {
    // TODO(backend): grava agendamento.status e data_presenca (F-11).
    throw const ApiException.pendente();
  }
}
