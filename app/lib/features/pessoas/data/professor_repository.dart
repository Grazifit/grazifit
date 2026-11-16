import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

/// Professor como o backend o devolve (`professorToPublicJson`).
class Professor {
  const Professor({
    required this.idProfessor,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.status,
  });

  factory Professor.fromJson(Map<String, dynamic> json) => Professor(
        idProfessor: json['id_professor'] as int,
        nome: json['nome'] as String,
        email: json['email'] as String,
        telefone: json['telefone'] as String,
        status: json['status'] as bool,
      );

  final int idProfessor;
  final String nome;
  final String email;
  final String telefone;
  final bool status;
}

final professorRepositoryProvider = Provider<ProfessorRepository>(
  (ref) => ProfessorRepository(ref.watch(apiClientProvider)),
);

class ProfessorRepository {
  const ProfessorRepository(this._api);

  final ApiClient _api;

  Future<Professor> criar({
    required String nome,
    required String cpf,
    required String email,
    required String senha,
    required String telefone,
  }) async {
    final json = await _api.post('/professor', {
      'nome': nome.trim(),
      'cpf': cpf,
      'email': email.trim(),
      'senha': senha,
      'telefone': telefone,
    });
    return Professor.fromJson(json);
  }
}
