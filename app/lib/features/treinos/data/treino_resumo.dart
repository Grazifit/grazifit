/// Modelos da lista de treinos do aluno, como a tela espera receber.
///
/// ATENÇÃO: as chaves usadas nos `fromJson` (professor, treinosDoProfessor,
/// treinosLivres, id, nome, objetivo) são uma suposição. Ajuste para os nomes
/// reais que o backend devolve.
class TreinoResumo {
  final String id;
  final String nome;
  final String objetivo;

  const TreinoResumo({
    required this.id,
    required this.nome,
    required this.objetivo,
  });

  factory TreinoResumo.fromJson(Map<String, dynamic> json) {
    return TreinoResumo(
      id: json['id'].toString(),
      nome: json['nome'] as String,
      objetivo: json['objetivo'] as String,
    );
  }
}

class TreinosDoAluno {
  /// Professor que montou os [treinosDoProfessor].
  final String professor;
  final List<TreinoResumo> treinosDoProfessor;
  final List<TreinoResumo> treinosLivres;

  const TreinosDoAluno({
    required this.professor,
    required this.treinosDoProfessor,
    required this.treinosLivres,
  });

  factory TreinosDoAluno.fromJson(Map<String, dynamic> json) {
    List<TreinoResumo> lista(String chave) =>
        ((json[chave] as List<dynamic>?) ?? const [])
            .map((e) => TreinoResumo.fromJson(e as Map<String, dynamic>))
            .toList();

    return TreinosDoAluno(
      professor: json['professor'] as String,
      treinosDoProfessor: lista('treinosDoProfessor'),
      treinosLivres: lista('treinosLivres'),
    );
  }
}
