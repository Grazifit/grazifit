import 'package:drift/drift.dart';

import '../../database/database.dart';
import '../../shared/autorizacao/identidade.dart';

class ContaAutenticacao {
  final Identidade identidade;
  final String nome;
  final String senhaHash;
  final bool ativa;

  const ContaAutenticacao({
    required this.identidade,
    required this.nome,
    required this.senhaHash,
    required this.ativa,
  });
}

/// Somente leitura das tabelas de pessoas. A feature auth nao possui tabelas.
class AuthRepository {
  final GraziDatabase _db;

  AuthRepository(this._db);

  /// Retorna ate duas contas para detectar e-mail repetido entre perfis.
  /// A unicidade entre as tres tabelas ainda nao e garantida pelo schema.
  Future<List<ContaAutenticacao>> buscarPorEmail(String email) async {
    final linhas = await _db
        .customSelect(
          r'''
      SELECT id, papel, nome, senha_hash, ativa FROM (
        SELECT id_admin AS id, 'admin'::text AS papel, nome,
               senha_hash, TRUE AS ativa
          FROM admin WHERE lower(email::text) = $1
        UNION ALL
        SELECT id_professor AS id, 'professor'::text AS papel, nome,
               senha_hash, status AS ativa
          FROM professor WHERE lower(email::text) = $2
        UNION ALL
        SELECT id_aluno AS id, 'aluno'::text AS papel, nome,
               senha_hash, status AS ativa
          FROM aluno WHERE lower(email::text) = $3
      ) AS contas
      LIMIT 2
    ''',
          variables: [
            Variable.withString(email),
            Variable.withString(email),
            Variable.withString(email),
          ],
        )
        .get();

    return linhas.map((linha) {
      final papel = Papel.values.byName(linha.read<String>('papel'));
      return ContaAutenticacao(
        identidade: Identidade(id: linha.read<int>('id'), papel: papel),
        nome: linha.read<String>('nome'),
        senhaHash: linha.read<String>('senha_hash'),
        ativa: linha.read<bool>('ativa'),
      );
    }).toList();
  }

  /// Revalida existencia e status antes de aceitar um token antigo.
  Future<bool> contaAtiva(Identidade identidade) async {
    final (tabela, colunaId, condicaoStatus) = switch (identidade.papel) {
      Papel.admin => ('admin', 'id_admin', ''),
      Papel.professor => ('professor', 'id_professor', ' AND status = TRUE'),
      Papel.aluno => ('aluno', 'id_aluno', ' AND status = TRUE'),
    };
    final linha = await _db
        .customSelect(
          'SELECT 1 FROM $tabela WHERE $colunaId = \$1$condicaoStatus LIMIT 1',
          variables: [Variable.withInt(identidade.id)],
        )
        .getSingleOrNull();
    return linha != null;
  }
}
