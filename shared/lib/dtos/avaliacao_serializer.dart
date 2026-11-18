/// Medidas em kg e metros; IMC e data sao devolvidos pelo banco.
class AvaliacaoDto {
  const AvaliacaoDto({
    required this.idAvaliacao,
    required this.idAluno,
    required this.dataAvaliacao,
    required this.peso,
    required this.altura,
    required this.imc,
    this.observacao,
  });
  final int idAvaliacao;
  final int idAluno;
  final String dataAvaliacao;
  final double peso;
  final double altura;
  final double imc;
  final String? observacao;

  Map<String, dynamic> toJson() => {
    'id_avaliacao': idAvaliacao,
    'id_aluno': idAluno,
    'data_avaliacao': dataAvaliacao,
    'peso': peso,
    'altura': altura,
    'imc': imc,
    'observacao': observacao,
  };
}
