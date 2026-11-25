/// Aula da lista do Admin (aba "Aulas"), já com textos de exibição.
class AulaListaAdminData {
  const AulaListaAdminData({
    required this.id,
    required this.horarioInicio,
    required this.horarioFim,
    required this.modalidade,
    required this.formato,
    required this.vagasOcupadas,
    required this.vagasTotais,
    required this.cancelada,
  });

  final int id;
  final String horarioInicio;
  final String horarioFim;
  final String modalidade;
  final String formato;
  final int vagasOcupadas;
  final int vagasTotais;
  final bool cancelada;

  String get resumoVagas => '$vagasOcupadas de $vagasTotais vagas';
}
