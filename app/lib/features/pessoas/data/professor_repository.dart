import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/datas.dart';

/// Professor como o backend o devolve (`professorToPublicJson`).
class Professor {
  const Professor({
    required this.idProfessor,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.status,
    this.cpf,
    this.desde,
  });

  factory Professor.fromJson(Map<String, dynamic> json) => Professor(
        idProfessor: json['id_professor'] as int,
        nome: json['nome'] as String,
        email: json['email'] as String,
        telefone: json['telefone'] as String,
        status: json['status'] as bool,
        // O DTO público ainda não traz cpf nem data_cadastro (lacuna I-3).
        cpf: json['cpf'] as String?,
        desde: Datas.diaMesAno(json['data_cadastro'] as String?),
      );

  final int idProfessor;
  final String nome;
  final String email;
  final String telefone;
  final bool status;
  final String? cpf;

  /// `dd/MM/aaaa`, para "Professora desde".
  final String? desde;
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
    Map<String, dynamic>? endereco,
  }) async {
    final json = await _api.post('/professor', {
      'nome': nome.trim(),
      'cpf': cpf,
      'email': email.trim(),
      'senha': senha,
      'telefone': telefone,
      // TODO(backend): POST /professor ainda não lê `endereco` (só aluno aceita
      // id_endereco). Colunas iguais às da tabela endereco. Ver
      // docs/integracao-frontend.md, lacuna I-2.
      if (endereco != null) 'endereco': endereco,
    });
    return Professor.fromJson(json);
  }

  /// `GET /professor/<id>`. Hoje só admin acessa (lacuna I-1).
  Future<Professor> buscar(int idProfessor) async =>
      Professor.fromJson(await _api.get('/professor/$idProfessor'));

  /// `PATCH /professor/<id>`: nome, email, telefone, senha e status.
  Future<Professor> atualizar(
    int idProfessor, {
    required String nome,
    required String telefone,
  }) async =>
      Professor.fromJson(await _api.patch('/professor/$idProfessor', {
        'nome': nome.trim(),
        'telefone': telefone,
      }));
}
