enum Papel { aluno, professor, admin }

class Identidade {
  final int id;
  final Papel papel;

  const Identidade({required this.id, required this.papel});
}

class AcessoNegado implements Exception {
  const AcessoNegado();
}

void exigirAdmin(Identidade identidade) {
  if (identidade.papel != Papel.admin) throw const AcessoNegado();
}
