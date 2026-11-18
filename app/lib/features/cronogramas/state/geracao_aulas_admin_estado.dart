/// Contratos de estado visual para a tela de geração de aulas.
/// A integração de F-19 fornece estes valores; a tela não calcula ocorrências.
enum EstadoGeracaoAulasAdmin {
  periodo,
  carregandoPrevia,
  erroPrevia,
  semConexaoPrevia,
  previa,
  criando,
  erroCriacao,
  semConexaoCriacao,
  resultado,
}

class PeriodoGeracaoAulasAdmin {
  const PeriodoGeracaoAulasAdmin({
    required this.cronogramaId,
    required this.dataInicio,
    required this.dataFim,
  });

  final int cronogramaId;
  final DateTime dataInicio;
  final DateTime dataFim;
}

class PreviaGeracaoAulasAdmin {
  const PreviaGeracaoAulasAdmin({
    required this.periodo,
    required this.quantidadeParaCriar,
    required this.quantidadeJaExistentes,
    required this.aulas,
  });

  final PeriodoGeracaoAulasAdmin periodo;
  final int quantidadeParaCriar;
  final int quantidadeJaExistentes;
  final List<ItemAulaGeracaoAdmin> aulas;
}

class ResultadoGeracaoAulasAdmin {
  const ResultadoGeracaoAulasAdmin({
    required this.periodo,
    required this.quantidadeCriadas,
    required this.quantidadeJaExistentes,
    required this.aulas,
  });

  final PeriodoGeracaoAulasAdmin periodo;
  final int quantidadeCriadas;
  final int quantidadeJaExistentes;
  final List<ItemAulaGeracaoAdmin> aulas;
}

/// Dados que a camada de integração precisa para confirmar a geração.
class ConfirmacaoGeracaoAulasAdmin {
  const ConfirmacaoGeracaoAulasAdmin({
    required this.periodo,
    required this.previa,
  });

  final PeriodoGeracaoAulasAdmin periodo;
  final PreviaGeracaoAulasAdmin previa;
}

class ItemAulaGeracaoAdmin {
  const ItemAulaGeracaoAdmin({
    required this.dataLegivel,
    required this.horario,
    required this.jaExistia,
  });

  final String dataLegivel;
  final String horario;
  final bool jaExistia;
}
