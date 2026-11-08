const Set<String> tiposAula = {'coletiva', 'individual', 'experimental'};

const Set<String> categoriasAula = {
  'musculacao',
  'funcional',
  'pilates',
  'crossfit',
  'danca',
  'spinning',
};

/// `status = false` indica aula cancelada.
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
    'status': status,
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
