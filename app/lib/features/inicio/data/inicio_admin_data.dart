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

  /// Valor vazio para uso antes da injeção de dados reais.
  static const vazio = InicioAdminData(
    dataLegivel: '',
    aulasHoje: 0,
    ocupacaoPercentual: 0,
    pessoasInativas: 0,
    aulas: [],
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
