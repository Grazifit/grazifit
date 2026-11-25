import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/aulas_professor_repository.dart';
import '../../../core/data/repositorios.dart';

final agendaProfessorProvider = FutureProvider.autoDispose<AgendaProfessor>(
  (ref) => Repositorios.aulasProfessor.agendaDoDia(),
);

final detalheAulaProvider =
    FutureProvider.autoDispose.family<AulaProfessorDetalhe, int>(
  (ref, id) => Repositorios.aulasProfessor.detalhe(id),
);
