/// Agendamento do aluno em uma aula, como a tela "Meus agendamentos" espera.
///
/// ATENÇÃO: as chaves usadas no `fromJson` (id, aulaId, horarioInicio,
/// horarioFim, modalidade, tipo, professor, vagasOcupadas, vagasTotais, aviso)
/// são uma suposição. Ajuste para os nomes reais que o backend devolve.
class Agendamento {
  final String id;

  /// Aula à qual este agendamento pertence.
  final String aulaId;
  final String horarioInicio; // ex.: "07:00"
  final String horarioFim; // ex.: "08:00"
  final String modalidade;
  final String tipo;
  final String professor;
  final int vagasOcupadas;
  final int vagasTotais;

  /// Mensagem opcional mostrada no card (ex.: prazo para cancelar).
  final String? aviso;

  const Agendamento({
    required this.id,
    required this.aulaId,
    required this.horarioInicio,
    required this.horarioFim,
    required this.modalidade,
    required this.tipo,
    required this.professor,
    required this.vagasOcupadas,
    required this.vagasTotais,
    this.aviso,
  });

  /// Ex.: "07:00 - 08:00".
  String get horario => '$horarioInicio - $horarioFim';

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    return Agendamento(
      id: json['id'].toString(),
      aulaId: json['aulaId'].toString(),
      horarioInicio: json['horarioInicio'] as String,
      horarioFim: json['horarioFim'] as String,
      modalidade: json['modalidade'] as String,
      tipo: (json['tipo'] as String?) ?? 'Em grupo',
      professor: json['professor'] as String,
      vagasOcupadas: (json['vagasOcupadas'] as num).toInt(),
      vagasTotais: (json['vagasTotais'] as num).toInt(),
      aviso: json['aviso'] as String?,
    );
  }
}
