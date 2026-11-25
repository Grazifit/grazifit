import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/vinculos_repository.dart';
import '../../../core/data/repositorios.dart';

final alunosAtivosProvider = FutureProvider.autoDispose<List<AlunoVinculado>>(
  (ref) => Repositorios.vinculos.listarAtivos(),
);

final alunosInativosProvider = FutureProvider.autoDispose<List<AlunoInativo>>(
  (ref) => Repositorios.vinculos.listarInativos(),
);

/// Detalhe do aluno por id. Também serve de fonte do **nome** nas telas
/// filhas (treinos, histórico, avaliação, montar treino).
final alunoDetalheProvider =
    FutureProvider.autoDispose.family<AlunoDetalhe, int>(
  (ref, id) => Repositorios.vinculos.detalhe(id),
);
