import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repositorios.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/state/auth_controller.dart';
import '../data/professor_repository.dart';

/// Perfil do professor logado. Depois de editar: `ref.invalidate(...)`.
final perfilProfessorProvider = FutureProvider.autoDispose<Professor>((ref) {
  final id = ref.watch(authControllerProvider).sessao?.id;
  if (id == null) throw const ApiException(statusCode: 401);
  return Repositorios.professores.buscar(id);
});
