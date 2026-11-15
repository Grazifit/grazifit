/// Estados e dados de apresentação da lista de treinos livres do Admin.
/// A integração fornece os itens; a tela não mantém exemplos locais.
enum EstadoTreinosLivresAdmin { carregando, vazio, erro, semConexao, dados }

class TreinoLivreAdminItem {
  const TreinoLivreAdminItem({
    required this.id,
    required this.nome,
    required this.tipo,
  });

  final int id;
  final String nome;

  /// Tipo do domínio: forca, hipertrofia, resistencia, cardio ou mobilidade.
  final String tipo;

  String get tipoExibicao => switch (tipo) {
        'forca' => 'Força',
        'hipertrofia' => 'Hipertrofia',
        'resistencia' => 'Resistência',
        'cardio' => 'Cardio',
        'mobilidade' => 'Mobilidade',
        _ => tipo,
      };
}
