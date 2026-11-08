import 'dart:convert';

import 'package:drift_postgres/drift_postgres.dart' show PgDate;
import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/aulas/aula_controller.dart';
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
        'status': true,
      });
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
}
