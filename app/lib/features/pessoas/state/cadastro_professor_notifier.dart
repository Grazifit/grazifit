import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/professor_repository.dart';
import '../../../core/data/repositorios.dart';

/// Estado do envio do cadastro. `AsyncValue.data(null)` = ocioso;
/// `data(Professor)` = criado; `loading` e `error` (com [ApiException]).
class CadastroProfessorNotifier extends AutoDisposeNotifier<AsyncValue<Professor?>> {
  @override
  AsyncValue<Professor?> build() => const AsyncValue.data(null);

  Future<void> salvar({
    required String nome,
    required String cpf,
    required String email,
    required String senha,
    required String telefone,
    Map<String, dynamic>? endereco,
  }) async {
    if (state.isLoading) return;
    state = const AsyncValue.loading();
    try {
      final professor = await Repositorios.professores.criar(
            nome: nome,
            cpf: cpf,
            email: email,
            senha: senha,
            telefone: telefone,
            endereco: endereco,
          );
      state = AsyncValue.data(professor);
    } on ApiException catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final cadastroProfessorProvider =
    NotifierProvider.autoDispose<CadastroProfessorNotifier, AsyncValue<Professor?>>(
  CadastroProfessorNotifier.new,
);
