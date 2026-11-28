import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repositorios.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/state/cache_temporario.dart';
import '../../auth/state/auth_controller.dart';
import '../data/treinos_professor_repository.dart';

// Visão do professor. Os providers só repassam para `Repositorios`.

final treinosDoAlunoProvider = FutureProvider.autoDispose
    .family<List<TreinoDoAluno>, int>((ref, idAluno) {
      final sessao = ref.watch(authControllerProvider).sessao;
      if (sessao == null) throw const ApiException(statusCode: 401);
      return carregarComCacheTemporario(
        ref,
        () => Repositorios.treinosProfessor.listarDoAluno(idAluno),
      );
    });

final historicoAlunoProvider = FutureProvider.autoDispose
    .family<HistoricoAluno, int>(
      (ref, idAluno) => Repositorios.treinosProfessor.historico(idAluno),
    );
