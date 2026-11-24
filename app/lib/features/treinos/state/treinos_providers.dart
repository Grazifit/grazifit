import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repositorios.dart';
import '../data/treinos_professor_repository.dart';

// Visão do professor. Os providers só repassam para `Repositorios`.

final treinosDoAlunoProvider =
    FutureProvider.autoDispose.family<List<TreinoDoAluno>, int>(
  (ref, idAluno) => Repositorios.treinosProfessor.listarDoAluno(idAluno),
);

final historicoAlunoProvider =
    FutureProvider.autoDispose.family<HistoricoAluno, int>(
  (ref, idAluno) => Repositorios.treinosProfessor.historico(idAluno),
);
