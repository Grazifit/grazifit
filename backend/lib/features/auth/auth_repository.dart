import 'package:drift/drift.dart';

import '../../database/database.dart';
import '../../shared/autorizacao/identidade.dart';
import 'token_service.dart';

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

  Future<void> registrarSessao(
    TokenEmitido token,
    Identidade identidade,
  ) async {
    await _db.customStatement(
      r'''
      INSERT INTO sessao_auth (jti_hash, papel, id_usuario, expira_em)
      VALUES ($1, $2, $3, $4)
      ''',
      [token.jtiHash, identidade.papel.name, identidade.id, token.expiraEm],
    );
  }

  Future<bool> sessaoAtiva(TokenValidado token) async {
    final linha = await _db
        .customSelect(
          r'''
          SELECT 1
            FROM sessao_auth
           WHERE jti_hash = $1
             AND papel = $2
             AND id_usuario = $3
             AND expira_em = $4
             AND revogada_em IS NULL
             AND expira_em > now()
           LIMIT 1
          ''',
          variables: [
            Variable.withString(token.jtiHash),
            Variable.withString(token.identidade.papel.name),
            Variable.withInt(token.identidade.id),
            Variable<DateTime>(token.expiraEm),
          ],
        )
        .getSingleOrNull();
    return linha != null;
  }

  Future<bool> revogarSessao(TokenValidado token) async {
    final alteradas = await _db.customUpdate(
      r'''
      UPDATE sessao_auth
         SET revogada_em = now()
       WHERE jti_hash = $1
         AND papel = $2
         AND id_usuario = $3
         AND revogada_em IS NULL
      ''',
      variables: [
        Variable.withString(token.jtiHash),
        Variable.withString(token.identidade.papel.name),
        Variable.withInt(token.identidade.id),
      ],
    );
    return alteradas == 1;
  }

  Future<void> limparSessoesExpiradas() async {
    await _db.customStatement(
      'DELETE FROM sessao_auth WHERE expira_em <= now()',
    );
  }
}
