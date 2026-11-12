/// Dados de apresentação da lista de cronogramas do Admin.
///
/// O total vem pronto da camada que fornecer os dados; a tela não recalcula
/// quantos cronogramas estão ativos.
class CronogramasAdminData {
  const CronogramasAdminData({required this.totalAtivos, required this.itens});

  static const vazio = CronogramasAdminData(totalAtivos: 0, itens: []);

  final int totalAtivos;
  final List<CronogramaResumoAdmin> itens;
}

class CronogramaResumoAdmin {
  const CronogramaResumoAdmin({
    required this.id,
    required this.nome,
    required this.resumo,
  });

  final int id;
  final String nome;
  final String resumo;
}

enum CategoriaCronogramaAdmin {
  musculacao('musculacao', 'Musculação'),
  funcional('funcional', 'Funcional'),
  pilates('pilates', 'Pilates'),
  crossfit('crossfit', 'Crossfit'),
  danca('danca', 'Dança'),
  spinning('spinning', 'Spinning');

  const CategoriaCronogramaAdmin(this.codigo, this.rotulo);

  final String codigo;
  final String rotulo;
}

class ProfessorCronogramaOpcao {
  const ProfessorCronogramaOpcao({required this.id, required this.nome});

  final int id;
  final String nome;
}

/// Valores preenchidos no formulário, prontos para serem consumidos por uma
/// camada de estado/repositório quando a integração for feita.
class NovoCronogramaAdmin {
  const NovoCronogramaAdmin({
    required this.professorId,
    required this.categoria,
    required this.dataInicio,
    required this.horaInicio,
    required this.horaFim,
    required this.vagasMaxima,
    required this.diasSemana,
  });

  final int professorId;
  final CategoriaCronogramaAdmin categoria;
  final DateTime dataInicio;
  final String horaInicio;
  final String horaFim;
  final int vagasMaxima;

  /// Convenção do schema: 0 = domingo e 6 = sábado.
  final List<int> diasSemana;
}
