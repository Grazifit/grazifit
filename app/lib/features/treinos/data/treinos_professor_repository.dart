
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

/// Treino de um aluno, na visão do professor.
class TreinoDoAluno {
  final String id;
  final String nome;
  final bool concluidoHoje;

  const TreinoDoAluno({
    required this.id,
    required this.nome,
    required this.concluidoHoje,
  });

  factory TreinoDoAluno.fromJson(Map<String, dynamic> json) => TreinoDoAluno(
        id: json['id'].toString(),
        nome: json['nome'] as String,
        concluidoHoje: json['concluido_hoje'] as bool,
      );
}

class ExecucaoTreino {
  final String treino;

  /// `AAAA-MM-DD`.
  final String data;
  final bool concluido;

  const ExecucaoTreino({
    required this.treino,
    required this.data,
    required this.concluido,
  });

  factory ExecucaoTreino.fromJson(Map<String, dynamic> json) => ExecucaoTreino(
        treino: json['treino'] as String,
        data: json['data'] as String,
        concluido: json['concluido'] as bool,
      );
}

/// Histórico dos últimos 30 dias. O total vem do backend.
class HistoricoAluno {
  final int total;
  final List<ExecucaoTreino> execucoes;

  const HistoricoAluno({required this.total, required this.execucoes});

  factory HistoricoAluno.fromJson(Map<String, dynamic> json) => HistoricoAluno(
        total: (json['total'] as num).toInt(),
        execucoes: (json['execucoes'] as List<dynamic>)
            .map((e) => ExecucaoTreino.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

abstract class TreinosProfessorRepository {
  Future<List<TreinoDoAluno>> listarDoAluno(int idAluno);
  Future<HistoricoAluno> historico(int idAluno);

  /// Professor confirma a execução. Lacuna D29: `historico_treino` não
  /// registra quem confirmou — não contornar.
  Future<void> confirmarExecucao(int idAluno, String idTreino);
}

/// **Sem backend de `treinos`/`historico`** ainda: falha com
/// [ApiException.pendente]. Ver docs/integracao-frontend.md.
class TreinosProfessorRepositoryHttp implements TreinosProfessorRepository {
  // ignore: unused_field
  final ApiClient _api;

  const TreinosProfessorRepositoryHttp(this._api);

  @override
  Future<List<TreinoDoAluno>> listarDoAluno(int idAluno) async {
    // TODO(backend): treinos do aluno + se concluiu hoje.
    throw const ApiException.pendente();
  }

  @override
  Future<HistoricoAluno> historico(int idAluno) async {
    // TODO(backend): historico_treino do aluno (30 dias).
    throw const ApiException.pendente();
  }

  @override
  Future<void> confirmarExecucao(int idAluno, String idTreino) async {
    // TODO(backend): grava historico_treino (ver D29).
    throw const ApiException.pendente();
  }
}
