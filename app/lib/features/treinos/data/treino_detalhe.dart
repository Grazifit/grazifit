/// Modelos do detalhe de um treino, como a tela espera receber.
///
/// ATENÇÃO: as chaves usadas nos `fromJson` (id, nome, objetivo, professor,
/// exercicios, series, repeticoes, carga, observacao, descansoSegundos) são
/// uma suposição. Ajuste para os nomes reais que o backend devolve.
class ExercicioTreino {
  final String id;
  final String nome;
  final int series;
  final int repeticoes;

  /// Carga em kg. Nulo para exercícios sem carga (ex.: peso do corpo).
  final double? carga;
  final String? observacao;
  final int? descansoSegundos;

  const ExercicioTreino({
    required this.id,
    required this.nome,
    required this.series,
    required this.repeticoes,
    this.carga,
    this.observacao,
    this.descansoSegundos,
  });

  factory ExercicioTreino.fromJson(Map<String, dynamic> json) {
    return ExercicioTreino(
      id: json['id'].toString(),
      nome: json['nome'] as String,
      series: (json['series'] as num).toInt(),
      repeticoes: (json['repeticoes'] as num).toInt(),
      carga: (json['carga'] as num?)?.toDouble(),
      observacao: json['observacao'] as String?,
      descansoSegundos: (json['descansoSegundos'] as num?)?.toInt(),
    );
  }
}

class TreinoDetalhe {
  final String id;
  final String nome;
  final String objetivo;
  final String professor;
  final List<ExercicioTreino> exercicios;

  const TreinoDetalhe({
    required this.id,
    required this.nome,
    required this.objetivo,
    required this.professor,
    required this.exercicios,
  });

  factory TreinoDetalhe.fromJson(Map<String, dynamic> json) {
    return TreinoDetalhe(
      id: json['id'].toString(),
      nome: json['nome'] as String,
      objetivo: json['objetivo'] as String,
      professor: json['professor'] as String,
      exercicios: (json['exercicios'] as List<dynamic>)
          .map((e) => ExercicioTreino.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}