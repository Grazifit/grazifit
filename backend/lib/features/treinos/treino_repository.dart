import 'package:drift/drift.dart' show Variable;

import '../../database/database.dart';

/// Treino livre (do sistema): `treino.id_admin` preenchido, sem aluno nem
/// professor.
class TreinoLivre {
  const TreinoLivre({
    required this.idTreino,
    required this.nome,
    required this.tipo,
  });

  final int idTreino;
  final String nome;
  final String tipo;
}

class TreinoRepository {
  TreinoRepository(this._db);

  final GraziDatabase _db;

  Future<List<TreinoLivre>> listarLivres({
    required int limit,
    required int offset,
  }) async {
    final linhas = await _db
        .customSelect(
          '''
      SELECT id_treino, nome, tipo
        FROM treino
       WHERE id_admin IS NOT NULL
       ORDER BY nome, id_treino
       LIMIT \$1 OFFSET \$2
    ''',
          variables: [Variable.withInt(limit), Variable.withInt(offset)],
        )
        .get();
    return linhas
        .map(
          (l) => TreinoLivre(
            idTreino: l.read<int>('id_treino'),
            nome: l.read<String>('nome'),
            tipo: l.read<String>('tipo'),
          ),
        )
        .toList();
  }

  Future<int> contarLivres() async {
    final linha = await _db
        .customSelect(
          'SELECT COUNT(*)::int AS total FROM treino WHERE id_admin IS NOT NULL',
        )
        .getSingle();
    return linha.read<int>('total');
  }
}
