import 'dart:convert';

import 'package:grazifit_backend/features/agendamentos/agendamento_controller.dart';
import 'package:grazifit_backend/features/agendamentos/agendamento_service.dart';
import 'package:grazifit_backend/shared/autorizacao/identidade.dart';
import 'package:grazifit_backend/shared/limite/limitador_janela.dart';
import 'package:grazifit_backend/shared/middleware/identidade_middleware.dart';
import 'package:shared/erros/codigo_erro.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'agendamento_fakes.dart';

void main() {
  late RepositorioAgendamentoFalso repo;
  late AgendamentoController controller;

  setUp(() {
    repo = RepositorioAgendamentoFalso()..aula = aulaDe();
    controller = AgendamentoController(
      AgendamentoService(repo, agora: () => agoraFixo),
    );
  });

  Future<(int, Map<String, dynamic>)> chamar(
    String metodo,
    String caminho, {
    Object? corpo,
    Identidade? identidade = aluno,
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

  group('POST /agendamentos', () {
    test('201 com o DTO do agendamento criado', () async {
      final r = await chamar('POST', '/agendamentos', corpo: {'id_aula': 1});
      expect(r.$1, 201, reason: jsonEncode(r.$2));
      expect(r.$2, {
        'id_agendamento': 1,
        'id_aluno': 5,
        'id_aula': 1,
        'data_agendamento': '2026-06-10',
        'status': 'agendado',
        'data_presenca': null,
        'data_cancelamento': null,
      });
    });

    test('sem token: 401 TOKEN_INVALIDO', () async {
      final r = await chamar(
        'POST',
        '/agendamentos',
        corpo: {'id_aula': 1},
        identidade: null,
      );
      esperaErro(r, 401, CodigoErro.tokenInvalido);
    });

    test('corpo que nao e JSON de objeto: 400 JSON_INVALIDO', () async {
      esperaErro(
        await chamar('POST', '/agendamentos', corpo: '[1]'),
        400,
        CodigoErro.jsonInvalido,
      );
      esperaErro(
        await chamar('POST', '/agendamentos', corpo: '{oi'),
        400,
        CodigoErro.jsonInvalido,
      );
    });

    test('id_aula ausente: 400 CAMPO_OBRIGATORIO', () async {
      esperaErro(
        await chamar('POST', '/agendamentos', corpo: {}),
        400,
        CodigoErro.campoObrigatorio,
        'id_aula',
      );
    });

    test('id_aula de tipo errado: 400 CAMPO_INVALIDO', () async {
      esperaErro(
        await chamar('POST', '/agendamentos', corpo: {'id_aula': '1'}),
        400,
        CodigoErro.campoInvalido,
        'id_aula',
      );
    });

    test('chave desconhecida: 400 CAMPO_INVALIDO no campo recusado', () async {
      esperaErro(
        await chamar(
          'POST',
          '/agendamentos',
          corpo: {'id_aula': 1, 'id_aluno': 9},
        ),
        400,
        CodigoErro.campoInvalido,
        'id_aluno',
      );
    });

    test('professor e admin: 403 ACESSO_NEGADO', () async {
      esperaErro(
        await chamar(
          'POST',
          '/agendamentos',
          corpo: {'id_aula': 1},
          identidade: professor,
        ),
        403,
        CodigoErro.acessoNegado,
      );
      esperaErro(
        await chamar(
          'POST',
          '/agendamentos',
          corpo: {'id_aula': 1},
          identidade: admin,
        ),
        403,
        CodigoErro.acessoNegado,
      );
    });

    test('aula inexistente: 404 REGISTRO_NAO_ENCONTRADO', () async {
      esperaErro(
        await chamar('POST', '/agendamentos', corpo: {'id_aula': 99}),
        404,
        CodigoErro.registroNaoEncontrado,
      );
    });

    test('aula lotada: 409 AULA_SEM_VAGAS (CA-3)', () async {
      repo.aula = aulaDe(vagas: 1);
      await chamar(
        'POST',
        '/agendamentos',
        corpo: {'id_aula': 1},
        identidade: outroAluno,
      );
      esperaErro(
        await chamar('POST', '/agendamentos', corpo: {'id_aula': 1}),
        409,
        CodigoErro.aulaSemVagas,
      );
    });

    test('duplicado: 409 AGENDAMENTO_DUPLICADO (CA-4)', () async {
      await chamar('POST', '/agendamentos', corpo: {'id_aula': 1});
      esperaErro(
        await chamar('POST', '/agendamentos', corpo: {'id_aula': 1}),
        409,
        CodigoErro.agendamentoDuplicado,
      );
    });

    test(
      'fora da janela: 409 AGENDAMENTO_FORA_DA_JANELA (CA-6, CA-11)',
      () async {
        repo.aula = aulaDe(
          data: DateTime(2026, 6, 10),
          horaInicio: const Duration(hours: 13),
          horaFim: const Duration(hours: 14),
        );
        esperaErro(
          await chamar('POST', '/agendamentos', corpo: {'id_aula': 1}),
          409,
          CodigoErro.agendamentoForaDaJanela,
        );
      },
    );

    test('data passada: 409 AULA_DATA_PASSADA (CA-8)', () async {
      repo.aula = aulaDe(data: DateTime(2026, 6, 9));
      esperaErro(
        await chamar('POST', '/agendamentos', corpo: {'id_aula': 1}),
        409,
        CodigoErro.aulaDataPassada,
      );
    });

    test('vigencia: 400 CAMPO_INVALIDO em data (CA-9)', () async {
      repo.aula = aulaDe(data: DateTime(2029, 1, 1));
      esperaErro(
        await chamar('POST', '/agendamentos', corpo: {'id_aula': 1}),
        400,
        CodigoErro.campoInvalido,
        'data',
      );
    });
  });

  group('GET /agendamentos (CA-10)', () {
    test('200 com paginacao; so os proprios', () async {
      await chamar('POST', '/agendamentos', corpo: {'id_aula': 1});
      await chamar(
        'POST',
        '/agendamentos',
        corpo: {'id_aula': 1},
        identidade: outroAluno,
      );
      final r = await chamar('GET', '/agendamentos?limit=10&offset=0');
      expect(r.$1, 200);
      expect(r.$2['total'], 1);
      expect(r.$2['limit'], 10);
      expect(r.$2['offset'], 0);
      final itens = (r.$2['itens'] as List).cast<Map<String, dynamic>>();
      expect(itens.map((i) => i['id_aluno']), [5]);
    });

    test('limit padrao 20 quando ausente', () async {
      final r = await chamar('GET', '/agendamentos');
      expect(r.$2['limit'], 20);
    });

    test('limit fora de 1..100: 400 CAMPO_INVALIDO', () async {
      esperaErro(
        await chamar('GET', '/agendamentos?limit=0'),
        400,
        CodigoErro.campoInvalido,
        'limit',
      );
      esperaErro(
        await chamar('GET', '/agendamentos?limit=101'),
        400,
        CodigoErro.campoInvalido,
        'limit',
      );
    });

    test('offset negativo: 400 CAMPO_INVALIDO', () async {
      esperaErro(
        await chamar('GET', '/agendamentos?offset=-1'),
        400,
        CodigoErro.campoInvalido,
        'offset',
      );
    });

    test('professor e admin: 403 ACESSO_NEGADO', () async {
      esperaErro(
        await chamar('GET', '/agendamentos', identidade: professor),
        403,
        CodigoErro.acessoNegado,
      );
    });
  });

  group('PATCH /agendamentos/<id> (CA-1, CA-7)', () {
    test('cancela o proprio: 200 com status cancelado', () async {
      await chamar('POST', '/agendamentos', corpo: {'id_aula': 1});
      final r = await chamar(
        'PATCH',
        '/agendamentos/1',
        corpo: {'status': 'cancelado'},
      );
      expect(r.$1, 200, reason: jsonEncode(r.$2));
      expect(r.$2['status'], 'cancelado');
      expect(r.$2['data_cancelamento'], isNotNull);
    });

    test(
      'agendamento de outro aluno: 404, igual a id inexistente (CA-1)',
      () async {
        await chamar('POST', '/agendamentos', corpo: {'id_aula': 1});
        final outro = await chamar(
          'PATCH',
          '/agendamentos/1',
          corpo: {'status': 'cancelado'},
          identidade: outroAluno,
        );
        final inexistente = await chamar(
          'PATCH',
          '/agendamentos/999',
          corpo: {'status': 'cancelado'},
          identidade: outroAluno,
        );
        esperaErro(outro, 404, CodigoErro.registroNaoEncontrado);
        expect(outro.$2['mensagem'], 'Agendamento nao encontrado.');
        // Mesma resposta para alvo alheio e inexistente: nao revela existencia.
        expect(outro.$2, inexistente.$2);
        expect(outro.$1, inexistente.$1);
        expect(repo.agendamentos.single.status, 'agendado');
      },
    );

    test('professor e admin: 403 ACESSO_NEGADO', () async {
      await chamar('POST', '/agendamentos', corpo: {'id_aula': 1});
      esperaErro(
        await chamar(
          'PATCH',
          '/agendamentos/1',
          corpo: {'status': 'cancelado'},
          identidade: professor,
        ),
        403,
        CodigoErro.acessoNegado,
      );
    });

    test('dentro da janela: 409 AGENDAMENTO_FORA_DA_JANELA', () async {
      await chamar('POST', '/agendamentos', corpo: {'id_aula': 1});
      repo.aula = aulaDe(
        data: DateTime(2026, 6, 10),
        horaInicio: const Duration(hours: 13),
        horaFim: const Duration(hours: 14),
      );
      esperaErro(
        await chamar(
          'PATCH',
          '/agendamentos/1',
          corpo: {'status': 'cancelado'},
        ),
        409,
        CodigoErro.agendamentoForaDaJanela,
      );
    });

    test('id nao numerico: 400 CAMPO_INVALIDO em id', () async {
      esperaErro(
        await chamar(
          'PATCH',
          '/agendamentos/abc',
          corpo: {'status': 'cancelado'},
        ),
        400,
        CodigoErro.campoInvalido,
        'id',
      );
    });

    test('status ausente: 400 CAMPO_OBRIGATORIO', () async {
      esperaErro(
        await chamar('PATCH', '/agendamentos/1', corpo: {}),
        400,
        CodigoErro.campoObrigatorio,
        'status',
      );
    });

    test('status diferente de cancelado: 400 CAMPO_INVALIDO', () async {
      esperaErro(
        await chamar('PATCH', '/agendamentos/1', corpo: {'status': 'presente'}),
        400,
        CodigoErro.campoInvalido,
        'status',
      );
    });

    test('campo fora de status: 400 CAMPO_INVALIDO', () async {
      esperaErro(
        await chamar(
          'PATCH',
          '/agendamentos/1',
          corpo: {'status': 'cancelado', 'id_aula': 2},
        ),
        400,
        CodigoErro.campoInvalido,
        'id_aula',
      );
    });

    test('agendamento inexistente: 404', () async {
      esperaErro(
        await chamar(
          'PATCH',
          '/agendamentos/999',
          corpo: {'status': 'cancelado'},
        ),
        404,
        CodigoErro.registroNaoEncontrado,
      );
    });
  });

  group('limite de requisicoes por usuario (429 MUITAS_TENTATIVAS)', () {
    late DateTime relogio;
    late RepositorioAgendamentoFalso repoLimite;
    late AgendamentoController limitado;

    setUp(() {
      relogio = agoraFixo;
      repoLimite = RepositorioAgendamentoFalso()..aula = aulaDe(vagas: 10);
      limitado = AgendamentoController(
        AgendamentoService(repoLimite, agora: () => agoraFixo),
        limitePost: LimitadorJanela(
          maximo: 2,
          janela: const Duration(minutes: 1),
          agora: () => relogio,
        ),
        limitePatch: LimitadorJanela(
          maximo: 1,
          janela: const Duration(minutes: 1),
          agora: () => relogio,
        ),
      );
    });

    Future<Response> emitir(
      String metodo,
      String caminho, {
      Object? corpo,
      Identidade? identidade = aluno,
    }) => limitado.router.call(
      Request(
        metodo,
        Uri.parse('http://localhost$caminho'),
        body: corpo == null ? null : jsonEncode(corpo),
        context: {chaveIdentidadeContexto: ?identidade},
      ),
    );

    Future<Map<String, dynamic>> corpoDe(Response r) async =>
        jsonDecode(await r.readAsString()) as Map<String, dynamic>;

    test('POST: passado o limite, 429 com Retry-After e envelope', () async {
      // Duas reservas passam (a segunda vira DUPLICADO, 409, mas conta).
      expect(
        (await emitir(
          'POST',
          '/agendamentos',
          corpo: {'id_aula': 1},
        )).statusCode,
        201,
      );
      expect(
        (await emitir(
          'POST',
          '/agendamentos',
          corpo: {'id_aula': 1},
        )).statusCode,
        409,
      );

      final r = await emitir('POST', '/agendamentos', corpo: {'id_aula': 1});
      expect(r.statusCode, 429);
      expect(r.headers['Retry-After'], '60');
      final corpo = await corpoDe(r);
      expect(corpo['codigo'], CodigoErro.muitasTentativas.valor);
      expect(corpo.containsKey('campo'), isFalse);
      expect(corpo['mensagem'], isA<String>());
      // A requisicao limitada nao chega ao service.
      expect(repoLimite.agendamentos, hasLength(1));
    });

    test('POST: o limite e por usuario; outro aluno nao e afetado', () async {
      await emitir('POST', '/agendamentos', corpo: {'id_aula': 1});
      await emitir('POST', '/agendamentos', corpo: {'id_aula': 1});
      expect(
        (await emitir(
          'POST',
          '/agendamentos',
          corpo: {'id_aula': 1},
        )).statusCode,
        429,
      );

      final outro = await emitir(
        'POST',
        '/agendamentos',
        corpo: {'id_aula': 1},
        identidade: outroAluno,
      );
      expect(outro.statusCode, 201);
    });

    test('PATCH: limite proprio, separado do POST', () async {
      await emitir('POST', '/agendamentos', corpo: {'id_aula': 1});
      final primeiro = await emitir(
        'PATCH',
        '/agendamentos/1',
        corpo: {'status': 'cancelado'},
      );
      expect(primeiro.statusCode, 200);

      final r = await emitir(
        'PATCH',
        '/agendamentos/1',
        corpo: {'status': 'cancelado'},
      );
      expect(r.statusCode, 429);
      expect(r.headers['Retry-After'], '60');
      expect((await corpoDe(r))['codigo'], 'MUITAS_TENTATIVAS');
    });

    test(
      'a janela desliza: depois de 60 s o usuario volta a ser atendido',
      () async {
        await emitir('POST', '/agendamentos', corpo: {'id_aula': 1});
        await emitir('POST', '/agendamentos', corpo: {'id_aula': 1});
        expect(
          (await emitir(
            'POST',
            '/agendamentos',
            corpo: {'id_aula': 1},
          )).statusCode,
          429,
        );

        relogio = relogio.add(const Duration(seconds: 60));
        final depois = await emitir(
          'POST',
          '/agendamentos',
          corpo: {'id_aula': 1},
        );
        expect(depois.statusCode, 409);
        expect((await corpoDe(depois))['codigo'], 'AGENDAMENTO_DUPLICADO');
      },
    );

    test(
      'sem identidade o limite nao e consumido (401 continua 401)',
      () async {
        for (var i = 0; i < 5; i++) {
          final r = await emitir(
            'POST',
            '/agendamentos',
            corpo: {'id_aula': 1},
            identidade: null,
          );
          expect(r.statusCode, 401);
        }
        expect(
          (await emitir(
            'POST',
            '/agendamentos',
            corpo: {'id_aula': 1},
          )).statusCode,
          201,
        );
      },
    );
  });
}
