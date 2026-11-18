import 'aula_serializer.dart' show dataParaJson;

/// DTO de `agendamento`. Quem le e sempre o proprio aluno (CA-10), entao o
/// `id_aluno` nao expoe terceiros. Datas com instante saem em UTC ISO-8601.
Map<String, dynamic> agendamentoToJson({
  required int idAgendamento,
  required int idAluno,
  required int idAula,
  required DateTime dataAgendamento,
  required String status,
  required DateTime? dataPresenca,
  required DateTime? dataCancelamento,
}) {
  return {
    'id_agendamento': idAgendamento,
    'id_aluno': idAluno,
    'id_aula': idAula,
    'data_agendamento': dataParaJson(dataAgendamento),
    'status': status,
    'data_presenca': dataPresenca?.toUtc().toIso8601String(),
    'data_cancelamento': dataCancelamento?.toUtc().toIso8601String(),
  };
}
