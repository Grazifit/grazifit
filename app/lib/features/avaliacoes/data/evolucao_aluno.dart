/// Modelos da tela de evolução do aluno, como ela espera receber.
///
/// ATENÇÃO: as chaves usadas nos `fromJson` (alturaM, medidas, data, peso)
/// são uma suposição. Ajuste para os nomes reais que o backend devolve.
class MedidaPeso {
  final DateTime data;

  /// Peso em kg.
  final double peso;

  const MedidaPeso({required this.data, required this.peso});

  factory MedidaPeso.fromJson(Map<String, dynamic> json) {
    return MedidaPeso(
      // Espera data em ISO 8601 (ex.: "2026-07-15" ou "2026-07-15T10:00:00Z").
      data: DateTime.parse(json['data'] as String),
      peso: (json['peso'] as num).toDouble(),
    );
  }
}

class EvolucaoAluno {
  /// Altura da última avaliação, em metros. Usada para calcular o IMC.
  final double alturaM;

  /// Histórico de medidas de peso.
  final List<MedidaPeso> medidas;

  const EvolucaoAluno({required this.alturaM, required this.medidas});

  factory EvolucaoAluno.fromJson(Map<String, dynamic> json) {
    return EvolucaoAluno(
      alturaM: (json['alturaM'] as num).toDouble(),
      medidas: ((json['medidas'] as List<dynamic>?) ?? const [])
          .map((e) => MedidaPeso.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
