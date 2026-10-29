/// Dados de apresentação do painel inicial administrativo.
///
/// O construtor recebe os dados de fora da tela para permitir a futura ligação
/// com o provider/API sem acoplar a interface a uma origem de dados.
class InicioAdminData {
  const InicioAdminData({
    required this.dataLegivel,
    required this.aulasHoje,
    required this.ocupacaoPercentual,
    required this.pessoasInativas,
    required this.aulas,
  });

  /// Conteúdo fictício baseado no protótipo visual enviado.
  static const exemplo = InicioAdminData(
    dataLegivel: 'Segunda, 01 de setembro',
    aulasHoje: 6,
    ocupacaoPercentual: 78,
    pessoasInativas: 3,
    aulas: [
      AulaAdminData(
        horarioInicio: '07:00',
        horarioFim: '08:00',
        modalidade: 'Funcional',
        formato: 'Em grupo',
        professor: 'Prof. Marina Alves',
        vagasOcupadas: 8,
        vagasTotais: 12,
      ),
      AulaAdminData(
        horarioInicio: '09:00',
        horarioFim: '10:00',
        modalidade: 'Funcional',
        formato: 'Em grupo',
        professor: 'Prof. Marina Alves',
        vagasOcupadas: 11,
        vagasTotais: 12,
        destaqueVagas: 'Últimas vagas',
      ),
    ],
  );

  final String dataLegivel;
  final int aulasHoje;
  final int ocupacaoPercentual;
  final int pessoasInativas;
  final List<AulaAdminData> aulas;
}

/// Resumo de aula usado pela tela inicial. Valores e destaque são informados
/// pela origem dos dados; a interface não decide regras de lotação.
class AulaAdminData {
  const AulaAdminData({
    required this.horarioInicio,
    required this.horarioFim,
    required this.modalidade,
    required this.formato,
    required this.professor,
    required this.vagasOcupadas,
    required this.vagasTotais,
    this.destaqueVagas,
  });

  final String horarioInicio;
  final String horarioFim;
  final String modalidade;
  final String formato;
  final String professor;
  final int vagasOcupadas;
  final int vagasTotais;
  final String? destaqueVagas;

  String get resumoVagas => '$vagasOcupadas de $vagasTotais vagas';
}
