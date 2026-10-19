@Timeout(Duration(minutes: 2))
library;

import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/shared/erros/tradutor_erro_banco.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:shared/erros/codigo_erro.dart';
import 'package:grazifit_backend/features/pessoas/aluno/aluno_repository.dart';
import 'package:test/test.dart';

void main() {
  late GraziDatabase db;
  late AlunoRepository repositorio;

  var contador = 0;

  /// Insere um aluno descartavel com a data pedida e devolve o que o banco
  /// gravou, no formato `AAAA-MM-DD`.
  Future<String> gravarELer(DateTime dataNascimento) async {
    contador++;
    final linha = await repositorio.create(
      cpf: (90000000000 + contador).toString(),
      senhaHash: 'hash-de-teste',
      nome: 'Aluno Integracao',
      dataNascimento: dataNascimento,
      telefone: '11900000000',
      email: 'integracao$contador@exemplo.test',
    );

    final d = linha.dataNascimento;
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  setUpAll(() async {
    db = GraziDatabase.doAmbiente();
    repositorio = AlunoRepository(db);

    try {
      await db.customSelect('SELECT 1').getSingle();
    } catch (e) {
      fail(
        'nao foi possivel conectar ao Postgres.\n'
        'rode antes:  docker compose up -d\n'
        'e confira a DATABASE_URL no ambiente deste processo.\n'
        'erro: $e',
      );
    }
  });

  tearDownAll(() async {
    await db.customStatement(
      "DELETE FROM aluno WHERE email LIKE '%@exemplo.test'",
    );
    await db.close();
  });

  group('data civil nao desloca — regressao', () {
    // O epoch do tipo `date` do Postgres e 2000-01-01. Antes da correcao,
    // TODA data anterior a ele era gravada um dia depois: o encoder conta
    // dias a partir do epoch usando `PgDate.toDateTime()`, e num fuso a
    // oeste de UTC a meia-noite local deixa um resto de +3h que, em
    // contagem negativa, trunca em direcao ao zero.
    //
    // As duas primeiras sao a fronteira exata. Se a correcao regredir, sao
    // elas que quebram primeiro.
    final casos = <String, DateTime>{
      '1999-12-30': (DateTime(1999, 12, 30)),
      '1999-12-31': (DateTime(1999, 12, 31)),
      '2000-01-01': (DateTime(2000, 1, 1)),
      '2000-01-02': (DateTime(2000, 1, 2)),
      '1995-03-20': (DateTime(1995, 3, 20)),
      '1970-01-01': (DateTime(1970, 1, 1)),
      '1940-06-15': (DateTime(1940, 6, 15)),
      '2024-02-29': (DateTime(2024, 2, 29)),
      '2001-11-02': (DateTime(2001, 11, 2)),
    };

    casos.forEach((esperado, enviado) {
      test('$esperado grava exatamente $esperado', () async {
        expect(await gravarELer(enviado), esperado);
      });
    });

    test('data anterior ao epoch nao ganha um dia', () async {
      // O caso que o defeito produzia: 1995-03-20 virava 1995-03-21.
      expect(await gravarELer(DateTime(1995, 3, 20)), isNot('1995-03-21'));
    });
  });

  group('constraints respondem', () {
    test('CPF duplicado levanta 23505 em uq_aluno_cpf', () async {
      const cpf = '90000000999';
      Future<void> inserir(String email) => repositorio.create(
        cpf: cpf,
        senhaHash: 'hash-de-teste',
        nome: 'Duplicado',
        dataNascimento: DateTime(1990, 5, 5),
        telefone: '11900000000',
        email: email,
      );

      await inserir('dup1@exemplo.test');

      // O repository NAO traduz (D64): a excecao sobe crua, e quem lhe da
      // nome e o tradutor unico, no ponto que conhece HTTP.
      await expectLater(
        () => inserir('dup2@exemplo.test'),
        throwsA(
          isA<Object>().having(
            (e) => (e as dynamic).constraintName,
            'constraintName',
            'uq_aluno_cpf',
          ),
        ),
      );
    });

    test('emailEmUso enxerga e-mail de aluno', () async {
      contador++;
      const email = 'ocupado@exemplo.test';
      await repositorio.create(
        cpf: (90000000000 + contador).toString(),
        senhaHash: 'hash-de-teste',
        nome: 'Ocupa',
        dataNascimento: DateTime(1990, 5, 5),
        telefone: '11900000000',
        email: email,
      );

      expect(await repositorio.emailEmUso(email), isTrue);
      expect(await repositorio.emailEmUso('livre@exemplo.test'), isFalse);
    });

    test('cpfEmUso responde sobre a tabela aluno', () async {
      contador++;
      final cpf = (90000000000 + contador).toString();
      await repositorio.create(
        cpf: cpf,
        senhaHash: 'hash-de-teste',
        nome: 'Ocupa CPF',
        dataNascimento: DateTime(1990, 5, 5),
        telefone: '11900000000',
        email: 'ocupacpf@exemplo.test',
      );

      expect(await repositorio.cpfEmUso(cpf), isTrue);
      expect(await repositorio.cpfEmUso('90000000998'), isFalse);
    });
  });

  group('paginacao — docs/guia-desenvolvimento.md §6, "Listas"', () {
    /// Roda [consultas] numa foto fixa do banco.
    ///
    /// O `dart test` roda os arquivos em paralelo, e outros testes (ex.:
    /// `schema_verificacao_test.dart`) inserem e apagam alunos ao mesmo
    /// tempo. Sem a foto, a contagem e cada pagina veem a tabela em
    /// momentos diferentes e o teste falha sem defeito na paginacao.
    Future<T> numaFotoDoBanco<T>(Future<T> Function() consultas) =>
        db.transaction(() async {
          await db.customStatement(
            'SET TRANSACTION ISOLATION LEVEL REPEATABLE READ',
          );
          return consultas();
        });

    test('paginas nao se sobrepoem nem perdem registro', () async {
      // Todos com o MESMO nome: sem o desempate por id, a ordem entre eles
      // nao e garantida e uma pagina poderia repetir o que a anterior trouxe.
      for (var i = 0; i < 5; i++) {
        contador++;
        await repositorio.create(
          cpf: (90000000000 + contador).toString(),
          senhaHash: 'hash-de-teste',
          nome: 'Aluno Integracao',
          dataNascimento: DateTime(1995, 3, 20),
          telefone: '11900000000',
          email: 'integracao$contador@exemplo.test',
        );
      }

      final (:total, :vistos) = await numaFotoDoBanco(() async {
        final total = await repositorio.countAlunos();
        final vistos = <int>[];
        for (var offset = 0; offset < total; offset += 2) {
          final pagina = await repositorio.buscarAlunos(
            limit: 2,
            offset: offset,
          );
          expect(pagina.length, lessThanOrEqualTo(2));
          vistos.addAll(pagina.map((a) => a.idAluno));
        }
        return (total: total, vistos: vistos);
      });

      expect(vistos.toSet(), hasLength(vistos.length), reason: 'repetido');
      expect(vistos, hasLength(total), reason: 'faltou registro');
    });

    test('offset alem do fim devolve lista vazia', () async {
      final pagina = await numaFotoDoBanco(() async {
        final total = await repositorio.countAlunos();
        return repositorio.buscarAlunos(limit: 20, offset: total + 10);
      });

      expect(pagina, isEmpty);
    });
  });

  group('edicao, status e exclusao', () {
    Future<AlunoData> novoAluno() {
      contador++;
      return repositorio.create(
        cpf: (90000000000 + contador).toString(),
        senhaHash: 'hash-de-teste',
        nome: 'Aluno Integracao',
        dataNascimento: DateTime(1995, 3, 20),
        telefone: '11900000000',
        email: 'integracao$contador@exemplo.test',
      );
    }

    test('atualizar muda so o que veio', () async {
      final aluno = await novoAluno();

      final editado = await repositorio.atualizar(
        aluno.idAluno,
        telefone: '11911112222',
      );

      expect(editado!.telefone, '11911112222');
      expect(editado.nome, aluno.nome);
      expect(editado.email, aluno.email);
    });

    test('atualizar aluno inexistente devolve null', () async {
      expect(await repositorio.atualizar(-1, nome: 'X'), isNull);
    });

    test('emailEmUso ignora o proprio aluno quando pedido', () async {
      final aluno = await novoAluno();

      expect(await repositorio.emailEmUso(aluno.email), isTrue);
      expect(
        await repositorio.emailEmUso(aluno.email, excetoIdAluno: aluno.idAluno),
        isFalse,
      );
    });

    test('alterarStatus inativa e reativa sem apagar', () async {
      final aluno = await novoAluno();

      expect(
        await repositorio.alterarStatus(aluno.idAluno, status: false),
        isTrue,
      );
      expect(
        (await repositorio.buscarAlunoPorId(aluno.idAluno))!.status,
        isFalse,
      );

      expect(
        await repositorio.alterarStatus(aluno.idAluno, status: true),
        isTrue,
      );
      expect(
        (await repositorio.buscarAlunoPorId(aluno.idAluno))!.status,
        isTrue,
      );
    });

    test('excluir sem historico apaga a linha', () async {
      final aluno = await novoAluno();

      expect(await repositorio.excluir(aluno.idAluno), isTrue);
      expect(await repositorio.buscarAlunoPorId(aluno.idAluno), isNull);
      expect(await repositorio.excluir(aluno.idAluno), isFalse);
    });

    test('excluir com historico: banco recusa -> REGISTRO_EM_USO', () async {
      final aluno = await novoAluno();
      await db.customStatement(
        'INSERT INTO avaliacao (id_aluno, peso, altura) VALUES (\$1, 70, 1.75)',
        [aluno.idAluno],
      );

      try {
        await expectLater(
          () => repositorio.excluir(aluno.idAluno),
          throwsA(
            isA<pg.ServerException>()
                .having((e) => e.code, 'code', '23001')
                .having(
                  (e) => traduzirErroBanco(e),
                  'traducao',
                  CodigoErro.registroEmUso,
                ),
          ),
        );
        expect(
          await repositorio.buscarAlunoPorId(aluno.idAluno),
          isNotNull,
          reason: 'a recusa nao pode apagar nada',
        );
      } finally {
        // Sem isto o tearDownAll nao consegue apagar o aluno (RESTRICT).
        await db.customStatement('DELETE FROM avaliacao WHERE id_aluno = \$1', [
          aluno.idAluno,
        ]);
      }
    });
  });
}
