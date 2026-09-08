@Timeout(Duration(minutes: 2))
library;

import 'package:grazifit_backend/database/database.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';

/// Verificacao obrigatoria da Fase 2 (prompt-fase-2 secao 10).
///
/// Roda contra o PostgreSQL REAL do docker-compose, com o schema aplicado
/// por `database/aplicar.sh`:
///
///     docker compose up -d
///     ./database/aplicar.sh
///     cd backend && DATABASE_URL=... dart test
///
/// A `DATABASE_URL` precisa estar no AMBIENTE do processo: o Dart nao le
/// o `.env` enquanto o `config.dart` da Fase 3 nao existir (D65). Nao ha
/// default — sem ela, `GraziDatabase.doAmbiente()` lanca `StateError`
/// (D65: fail-fast, nenhum default silencioso para segredo).
///
/// Mock aqui nao prova nada: a regra de vagas mora num trigger plpgsql
/// com `FOR UPDATE`, e o IMC e uma coluna gerada pelo banco. Ambos sao
/// invisiveis para qualquer duble (D66).
///
/// Os seis pontos abaixo sustentam D58 e o contrato de erro de D64: sem
/// eles, a secao 7 da arquitetura nao se sustenta.
///
/// Dados ficticios apenas (R5): CPF 000000000NN, dominio @exemplo.test.
void main() {
  late GraziDatabase db;

  // Ids criados pelo setUpAll, removidos pelo tearDownAll.
  late int idProfessor;
  late int idAlunoUm;
  late int idAlunoDois;
  late int idAula;

  /// Le um unico valor escalar do banco.
  Future<Object?> escalar(String sql) async {
    final linha = await db.customSelect(sql).getSingle();
    return linha.data.values.first;
  }

  /// Executa e devolve a `ServerException` que o Postgres levantou.
  ///
  /// E este objeto que sustenta D64: `code` carrega o SQLSTATE e
  /// `constraintName` carrega o nome da constraint violada. Sao eles que
  /// o tradutor unico do `error_handler` vai consultar na Fase 3 —
  /// nunca a string da mensagem.
  Future<pg.ServerException> capturarErro(String sql) async {
    try {
      await db.customStatement(sql);
    } on pg.ServerException catch (e) {
      return e;
    }
    fail('esperava ServerException, mas o comando passou: $sql');
  }

  setUpAll(() async {
    db = GraziDatabase.doAmbiente();

    // Falha cedo e com mensagem util se o banco nao estiver preparado.
    try {
      await escalar('SELECT 1');
    } catch (e) {
      fail(
        'nao foi possivel conectar ao Postgres.\n'
        'rode antes:  docker compose up -d  &&  ./database/aplicar.sh\n'
        'e confira a DATABASE_URL no ambiente deste processo.\n'
        'erro: $e',
      );
    }

    idProfessor = await escalar('''
      INSERT INTO professor (cpf, senha_hash, nome, telefone, email)
      VALUES ('00000000010', 'hash-ficticio',
              'Professor Teste', '11900000000', 'professor@exemplo.test')
      RETURNING id_professor
    ''') as int;

    idAlunoUm = await escalar('''
      INSERT INTO aluno (cpf, senha_hash, nome, data_nascimento,
                         telefone, email)
      VALUES ('00000000011', 'hash-ficticio', 'Aluno Um',
              DATE '1990-01-01', '11900000001', 'aluno.um@exemplo.test')
      RETURNING id_aluno
    ''') as int;

    idAlunoDois = await escalar('''
      INSERT INTO aluno (cpf, senha_hash, nome, data_nascimento,
                         telefone, email)
      VALUES ('00000000012', 'hash-ficticio', 'Aluno Dois',
              DATE '1992-02-02', '11900000002', 'aluno.dois@exemplo.test')
      RETURNING id_aluno
    ''') as int;

    // Aula com UMA vaga — e o que torna o ponto 4 verificavel.
    idAula = await escalar('''
      INSERT INTO aula (id_professor, data, hora_inicio, hora_fim,
                        tipo, categoria, vagas_maxima)
      VALUES ($idProfessor, CURRENT_DATE + 1, TIME '08:00', TIME '09:00',
              'coletiva', 'funcional', 1)
      RETURNING id_aula
    ''') as int;
  });

  tearDownAll(() async {
    // Ordem inversa das FKs — varias sao ON DELETE RESTRICT.
    await db.customStatement('DELETE FROM agendamento WHERE id_aula = $idAula');
    await db.customStatement('DELETE FROM aula WHERE id_aula = $idAula');
    await db.customStatement(
      'DELETE FROM avaliacao WHERE id_aluno IN ($idAlunoUm, $idAlunoDois)',
    );
    await db.customStatement(
      'DELETE FROM aluno WHERE id_aluno IN ($idAlunoUm, $idAlunoDois)',
    );
    await db.customStatement(
      'DELETE FROM professor WHERE id_professor = $idProfessor',
    );
    await db.close();
  });

  // ==========================================================
  test('1. o schema aplicado tem as 14 tabelas de dominio', () async {
    final total = await escalar('''
      SELECT count(*) FROM information_schema.tables
       WHERE table_schema = 'public'
         AND table_type   = 'BASE TABLE'
         AND table_name  <> 'schema_migracao'
    ''');

    // schema_migracao e infraestrutura do aplicar.sh, nao dominio.
    expect(total, 14);
  });

  // ==========================================================
  test('2. o IMC e calculado pelo banco, nunca em Dart (RF-03)', () async {
    await db.customStatement('''
      INSERT INTO avaliacao (id_aluno, data_avaliacao, peso, altura)
      VALUES ($idAlunoUm, CURRENT_DATE, 70, 1.75)
    ''');

    final imc = await escalar('''
      SELECT imc FROM avaliacao
       WHERE id_aluno = $idAlunoUm AND data_avaliacao = CURRENT_DATE
    ''');

    // 70 / (1.75 * 1.75) = 22.857... arredondado a NUMERIC(5,2).
    // Chega como String: NUMERIC nunca vira double (arquitetura 1.1).
    expect(imc, isA<String>(), reason: 'NUMERIC deve chegar como String');
    expect(imc, '22.86');
  });

  // ==========================================================
  test('3. as duas views respondem', () async {
    final ocupacao = await db
        .customSelect('SELECT * FROM vw_aula_ocupacao WHERE id_aula = $idAula')
        .getSingle();

    expect(ocupacao.data['vagas_maxima'], 1);
    expect(ocupacao.data['vagas_ocupadas'], 0);
    expect(ocupacao.data['vagas_livres'], 1);

    final medida = await db
        .customSelect(
          'SELECT * FROM vw_aluno_medida_atual WHERE id_aluno = $idAlunoUm',
        )
        .getSingle();

    // A view expoe a avaliacao mais recente do aluno — inclusive o IMC.
    expect(medida.data['imc'], '22.86');
  });

  // ==========================================================
  test('4. aula lotada devolve SQLSTATE GF001 (D64)', () async {
    // Primeiro agendamento ocupa a unica vaga.
    await db.customStatement('''
      INSERT INTO agendamento (id_aluno, id_aula)
      VALUES ($idAlunoUm, $idAula)
    ''');

    // Segundo aluno encontra a aula lotada.
    final erro = await capturarErro('''
      INSERT INTO agendamento (id_aluno, id_aula)
      VALUES ($idAlunoDois, $idAula)
    ''');

    // GF001 e levantado por fn_valida_vagas_aula, que roda com FOR UPDATE.
    // Sem o ERRCODE proprio isto voltaria como P0001, indistinguivel de
    // "aula inativa" (arquitetura 7.2) — e o contrato de erro cairia.
    expect(erro.code, 'GF001');

    // A ocupacao passou a refletir a vaga tomada.
    final livres = await escalar(
      'SELECT vagas_livres FROM vw_aula_ocupacao WHERE id_aula = $idAula',
    );
    expect(livres, 0);
  });

  // ==========================================================
  test('5. CPF duplicado devolve 23505 com o nome da constraint', () async {
    final erro = await capturarErro('''
      INSERT INTO aluno (cpf, senha_hash, nome, data_nascimento,
                         telefone, email)
      VALUES ('00000000011', 'hash-ficticio', 'Aluno Repetido',
              DATE '1995-05-05', '11900000003', 'aluno.tres@exemplo.test')
    ''');

    expect(erro.code, '23505');

    // O NOME da constraint e a chave do mapeamento de D64 — e estavel,
    // enquanto a mensagem do Postgres nao e.
    expect(erro.constraintName, 'uq_aluno_cpf');
  });

  // ==========================================================
  test('6. CPF fora do formato devolve 23514 em dom_cpf_check', () async {
    final erro = await capturarErro('''
      INSERT INTO aluno (cpf, senha_hash, nome, data_nascimento,
                         telefone, email)
      VALUES ('123', 'hash-ficticio', 'Aluno Invalido',
              DATE '1995-05-05', '11900000004', 'aluno.quatro@exemplo.test')
    ''');

    // Violacao de DOMAIN nao e 23505: e 23514 (check_violation).
    // Entra no mapa de D64 como CPF_INVALIDO (arquitetura 7.3).
    expect(erro.code, '23514');
    expect(erro.constraintName, 'dom_cpf_check');
  });
}
