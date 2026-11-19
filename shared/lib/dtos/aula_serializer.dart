const Set<String> tiposAula = {'coletiva', 'individual', 'experimental'};

const Set<String> categoriasAula = {
  'musculacao',
  'funcional',
  'pilates',
  'crossfit',
  'danca',
  'spinning',
};

/// `status = false` indica aula cancelada. Quem cancelou sai so como papel
/// (`cancelado_por`), sem o id; `data_cancelamento` em UTC ISO-8601.
/// `vagas_livres` e derivado de `vagas_maxima` e `vagas_ocupadas`.
Map<String, dynamic> aulaToJson({
  required int idAula,
  required int idProfessor,
  required int? idCronograma,
  required DateTime data,
  required Duration horaInicio,
  required Duration horaFim,
  required String tipo,
  required String categoria,
  required int vagasMaxima,
  required bool status,
  required DateTime? dataCancelamento,
  required int? idProfessorCancelou,
  required int? idAdminCancelou,
  required int vagasOcupadas,
}) {
  return {
    'id_aula': idAula,
    'id_professor': idProfessor,
    'id_cronograma': idCronograma,
    'data': dataParaJson(data),
    'hora_inicio': horaParaJson(horaInicio),
    'hora_fim': horaParaJson(horaFim),
    'tipo': tipo,
    'categoria': categoria,
    'vagas_maxima': vagasMaxima,
    'vagas_ocupadas': vagasOcupadas,
    'vagas_livres': vagasMaxima - vagasOcupadas,
    'status': status,
    'data_cancelamento': dataCancelamento?.toUtc().toIso8601String(),
    'cancelado_por': idAdminCancelou != null
        ? 'admin'
        : (idProfessorCancelou != null ? 'professor' : null),
  };
}

/// `AAAA-MM-DD`.
String dataParaJson(DateTime data) {
  final ano = data.year.toString().padLeft(4, '0');
  final mes = data.month.toString().padLeft(2, '0');
  final dia = data.day.toString().padLeft(2, '0');
  return '$ano-$mes-$dia';
}

/// `HH:MM`.
String horaParaJson(Duration desdeMeiaNoite) {
  final hora = desdeMeiaNoite.inHours.toString().padLeft(2, '0');
  final minuto = (desdeMeiaNoite.inMinutes % 60).toString().padLeft(2, '0');
  return '$hora:$minuto';
}
