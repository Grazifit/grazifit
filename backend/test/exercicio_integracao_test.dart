@Timeout(Duration(minutes: 2))
library;

import 'dart:convert';

import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/exercicios/exercicio_controller.dart';
import 'package:grazifit_backend/features/exercicios/exercicio_repository.dart';
import 'package:grazifit_backend/features/exercicios/exercicio_service.dart';
import 'package:grazifit_backend/shared/autorizacao/identidade.dart';
import 'package:grazifit_backend/shared/middleware/identidade_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// Integracao contra o PostgreSQL REAL (repository + service + controller).
/// Sem mock de banco: a unicidade do nome e a FK `RESTRICT` de
/// `treino_exercicio` so existem no banco.
///
///     docker compose up -d banco && ./database/aplicar.sh
///     cd backend && dart test test/exercicio_integracao_test.dart
///
/// Exige `DATABASE_URL` no ambiente do processo. Dados ficticios apenas:
/// nomes com o prefixo [_prefixo] e admin `@exemplo.test`.
void main() {
  late GraziDatabase db;
  late ExercicioController controller;
  late Identidade admin;

  const aluno = Identidade(id: 1, papel: Papel.aluno);
  const professor = Identidade(id: 1, papel: Papel.professor);

  const emailAdmin = 'exercicio.integracao@exemplo.test';

  Future<void> limpar() async {
    await db.customStatement(
      "DELETE FROM treino WHERE nome LIKE '$_prefixo%'",
    );
    await db.customStatement(
      "DELETE FROM exercicio WHERE nome LIKE '$_prefixo%'",
    );
    await db.customStatement("DELETE FROM admin WHERE email = '$emailAdmin'");
  }

  setUpAll(() async {
    db = GraziDatabase.doAmbiente();
    try {
      await db.customSelect('SELECT 1').getSingle();
    } catch (e) {
      fail(
        'nao foi possivel conectar ao Postgres.\n'
        'rode antes:  docker compose up -d banco\n'
        'e confira a DATABASE_URL no ambiente deste processo.\n'
        'erro: $e',
      );
    }
    await limpar();

    final idAdmin = await db
        .customSelect(
          'INSERT INTO admin (cpf, senha_hash, nome, email) '
          "VALUES ('11144477735', 'hash-integracao', 'Admin Exercicio', "
          "'$emailAdmin') RETURNING id_admin",
        )
        .getSingle();
    admin = Identidade(id: idAdmin.read<int>('id_admin'), papel: Papel.admin);

    controller = ExercicioController(
      ExercicioService(ExercicioRepository(db)),
    );
  });

  tearDownAll(() async {
    await limpar();
    await db.close();
  });

  var contador = 0;
  String nomeNovo() => '$_prefixo ${++contador} ${DateTime.now().microsecondsSinceEpoch}';

  Future<Response> chamar(
    String metodo,
    String caminho, {
    Identidade? identidade,
    Object? corpo,
  }) {
    return controller.router.call(
      Request(
        metodo,
        Uri.parse('http://localhost$caminho'),
        body: corpo == null ? null : jsonEncode(corpo),
        headers: {'Content-Type': 'application/json'},
        context: {chaveIdentidadeContexto: identidade ?? admin},
      ),
    );
  }

  Future<Map<String, dynamic>> json(Response r) async =>
      jsonDecode(await r.readAsString()) as Map<String, dynamic>;

  Future<void> esperaErro(
    Response r,
    int status,
    String codigo, {
    String? campo,
  }) async {
    expect(r.statusCode, status);
    final corpo = await json(r);
    expect(corpo['codigo'], codigo);
    expect(corpo['campo'], campo);
  }

  /// Cria via API como admin e devolve o JSON de resposta.
  Future<Map<String, dynamic>> criar({String? nome, Object? extra}) async {
    final r = await chamar(
      'POST',
      '/exercicio',
      corpo: {
        'nome': nome ?? nomeNovo(),
        'instrucoes': 'Execute com postura correta.',
        ...?(extra as Map<String, dynamic>?),
      },
    );
    expect(r.statusCode, 201);
    return json(r);
  }

  group('criar', () {
    test('201 com defaults, descricao em branco vira null', () async {
      final nome = nomeNovo();
      final r = await chamar(
        'POST',
        '/exercicio',
        corpo: {'nome': ' $nome ', 'instrucoes': 'Passos', 'descricao': '   '},
      );
      expect(r.statusCode, 201);
      final corpo = await json(r);
      expect(corpo['nome'], nome);
      expect(corpo['descricao'], isNull);
      expect(corpo['dificuldade'], 'iniciante');
      expect(corpo['id_exercicio'], isA<int>());

      final linha = await db
          .customSelect(
            'SELECT id_admin_criador FROM exercicio WHERE id_exercicio = '
            '${corpo['id_exercicio']}',
          )
          .getSingle();
      expect(linha.read<int>('id_admin_criador'), admin.id);
    });

    test('nome duplicado -> 409 NOME_EM_USO', () async {
      final nome = nomeNovo();
      await criar(nome: nome);
      await esperaErro(
        await chamar(
          'POST',
          '/exercicio',
          corpo: {'nome': nome, 'instrucoes': 'x'},
        ),
        409,
        'NOME_EM_USO',
        campo: 'nome',
      );
    });

    test('dificuldade fora da lista -> 400 CAMPO_INVALIDO', () async {
      await esperaErro(
        await chamar(
          'POST',
          '/exercicio',
          corpo: {
            'nome': nomeNovo(),
            'instrucoes': 'x',
            'dificuldade': 'impossivel',
          },
        ),
        400,
        'CAMPO_INVALIDO',
        campo: 'dificuldade',
      );
    });

    test('nome com mais de 120 caracteres -> 400', () async {
      await esperaErro(
        await chamar(
          'POST',
          '/exercicio',
          corpo: {'nome': 'a' * 121, 'instrucoes': 'x'},
        ),
        400,
        'CAMPO_INVALIDO',
        campo: 'nome',
      );
    });

    test('instrucoes ausente -> 400 CAMPO_OBRIGATORIO', () async {
      await esperaErro(
        await chamar('POST', '/exercicio', corpo: {'nome': nomeNovo()}),
        400,
        'CAMPO_OBRIGATORIO',
        campo: 'instrucoes',
      );
    });
  });

  group('editar', () {
    test('altera so o que veio e aceita manter o proprio nome', () async {
      final criado = await criar();
      final id = criado['id_exercicio'];

      final r = await chamar(
        'PATCH',
        '/exercicio/$id',
        corpo: {'nome': criado['nome'], 'dificuldade': 'avancado'},
      );
      expect(r.statusCode, 200);
      final corpo = await json(r);
      expect(corpo['dificuldade'], 'avancado');
      expect(corpo['instrucoes'], criado['instrucoes']);
    });

    test('nome de outro exercicio -> 409 NOME_EM_USO', () async {
      final a = await criar();
      final b = await criar();
      await esperaErro(
        await chamar(
          'PATCH',
          '/exercicio/${b['id_exercicio']}',
          corpo: {'nome': a['nome']},
        ),
        409,
        'NOME_EM_USO',
        campo: 'nome',
      );
    });

    test('dificuldade fora da lista -> 400 CAMPO_INVALIDO', () async {
      final criado = await criar();
      await esperaErro(
        await chamar(
          'PATCH',
          '/exercicio/${criado['id_exercicio']}',
          corpo: {'dificuldade': 'facil'},
        ),
        400,
        'CAMPO_INVALIDO',
        campo: 'dificuldade',
      );
    });

    test('id inexistente -> 404 REGISTRO_NAO_ENCONTRADO', () async {
      await esperaErro(
        await chamar('PATCH', '/exercicio/999999999', corpo: {'nome': 'x'}),
        404,
        'REGISTRO_NAO_ENCONTRADO',
      );
    });
  });

  group('excluir', () {
    test('sem uso -> 204 e some do banco', () async {
      final criado = await criar();
      final id = criado['id_exercicio'];
      expect((await chamar('DELETE', '/exercicio/$id')).statusCode, 204);
      await esperaErro(
        await chamar('GET', '/exercicio/$id'),
        404,
        'REGISTRO_NAO_ENCONTRADO',
      );
    });

    test('em uso em treino_exercicio -> 409 REGISTRO_EM_USO', () async {
      final criado = await criar();
      final id = criado['id_exercicio'] as int;

      final treino = await db
          .customSelect(
            'INSERT INTO treino (id_admin, nome, tipo) VALUES '
            "(${admin.id}, '$_prefixo treino $id', 'forca') RETURNING id_treino",
          )
          .getSingle();
      await db.customStatement(
        'INSERT INTO treino_exercicio '
        '(id_treino, id_exercicio, ordem, series, repeticoes, carga) VALUES '
        "(${treino.read<int>('id_treino')}, $id, 1, 3, 10, '10kg')",
      );

      await esperaErro(
        await chamar('DELETE', '/exercicio/$id'),
        409,
        'REGISTRO_EM_USO',
      );
      expect((await chamar('GET', '/exercicio/$id')).statusCode, 200);
    });

    test('id inexistente -> 404 REGISTRO_NAO_ENCONTRADO', () async {
      await esperaErro(
        await chamar('DELETE', '/exercicio/999999999'),
        404,
        'REGISTRO_NAO_ENCONTRADO',
      );
    });
  });

  group('listar', () {
    test('default 20/0, ordenado por nome, com total', () async {
      await criar(nome: '$_prefixo ordem B');
      await criar(nome: '$_prefixo ordem A');

      final r = await chamar('GET', '/exercicio');
      expect(r.statusCode, 200);
      final corpo = await json(r);
      expect(corpo['limit'], 20);
      expect(corpo['offset'], 0);
      final nomes = (corpo['itens'] as List)
          .map((e) => (e as Map)['nome'] as String)
          .toList();
      expect(nomes, orderedEquals([...nomes]..sort()));
      expect(corpo['total'], greaterThanOrEqualTo(2));
    });

    test('limit e offset paginam sem repetir item', () async {
      final primeira = await json(
        await chamar('GET', '/exercicio?limit=1&offset=0'),
      );
      final segunda = await json(
        await chamar('GET', '/exercicio?limit=1&offset=1'),
      );
      expect((primeira['itens'] as List), hasLength(1));
      final idPrimeira =
          ((primeira['itens'] as List).single as Map)['id_exercicio'];
      final idSegunda =
          ((segunda['itens'] as List).single as Map)['id_exercicio'];
      expect(idPrimeira, isNot(idSegunda));
    });

    test('fora da faixa -> 400 CAMPO_INVALIDO', () async {
      await esperaErro(
        await chamar('GET', '/exercicio?limit=0'),
        400,
        'CAMPO_INVALIDO',
        campo: 'limit',
      );
      await esperaErro(
        await chamar('GET', '/exercicio?limit=101'),
        400,
        'CAMPO_INVALIDO',
        campo: 'limit',
      );
      await esperaErro(
        await chamar('GET', '/exercicio?offset=-1'),
        400,
        'CAMPO_INVALIDO',
        campo: 'offset',
      );
      expect((await chamar('GET', '/exercicio?limit=100')).statusCode, 200);
    });
  });

  group('RBAC', () {
    for (final (rotulo, quem) in [('aluno', aluno), ('professor', professor)]) {
      test('$rotulo: POST/PATCH/DELETE -> 403, GET -> 200', () async {
        final criado = await criar();
        final id = criado['id_exercicio'];

        await esperaErro(
          await chamar(
            'POST',
            '/exercicio',
            identidade: quem,
            corpo: {'nome': nomeNovo(), 'instrucoes': 'x'},
          ),
          403,
          'ACESSO_NEGADO',
        );
        await esperaErro(
          await chamar(
            'PATCH',
            '/exercicio/$id',
            identidade: quem,
            corpo: {'nome': nomeNovo()},
          ),
          403,
          'ACESSO_NEGADO',
        );
        await esperaErro(
          await chamar('DELETE', '/exercicio/$id', identidade: quem),
          403,
          'ACESSO_NEGADO',
        );

        expect(
          (await chamar('GET', '/exercicio/$id', identidade: quem)).statusCode,
          200,
        );
        expect(
          (await chamar('GET', '/exercicio', identidade: quem)).statusCode,
          200,
        );
      });
    }
  });
}

const _prefixo = 'Teste Integ Exercicio';
