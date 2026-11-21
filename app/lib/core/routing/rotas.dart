/// Caminhos das rotas de topo. As telas internas continuam abrindo por
/// `Navigator.push`; o GoRouter cuida do login, do destino de cada papel e do
/// guard.
abstract final class Rotas {
  static const login = '/login';
  static const aluno = '/aluno';
  static const professor = '/professor';
  static const admin = '/admin';

  /// Catálogo de telas para desenvolvimento.
  static const dev = '/dev';

  /// Tela inicial de cada papel (`aluno`, `professor`, `admin`).
  static String? inicioDe(String papel) => switch (papel) {
        'aluno' => aluno,
        'professor' => professor,
        'admin' => admin,
        _ => null,
      };
}
