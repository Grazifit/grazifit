/// Dados e estados de apresentação da biblioteca de exercícios do Admin.
/// A tela não fornece conteúdo de demonstração nem consulta a API.
enum EstadoBibliotecaExerciciosAdmin {
  carregando,
  vazio,
  erro,
  semConexao,
  dados,
}

class ExercicioBibliotecaAdminItem {
  const ExercicioBibliotecaAdminItem({
    required this.id,
    required this.nome,
    required this.dificuldade,
  });

  final int id;
  final String nome;

  /// Valor de domínio: iniciante, intermediario ou avancado.
  final String dificuldade;

  String get dificuldadeExibicao => switch (dificuldade) {
        'iniciante' => 'Iniciante',
        'intermediario' => 'Intermediário',
        'avancado' => 'Avançado',
        _ => dificuldade,
      };
}
