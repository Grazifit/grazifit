/// Modelos da agenda do aluno, como a tela espera receber.
///
/// ATENÇÃO: as chaves usadas nos `fromJson` (id, nome, horarioInicio,
/// horarioFim, modalidade, tipo, professor, vagasOcupadas, vagasTotais) são uma
/// suposição. Ajuste para os nomes reais que o backend devolve.

enum StatusAula { normal, ultimasVagas, lotada }

class Modalidade {
  final String id;
  final String nome;

  const Modalidade({required this.id, required this.nome});

  factory Modalidade.fromJson(Map<String, dynamic> json) {
    return Modalidade(
      id: json['id'].toString(),
      nome: json['nome'] as String,
    );
  }
}

class Aula {
  final String id;
  final String horarioInicio; // ex.: "07:00"
  final String horarioFim; // ex.: "08:00"

  /// Nome da modalidade. É comparado com [Modalidade.nome] no filtro da tela.
  final String modalidade;

  /// Ex.: "Em grupo".
  final String tipo;
  final String professor;
  final int vagasOcupadas;
  final int vagasTotais;

  const Aula({
    required this.id,
    required this.horarioInicio,
    required this.horarioFim,
    required this.modalidade,
    required this.tipo,
    required this.professor,
    required this.vagasOcupadas,
    required this.vagasTotais,
  });

  /// Com quantas vagas restantes ou menos a aula aparece como "Últimas vagas".
  static const int limiteUltimasVagas = 1;

  int get vagasRestantes => vagasTotais - vagasOcupadas;

  /// Calculado a partir das vagas, não vem do backend.
  StatusAula get status {
    if (vagasRestantes <= 0) return StatusAula.lotada;
    if (vagasRestantes <= limiteUltimasVagas) return StatusAula.ultimasVagas;
    return StatusAula.normal;
  }

  factory Aula.fromJson(Map<String, dynamic> json) {
    return Aula(
      id: json['id'].toString(),
      horarioInicio: json['horarioInicio'] as String,
      horarioFim: json['horarioFim'] as String,
      modalidade: json['modalidade'] as String,
      tipo: (json['tipo'] as String?) ?? 'Em grupo',
      professor: json['professor'] as String,
      vagasOcupadas: (json['vagasOcupadas'] as num).toInt(),
      vagasTotais: (json['vagasTotais'] as num).toInt(),
    );
  }
}