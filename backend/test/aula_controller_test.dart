import 'dart:convert';

import 'package:drift_postgres/drift_postgres.dart' show PgDate, PgDateTime;
import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/aulas/aula_controller.dart';
import 'package:grazifit_backend/features/aulas/aula_repository.dart';
import 'package:grazifit_backend/features/aulas/aula_service.dart';
import 'package:grazifit_backend/shared/autorizacao/identidade.dart';
import 'package:grazifit_backend/shared/erros/aula_exception.dart';
import 'package:grazifit_backend/shared/middleware/identidade_middleware.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:shared/erros/codigo_erro.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

class _ServicoFalso implements AulaService {
  Object? erro;
  Map<String, Object?>? recebido;

  AulaData get _aula => AulaData(
    idAula: 7,
    idProfessor: 10,
    data: PgDate(year: 2026, month: 6, day: 20),
    horaInicio: pg.Time(7, 5),
    horaFim: pg.Time(8),
    tipo: 'coletiva',
    categoria: 'pilates',
    vagasMaxima: 10,
    status: true,
  );

  Future<AulaData> _responder(Map<String, Object?> args) async {
    recebido = args;
    if (erro != null) throw erro!;
    return _aula;
  }

  @override
  Future<AulaData> criar({
    required Identidade identidade,
    required int idProfessor,
    required DateTime data,
    required Duration horaInicio,
    required Duration horaFim,
    required String tipo,
    required String categoria,
    required int vagasMaxima,
  }) => _responder({
    'idProfessor': idProfessor,
    'data': data,
    'horaInicio': horaInicio,
    'horaFim': horaFim,
    'tipo': tipo,
    'categoria': categoria,
    'vagasMaxima': vagasMaxima,
  });

  @override
  Future<AulaData> buscarPorId(Identidade identidade, int idAula) =>
      _responder({'idAula': idAula});

  @override
  Future<({List<AulaData> itens, int total})> listar(
    Identidade identidade, {
    required int limit,
    required int offset,
    DateTime? data,
    String? categoria,
    int? idProfessor,
  }) async {
    recebido = {
      'limit': limit,
      'offset': offset,
      'data': data,
      'categoria': categoria,
      'idProfessor': idProfessor,
    };
    if (erro != null) throw erro!;
    return (itens: [_aula], total: 41);
  }

  @override
  Future<AulaData> atualizar({
    required Identidade identidade,
    required int idAula,
    int? idProfessor,
    DateTime? data,
    Duration? horaInicio,
    Duration? horaFim,
    String? tipo,
    String? categoria,
    int? vagasMaxima,
  }) => _responder({
    'idAula': idAula,
    'idProfessor': ?idProfessor,
    'data': ?data,
    'horaInicio': ?horaInicio,
    'horaFim': ?horaFim,
    'tipo': ?tipo,
    'categoria': ?categoria,
    'vagasMaxima': ?vagasMaxima,
  });

  /// Aula devolvida pelo cancelamento; `null` usa a aula ativa padrao.
  AulaData? cancelada;

  @override
  Future<AulaData> cancelar({
    required Identidade identidade,
    required int idAula,
  }) async {
    recebido = {'idAula': idAula, 'papel': identidade.papel};
    if (erro != null) throw erro!;
    return cancelada ?? _aula;
  }

  /// Ocupacao por aula devolvida pelo service; ids pedidos a cada chamada.
  Map<int, int> ocupacao = {7: 3};
  final List<List<int>> idsOcupacao = [];

  @override
  Future<Map<int, int>> vagasOcupadas(
    Identidade identidade,
    List<int> idsAulas,
  ) async {
    idsOcupacao.add(idsAulas);
    return {for (final id in idsAulas) id: ocupacao[id] ?? 0};
  }

  List<AgendadoDaAula> agendados = const [
    AgendadoDaAula(
      idAgendamento: 3,
      idAluno: 40,
      nomeAluno: 'Ana',
      status: 'presente',
    ),
    AgendadoDaAula(
      idAgendamento: 1,
      idAluno: 41,
      nomeAluno: 'Bia',
      status: 'agendado',
    ),
  ];

  @override
  Future<({List<AgendadoDaAula> itens, int total})> listarAgendados(
    Identidade identidade,
    int idAula, {
    required int limit,
    required int offset,
  }) async {
    recebido = {
      'idAula': idAula,
      'limit': limit,
      'offset': offset,
      'papel': identidade.papel,
    };
    if (erro != null) throw erro!;
    return (itens: agendados, total: 23);
  }
}

const _admin = Identidade(id: 1, papel: Papel.admin);

final _corpoValido = {
  'id_professor': 10,
  'data': '2026-06-20',
  'hora_inicio': '07:05',
  'hora_fim': '08:00',
  'tipo': 'coletiva',
  'categoria': 'pilates',
  'vagas_maxima': 10,
};

void main() {
  late _ServicoFalso servico;
  late AulaController controller;

  setUp(() {
    servico = _ServicoFalso();
    controller = AulaController(servico);
  });

  Future<(int, Map<String, dynamic>)> chamar(
    String metodo,
    String caminho, {
    Object? corpo,
    Identidade? identidade = _admin,
  }) async {
    final resposta = await controller.router.call(
      Request(
        metodo,
        Uri.parse('http://localhost$caminho'),
        body: corpo == null
            ? null
            : (corpo is String ? corpo : jsonEncode(corpo)),
        context: {chaveIdentidadeContexto: ?identidade},
      ),
    );
    final texto = await resposta.readAsString();
    return (
      resposta.statusCode,
      texto.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(texto) as Map<String, dynamic>,
    );
  }

  void esperaErro(
    (int, Map<String, dynamic>) r,
    int status,
    CodigoErro codigo, [
    String? campo,
  ]) {
    expect(r.$1, status, reason: jsonEncode(r.$2));
    expect(r.$2['codigo'], codigo.valor);
    expect(r.$2['campo'], campo);
  }

  group('POST /aulas', () {
    test('201 com o DTO; data e hora chegam convertidas ao service', () async {
      final r = await chamar('POST', '/aulas', corpo: _corpoValido);
      expect(r.$1, 201);
      expect(r.$2, {
        'id_aula': 7,
        'id_professor': 10,
        'id_cronograma': null,
        'data': '2026-06-20',
        'hora_inicio': '07:05',
        'hora_fim': '08:00',
        'tipo': 'coletiva',
        'categoria': 'pilates',
        'vagas_maxima': 10,
        'vagas_ocupadas': 0,
        'vagas_livres': 10,
        'status': true,
        'data_cancelamento': null,
        'cancelado_por': null,
      });
      expect(servico.idsOcupacao, isEmpty, reason: 'aula nova nao consulta');
      expect(servico.recebido!['data'], DateTime(2026, 6, 20));
      expect(
        servico.recebido!['horaInicio'],
        const Duration(hours: 7, minutes: 5),
      );
    });

    test('sem identidade e 401', () async {
      final r = await chamar(
        'POST',
        '/aulas',
        corpo: _corpoValido,
        identidade: null,
      );
      esperaErro(r, 401, CodigoErro.tokenInvalido);
    });

    test('corpo que nao e objeto JSON e 400', () async {
      esperaErro(
        await chamar('POST', '/aulas', corpo: '{'),
        400,
        CodigoErro.jsonInvalido,
      );
      esperaErro(
        await chamar('POST', '/aulas', corpo: '[]'),
        400,
        CodigoErro.jsonInvalido,
      );
    });

    test('campo ausente e CAMPO_OBRIGATORIO', () async {
      final corpo = {..._corpoValido}..remove('hora_fim');
      esperaErro(
        await chamar('POST', '/aulas', corpo: corpo),
        400,
        CodigoErro.campoObrigatorio,
        'hora_fim',
      );
    });

    test('campo desconhecido e recusado', () async {
      esperaErro(
        await chamar(
          'POST',
          '/aulas',
          corpo: {..._corpoValido, 'status': false},
        ),
        400,
        CodigoErro.campoInvalido,
        'status',
      );
    });

    for (final (campo, valor) in [
      ('data', '2026-02-30'),
      ('data', '2026-6-20'),
      ('data', '2026-06-20T00:00:00Z'),
      ('hora_inicio', '7:05'),
      ('hora_inicio', '07:05:00'),
      ('hora_inicio', '24:00'),
      ('hora_fim', 800),
      ('vagas_maxima', '10'),
      ('vagas_maxima', 10.5),
      ('id_professor', '10'),
      ('tipo', '  '),
    ]) {
      test('$campo = ${jsonEncode(valor)} e CAMPO_INVALIDO', () async {
        final r = await chamar(
          'POST',
          '/aulas',
          corpo: {..._corpoValido, campo: valor},
        );
        esperaErro(r, 400, CodigoErro.campoInvalido, campo);
        expect(servico.recebido, isNull);
      });
    }

    test('erros do service viram envelope com o status do contrato', () async {
      servico.erro = const AcessoNegado();
      esperaErro(
        await chamar('POST', '/aulas', corpo: _corpoValido),
        403,
        CodigoErro.acessoNegado,
      );

      servico.erro = const AulaValidationException(
        CodigoErro.campoInvalido,
        campo: 'vagas_maxima',
      );
      esperaErro(
        await chamar('POST', '/aulas', corpo: _corpoValido),
        400,
        CodigoErro.campoInvalido,
        'vagas_maxima',
      );
    });
  });

  group('GET /aulas', () {
    test('pagina com padrao limit=20 offset=0 e total da colecao', () async {
      final r = await chamar('GET', '/aulas');
      expect(r.$1, 200);
      expect(r.$2['limit'], 20);
      expect(r.$2['offset'], 0);
      expect(r.$2['total'], 41);
      final itens = (r.$2['itens'] as List).cast<Map<String, dynamic>>();
      expect(itens.single['id_aula'], 7);
    });

    test('repassa os filtros ao service', () async {
      await chamar(
        'GET',
        '/aulas?limit=5&offset=10&data=2026-06-20&categoria=pilates&idProfessor=10',
      );
      expect(servico.recebido, {
        'limit': 5,
        'offset': 10,
        'data': DateTime(2026, 6, 20),
        'categoria': 'pilates',
        'idProfessor': 10,
      });
    });

    for (final (query, campo) in [
      ('limit=0', 'limit'),
      ('limit=101', 'limit'),
      ('limit=abc', 'limit'),
      ('offset=-1', 'offset'),
      ('data=2026-02-30', 'data'),
      ('idProfessor=x', 'idProfessor'),
      ('categoria=', 'categoria'),
    ]) {
      test('?$query e CAMPO_INVALIDO', () async {
        esperaErro(
          await chamar('GET', '/aulas?$query'),
          400,
          CodigoErro.campoInvalido,
          campo,
        );
      });
    }
  });

  group('GET /aulas/<id>', () {
    test('200 com o DTO', () async {
      final r = await chamar('GET', '/aulas/7');
      expect(r.$1, 200);
      expect(servico.recebido, {'idAula': 7});
    });

    test('id nao numerico e 400; inexistente e 404', () async {
      esperaErro(
        await chamar('GET', '/aulas/abc'),
        400,
        CodigoErro.campoInvalido,
        'id',
      );
      servico.erro = const AulaNotFoundException();
      esperaErro(
        await chamar('GET', '/aulas/9'),
        404,
        CodigoErro.registroNaoEncontrado,
      );
    });
  });

  group('PATCH /aulas/<id>', () {
    test('repassa so os campos enviados', () async {
      final r = await chamar(
        'PATCH',
        '/aulas/7',
        corpo: {'vagas_maxima': 12, 'hora_fim': '09:30'},
      );
      expect(r.$1, 200);
      expect(servico.recebido, {
        'idAula': 7,
        'vagasMaxima': 12,
        'horaFim': const Duration(hours: 9, minutes: 30),
      });
    });

    test('corpo vazio e CAMPO_OBRIGATORIO', () async {
      esperaErro(
        await chamar('PATCH', '/aulas/7', corpo: {}),
        400,
        CodigoErro.campoObrigatorio,
      );
    });

    test('campo nulo ou desconhecido e recusado', () async {
      esperaErro(
        await chamar('PATCH', '/aulas/7', corpo: {'tipo': null}),
        400,
        CodigoErro.campoInvalido,
        'tipo',
      );
      esperaErro(
        await chamar('PATCH', '/aulas/7', corpo: {'id_cronograma': 1}),
        400,
        CodigoErro.campoInvalido,
        'id_cronograma',
      );
    });

    test('conflitos do service saem como 409 com campo', () async {
      servico.erro = const AulaConflictException(CodigoErro.aulaInativa);
      esperaErro(
        await chamar('PATCH', '/aulas/7', corpo: {'vagas_maxima': 5}),
        409,
        CodigoErro.aulaInativa,
      );

      servico.erro = const AulaConflictException(
        CodigoErro.registroEmUso,
        campo: 'data',
      );
      esperaErro(
        await chamar('PATCH', '/aulas/7', corpo: {'data': '2026-06-21'}),
        409,
        CodigoErro.registroEmUso,
        'data',
      );
    });

    test('falha inesperada e 500 sem vazar a excecao', () async {
      servico.erro = StateError('detalhe interno');
      final r = await chamar('PATCH', '/aulas/7', corpo: {'vagas_maxima': 5});
      esperaErro(r, 500, CodigoErro.erroInterno);
      expect(jsonEncode(r.$2), isNot(contains('detalhe interno')));
    });
  });

  group('POST /aulas/<id>/cancelar', () {
    AulaData canceladaPor({int? idProfessor, int? idAdmin}) => AulaData(
      idAula: 7,
      idProfessor: 10,
      data: PgDate(year: 2026, month: 6, day: 20),
      horaInicio: pg.Time(7, 5),
      horaFim: pg.Time(8),
      tipo: 'coletiva',
      categoria: 'pilates',
      vagasMaxima: 10,
      status: false,
      idProfessorCancelou: idProfessor,
      idAdminCancelou: idAdmin,
      // 12:30 em Brasilia (-03:00) = 15:30 UTC.
      dataCancelamento: PgDateTime(DateTime.parse('2026-06-10T12:30:00-03:00')),
    );

    test('200 com a aula cancelada; sem corpo; ids de quem cancelou nao '
        'saem no JSON', () async {
      servico.cancelada = canceladaPor(idAdmin: 1);
      final r = await chamar('POST', '/aulas/7/cancelar');
      expect(r.$1, 200, reason: jsonEncode(r.$2));
      expect(servico.recebido, {'idAula': 7, 'papel': Papel.admin});
      expect(r.$2, {
        'id_aula': 7,
        'id_professor': 10,
        'id_cronograma': null,
        'data': '2026-06-20',
        'hora_inicio': '07:05',
        'hora_fim': '08:00',
        'tipo': 'coletiva',
        'categoria': 'pilates',
        'vagas_maxima': 10,
        'vagas_ocupadas': 3,
        'vagas_livres': 7,
        'status': false,
        'data_cancelamento': '2026-06-10T15:30:00.000Z',
        'cancelado_por': 'admin',
      });
      expect(r.$2.keys, isNot(contains('id_admin_cancelou')));
      expect(r.$2.keys, isNot(contains('id_professor_cancelou')));
    });

    test('cancelado_por = professor quando o professor cancelou', () async {
      servico.cancelada = canceladaPor(idProfessor: 10);
      final r = await chamar(
        'POST',
        '/aulas/7/cancelar',
        identidade: const Identidade(id: 10, papel: Papel.professor),
      );
      expect(r.$1, 200);
      expect(r.$2['cancelado_por'], 'professor');
      expect(r.$2['data_cancelamento'], '2026-06-10T15:30:00.000Z');
      expect(servico.recebido, {'idAula': 7, 'papel': Papel.professor});
    });

    test('corpo enviado e ignorado', () async {
      final r = await chamar('POST', '/aulas/7/cancelar', corpo: '{');
      expect(r.$1, 200);
    });

    test('sem identidade e 401; id nao numerico e 400', () async {
      esperaErro(
        await chamar('POST', '/aulas/7/cancelar', identidade: null),
        401,
        CodigoErro.tokenInvalido,
      );
      esperaErro(
        await chamar('POST', '/aulas/abc/cancelar'),
        400,
        CodigoErro.campoInvalido,
        'id',
      );
      expect(servico.recebido, isNull);
    });

    test('erros do service: 403, 404 e 409 AULA_DATA_PASSADA', () async {
      servico.erro = const AcessoNegado();
      esperaErro(
        await chamar('POST', '/aulas/7/cancelar'),
        403,
        CodigoErro.acessoNegado,
      );

      servico.erro = const AulaNotFoundException();
      esperaErro(
        await chamar('POST', '/aulas/9/cancelar'),
        404,
        CodigoErro.registroNaoEncontrado,
      );

      servico.erro = const AulaConflictException(CodigoErro.aulaDataPassada);
      final r = await chamar('POST', '/aulas/7/cancelar');
      esperaErro(r, 409, CodigoErro.aulaDataPassada);
      expect(r.$2['mensagem'], 'Aula ja realizada nao pode ser cancelada.');
    });

    test(
      'GET de aula ativa traz data_cancelamento e cancelado_por nulos',
      () async {
        final r = await chamar('GET', '/aulas/7');
        expect(r.$2['data_cancelamento'], isNull);
        expect(r.$2['cancelado_por'], isNull);
        expect(r.$2.containsKey('data_cancelamento'), isTrue);
        expect(r.$2.containsKey('cancelado_por'), isTrue);
      },
    );
  });

  group('ocupacao no JSON da aula', () {
    void esperaOcupacao(Map<String, dynamic> aula, int ocupadas) {
      expect(aula['vagas_ocupadas'], ocupadas);
      expect(aula['vagas_livres'], (aula['vagas_maxima'] as int) - ocupadas);
    }

    test('GET por id, PATCH e cancelar trazem ocupadas e livres', () async {
      servico.ocupacao = {7: 4};
      esperaOcupacao((await chamar('GET', '/aulas/7')).$2, 4);
      esperaOcupacao(
        (await chamar('PATCH', '/aulas/7', corpo: {'tipo': 'coletiva'})).$2,
        4,
      );
      esperaOcupacao((await chamar('POST', '/aulas/7/cancelar')).$2, 4);
      expect(servico.idsOcupacao, [
        [7],
        [7],
        [7],
      ]);
    });

    test(
      'GET /aulas: uma consulta de ocupacao para a pagina inteira',
      () async {
        servico.ocupacao = {7: 9};
        final r = await chamar('GET', '/aulas');
        final itens = (r.$2['itens'] as List).cast<Map<String, dynamic>>();
        esperaOcupacao(itens.single, 9);
        expect(itens.single['vagas_livres'], 1);
        expect(servico.idsOcupacao, [
          [7],
        ]);
      },
    );

    test('aula sem agendamento: 0 ocupadas, livres = maxima', () async {
      servico.ocupacao = {};
      final r = await chamar('GET', '/aulas/7');
      expect(r.$2['vagas_ocupadas'], 0);
      expect(r.$2['vagas_livres'], 10);
    });

    test('POST /aulas: ocupadas 0, sem consultar', () async {
      final r = await chamar('POST', '/aulas', corpo: _corpoValido);
      esperaOcupacao(r.$2, 0);
      expect(servico.idsOcupacao, isEmpty);
    });
  });

  group('GET /aulas/<id>/agendamentos', () {
    test('200 com pagina; itens so com as quatro chaves', () async {
      final r = await chamar('GET', '/aulas/7/agendamentos');
      expect(r.$1, 200, reason: jsonEncode(r.$2));
      expect(r.$2.keys.toSet(), {'itens', 'limit', 'offset', 'total'});
      expect(r.$2['limit'], 20);
      expect(r.$2['offset'], 0);
      expect(r.$2['total'], 23);
      final itens = (r.$2['itens'] as List).cast<Map<String, dynamic>>();
      expect(itens, [
        {
          'id_agendamento': 3,
          'id_aluno': 40,
          'nome_aluno': 'Ana',
          'status': 'presente',
        },
        {
          'id_agendamento': 1,
          'id_aluno': 41,
          'nome_aluno': 'Bia',
          'status': 'agendado',
        },
      ]);
      for (final item in itens) {
        expect(item.keys.toSet(), {
          'id_agendamento',
          'id_aluno',
          'nome_aluno',
          'status',
        });
      }
      expect(servico.recebido, {
        'idAula': 7,
        'limit': 20,
        'offset': 0,
        'papel': Papel.admin,
      });
    });

    test('repassa limit, offset e o papel do professor', () async {
      final r = await chamar(
        'GET',
        '/aulas/7/agendamentos?limit=5&offset=10',
        identidade: const Identidade(id: 10, papel: Papel.professor),
      );
      expect(r.$1, 200);
      expect(servico.recebido, {
        'idAula': 7,
        'limit': 5,
        'offset': 10,
        'papel': Papel.professor,
      });
    });

    test('sem identidade 401; id ou paginacao invalidos 400', () async {
      esperaErro(
        await chamar('GET', '/aulas/7/agendamentos', identidade: null),
        401,
        CodigoErro.tokenInvalido,
      );
      esperaErro(
        await chamar('GET', '/aulas/abc/agendamentos'),
        400,
        CodigoErro.campoInvalido,
        'id',
      );
      for (final (query, campo) in [
        ('limit=0', 'limit'),
        ('limit=101', 'limit'),
        ('offset=-1', 'offset'),
      ]) {
        esperaErro(
          await chamar('GET', '/aulas/7/agendamentos?$query'),
          400,
          CodigoErro.campoInvalido,
          campo,
        );
      }
      expect(servico.recebido, isNull);
    });

    test('erros do service: 403 e 404', () async {
      servico.erro = const AcessoNegado();
      esperaErro(
        await chamar('GET', '/aulas/7/agendamentos'),
        403,
        CodigoErro.acessoNegado,
      );
      servico.erro = const AulaNotFoundException();
      esperaErro(
        await chamar('GET', '/aulas/9/agendamentos'),
        404,
        CodigoErro.registroNaoEncontrado,
      );
    });
  });
}
