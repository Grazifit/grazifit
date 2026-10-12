import 'dart:async';
import 'dart:convert';

import 'package:drift_postgres/drift_postgres.dart' show PgDate;
import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/pessoas/aluno/aluno_controller.dart';
import 'package:grazifit_backend/features/pessoas/aluno/aluno_exception.dart';
import 'package:grazifit_backend/features/pessoas/aluno/aluno_service.dart';
import 'package:shared/erros/codigo_erro.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// Service falso — o controller e testado sozinho, sem service, sem
/// repository, sem banco e sem servidor HTTP.
///
/// `implements` em vez de `extends` de proposito: assim nao e preciso
/// construir um `AlunoRepository`, que exigiria um `GraziDatabase`.
class _ServicoFalso implements AlunoService {
  /// Quando preenchido, `criar` e `atualizar` lancam este erro — simula a
  /// recusa de regra do service.
  Object? erroDoServico;

  /// A data que o controller entregou, ou nulo se ele recusou antes.
  DateTime? dataRecebida;
  bool chamado = false;

  @override
  String Function(String senha) get hash =>
      (s) => 'hash-falso';

  @override
  Future<AlunoData> criar({
    required String cpf,
    required String senha,
    required String nome,
    required DateTime dataNascimento,
    required String telefone,
    required String email,
    int? idAdminCriador,
    int? idEndereco,
    String? restricaoMedica,
    String? observacaoSaude,
  }) async {
    chamado = true;
    dataRecebida = dataNascimento;
    if (erroDoServico != null) throw erroDoServico!;

    return AlunoData(
      idAluno: 1,
      cpf: cpf,
      senhaHash: 'hash-falso',
      nome: nome,
      dataNascimento: PgDate.fromDateTime(dataNascimento),
      telefone: telefone,
      email: email,
      status: true,
      dataCadastro: PgDate.fromDateTime(DateTime.now()),
    );
  }

  /// Alunos que a busca encontra, por id.
  final Map<int, AlunoData> existentes = {};

  @override
  Future<AlunoData> buscarAlunoPorId(int idAluno) async {
    final aluno = existentes[idAluno];
    if (aluno == null) throw const AlunoNotFoundException();
    return aluno;
  }

  /// Quando verdadeiro, a listagem estoura com um erro inesperado.
  bool falhar = false;

  /// O que o controller pediu na ultima listagem, ou nulo se recusou antes.
  ({int limit, int offset})? paginaPedida;

  @override
  Future<({List<AlunoData> itens, int total})> buscarAlunos({
    required int limit,
    required int offset,
  }) async {
    if (falhar) throw StateError('falha simulada');
    paginaPedida = (limit: limit, offset: offset);
    final todos = existentes.values.toList();
    return (
      itens: todos.skip(offset).take(limit).toList(),
      total: todos.length,
    );
  }

  /// O que o controller entregou ao `atualizar`, ou nulo se recusou antes.
  Map<String, Object?>? atualizacaoRecebida;

  /// O status que o controller entregou, ou nulo se recusou antes.
  bool? statusRecebido;

  /// Ids excluidos.
  final List<int> excluidos = [];

  @override
  Future<AlunoData> atualizar(
    int idAluno, {
    String? nome,
    String? telefone,
    String? email,
  }) async {
    atualizacaoRecebida = {'nome': nome, 'telefone': telefone, 'email': email};
    if (erroDoServico != null) throw erroDoServico!;
    final atual = existentes[idAluno];
    if (atual == null) throw const AlunoNotFoundException();
    return atual.copyWith(
      nome: nome ?? atual.nome,
      telefone: telefone ?? atual.telefone,
      email: email ?? atual.email,
    );
  }

  @override
  Future<void> alterarStatus(int idAluno, {required bool status}) async {
    statusRecebido = status;
    if (!existentes.containsKey(idAluno)) throw const AlunoNotFoundException();
  }

  @override
  Future<void> excluir(int idAluno) async {
    if (existentes.remove(idAluno) == null) {
      throw const AlunoNotFoundException();
    }
    excluidos.add(idAluno);
  }
}

AlunoData _alunoExistente(int idAluno) => AlunoData(
  idAluno: idAluno,
  cpf: cpfValido,
  senhaHash: 'hash-falso',
  nome: 'Aluno $idAluno',
  dataNascimento: PgDate.fromDateTime(DateTime(1995, 3, 20)),
  telefone: '11999998888',
  email: 'aluno$idAluno@exemplo.com',
  restricaoMedica: 'Hipertensao',
  status: true,
  dataCadastro: PgDate.fromDateTime(DateTime.now()),
);

/// Todo erro sai no envelope `{ codigo, mensagem, campo? }` — D64. Casa
/// pelo codigo e pelo campo, nunca pelo texto da mensagem.
Future<void> _esperaEnvelope(
  Response resposta,
  int status,
  String codigo, {
  String? campo,
}) async {
  expect(resposta.statusCode, status);
  final corpo =
      jsonDecode(await resposta.readAsString()) as Map<String, dynamic>;
  expect(corpo['codigo'], codigo);
  expect(corpo['mensagem'], isA<String>());
  expect(corpo['campo'], campo);
  expect(corpo.containsKey('erro'), isFalse, reason: 'formato antigo');
}

Future<Response> _get(AlunoController controller, String caminho) {
  return controller.router.call(
    Request('GET', Uri.parse('http://localhost$caminho')),
  );
}

const cpfValido = '52998224725';

/// Monta o corpo completo, trocando so o que o teste quer variar.
String _corpo({String? dataNascimento = '1995-03-20'}) {
  return jsonEncode({
    'cpf': cpfValido,
    'senha': 'senhaboa1',
    'nome': 'Aluno Teste',
    'telefone': '11999998888',
    'email': 'aluno@exemplo.com',
    'data_nascimento': ?dataNascimento,
  });
}

Future<Response> _post(AlunoController controller, String corpo) {
  return controller.router.call(
    Request(
      'POST',
      Uri.parse('http://localhost/aluno'),
      body: corpo,
      headers: {'Content-Type': 'application/json'},
    ),
  );
}

void main() {
  late _ServicoFalso servico;
  late AlunoController controller;

  setUp(() {
    servico = _ServicoFalso();
    controller = AlunoController(servico);
  });

  group('data_nascimento — D68 aceita AAAA-MM-DD e nada mais', () {
    test('a forma do contrato passa e chega intacta ao service', () async {
      final resposta = await _post(controller, _corpo());

      expect(resposta.statusCode, 201);
      expect(servico.dataRecebida, DateTime(1995, 3, 20));
    });

    // Todas estas o `DateTime.tryParse` sozinho aceitaria. As tres ultimas
    // sao o caso perigoso: `PgDate.fromDateTime` le o dia do `DateTime` ja
    // convertido para UTC, entao um offset gravaria data diferente da
    // enviada.
    for (final bruta in const [
      '19950320',
      '1995-03-20T10:30:00',
      '1995-03-20T10:30:00Z',
      '1995-03-20 10:30:00',
      '1995-03-20T02:00:00+05:00',
      '1995-03-20T22:00:00-05:00',
    ]) {
      test('recusa "$bruta" — tem hora, fuso ou forma compacta', () async {
        final resposta = await _post(controller, _corpo(dataNascimento: bruta));

        await _esperaEnvelope(
          resposta,
          400,
          'CAMPO_INVALIDO',
          campo: 'data_nascimento',
        );
        expect(servico.chamado, isFalse, reason: 'nao pode chegar ao service');
      });
    }

    // O regex sozinho nao pega nenhuma destas: todas casam com
    // `\d{4}-\d{2}-\d{2}`. `DateTime.tryParse` faz rollover e devolve uma
    // data valida — 2025-02-30 vira 2025-03-02. So o round-trip pega.
    for (final inexistente in const [
      '2025-02-30',
      '2025-13-01',
      '2025-04-31',
      '2025-00-10',
      '2023-02-29',
    ]) {
      test(
        'recusa "$inexistente" — data que nao existe no calendario',
        () async {
          final resposta = await _post(
            controller,
            _corpo(dataNascimento: inexistente),
          );

          await _esperaEnvelope(
            resposta,
            400,
            'CAMPO_INVALIDO',
            campo: 'data_nascimento',
          );
          expect(
            servico.chamado,
            isFalse,
            reason: 'rollover silencioso gravaria outro dia',
          );
        },
      );
    }

    test('2024-02-29 passa — 2024 e bissexto', () async {
      final resposta = await _post(
        controller,
        _corpo(dataNascimento: '2024-02-29'),
      );

      expect(resposta.statusCode, 201);
      expect(servico.dataRecebida, DateTime(2024, 2, 29));
    });

    for (final malformada in const ['1995-3-20', '20/03/1995', 'ontem', '']) {
      test('recusa "$malformada"', () async {
        final resposta = await _post(
          controller,
          _corpo(dataNascimento: malformada),
        );

        // Em branco conta como ausente: e o `_texto` do controller.
        await _esperaEnvelope(
          resposta,
          400,
          malformada.isEmpty ? 'CAMPO_OBRIGATORIO' : 'CAMPO_INVALIDO',
          campo: 'data_nascimento',
        );
        expect(servico.chamado, isFalse);
      });
    }
  });

  group('demais erros de forma', () {
    test('campo obrigatorio ausente', () async {
      final resposta = await _post(controller, _corpo(dataNascimento: null));

      await _esperaEnvelope(
        resposta,
        400,
        'CAMPO_OBRIGATORIO',
        campo: 'data_nascimento',
      );
      expect(servico.chamado, isFalse);
    });

    test('JSON malformado', () async {
      final resposta = await _post(controller, '{ isto nao e json');

      await _esperaEnvelope(resposta, 400, 'JSON_INVALIDO');
      expect(servico.chamado, isFalse);
    });

    test('senha fora de 8 a 12 caracteres', () async {
      final resposta = await _post(
        controller,
        jsonEncode({
          'cpf': cpfValido,
          'senha': 'curta',
          'nome': 'Aluno Teste',
          'telefone': '11999998888',
          'email': 'aluno@exemplo.com',
          'data_nascimento': '1995-03-20',
        }),
      );

      await _esperaEnvelope(resposta, 400, 'CAMPO_INVALIDO', campo: 'senha');
      expect(servico.chamado, isFalse);
    });
  });

  group('resposta de sucesso', () {
    test('201 nao devolve campo clinico nem hash de senha — D21', () async {
      final resposta = await _post(
        controller,
        jsonEncode({
          'cpf': cpfValido,
          'senha': 'senhaboa1',
          'nome': 'Aluno Teste',
          'telefone': '11999998888',
          'email': 'aluno@exemplo.com',
          'data_nascimento': '1995-03-20',
          'restricao_medica': 'Hipertensao',
          'observacao_saude': 'Evitar impacto',
        }),
      );

      expect(resposta.statusCode, 201);

      final corpo =
          jsonDecode(await resposta.readAsString()) as Map<String, dynamic>;
      expect(
        corpo.keys,
        containsAll(['id_aluno', 'nome', 'email', 'telefone']),
      );
      expect(corpo.containsKey('restricao_medica'), isFalse);
      expect(corpo.containsKey('observacao_saude'), isFalse);
      expect(corpo.containsKey('senha_hash'), isFalse);
      expect(corpo.containsKey('cpf'), isFalse);
    });
  });

  group('status no DTO', () {
    Future<Map<String, dynamic>> alunoDe(Response resposta) async =>
        jsonDecode(await resposta.readAsString()) as Map<String, dynamic>;

    test('aluno ativo sai com status true', () async {
      servico.existentes[1] = _alunoExistente(1);

      final corpo = await alunoDe(await _get(controller, '/aluno/1'));

      expect(corpo['status'], isTrue);
    });

    test('aluno inativo sai com status false', () async {
      servico.existentes[1] = _alunoExistente(1).copyWith(status: false);

      final corpo = await alunoDe(await _get(controller, '/aluno/1'));

      expect(corpo['status'], isFalse);
    });

    test('a listagem distingue ativos de inativos', () async {
      servico.existentes
        ..[1] = _alunoExistente(1)
        ..[2] = _alunoExistente(2).copyWith(status: false);

      final pagina = await alunoDe(await _get(controller, '/aluno'));

      final itens = (pagina['itens'] as List).cast<Map<String, dynamic>>();
      expect(itens.map((a) => a['status']), [true, false]);
    });
  });

  group('GET /aluno/<id>', () {
    test('200 com o aluno, sem campo clinico, hash nem CPF', () async {
      servico.existentes[3] = _alunoExistente(3);

      final resposta = await _get(controller, '/aluno/3');

      expect(resposta.statusCode, 200);
      final corpo =
          jsonDecode(await resposta.readAsString()) as Map<String, dynamic>;
      expect(corpo['id_aluno'], 3);
      expect(corpo.containsKey('restricao_medica'), isFalse);
      expect(corpo.containsKey('senha_hash'), isFalse);
      expect(corpo.containsKey('cpf'), isFalse);
    });

    test('404 no envelope com REGISTRO_NAO_ENCONTRADO', () async {
      final resposta = await _get(controller, '/aluno/99');

      expect(resposta.statusCode, 404);
      final corpo =
          jsonDecode(await resposta.readAsString()) as Map<String, dynamic>;
      expect(corpo['codigo'], 'REGISTRO_NAO_ENCONTRADO');
      expect(corpo.containsKey('mensagem'), isTrue);
    });

    test('400 quando o id nao e inteiro', () async {
      final resposta = await _get(controller, '/aluno/abc');

      await _esperaEnvelope(resposta, 400, 'CAMPO_INVALIDO', campo: 'id');
    });
  });

  group('GET /aluno — pagina', () {
    Future<Map<String, dynamic>> corpoDe(Response resposta) async =>
        jsonDecode(await resposta.readAsString()) as Map<String, dynamic>;

    test('sem parametros usa limit=20 e offset=0', () async {
      final resposta = await _get(controller, '/aluno');

      expect(resposta.statusCode, 200);
      expect(servico.paginaPedida, (limit: 20, offset: 0));
      expect(await corpoDe(resposta), {
        'itens': isEmpty,
        'limit': 20,
        'offset': 0,
        'total': 0,
      });
    });

    test('total conta a colecao inteira, nao a pagina', () async {
      for (var id = 1; id <= 5; id++) {
        servico.existentes[id] = _alunoExistente(id);
      }

      final resposta = await _get(controller, '/aluno?limit=2&offset=2');

      expect(resposta.statusCode, 200);
      final corpo = await corpoDe(resposta);
      final itens = (corpo['itens'] as List).cast<Map<String, dynamic>>();
      expect(itens.map((a) => a['id_aluno']), [3, 4]);
      expect(corpo['limit'], 2);
      expect(corpo['offset'], 2);
      expect(corpo['total'], 5);
    });

    test('itens sem campo clinico, hash nem CPF', () async {
      servico.existentes[1] = _alunoExistente(1);

      final corpo = await corpoDe(await _get(controller, '/aluno'));

      final aluno = (corpo['itens'] as List).single as Map<String, dynamic>;
      expect(aluno.containsKey('restricao_medica'), isFalse);
      expect(aluno.containsKey('senha_hash'), isFalse);
      expect(aluno.containsKey('cpf'), isFalse);
    });

    test('limit=100 e o teto, e passa', () async {
      final resposta = await _get(controller, '/aluno?limit=100');

      expect(resposta.statusCode, 200);
      expect(servico.paginaPedida?.limit, 100);
    });

    for (final consulta in const [
      'limit=101',
      'limit=0',
      'limit=-1',
      'limit=abc',
      'limit=',
      'limit=2.5',
      'offset=-1',
      'offset=abc',
      'offset=',
    ]) {
      test('400 para ?$consulta, sem chegar ao service', () async {
        final resposta = await _get(controller, '/aluno?$consulta');

        await _esperaEnvelope(
          resposta,
          400,
          'CAMPO_INVALIDO',
          campo: consulta.split('=').first,
        );
        expect(servico.paginaPedida, isNull);
      });
    }
  });

  group('erro inesperado', () {
    test('500 no envelope com ERRO_INTERNO, sem vazar a excecao', () async {
      servico.falhar = true;

      // O `_erroInterno` registra a excecao com `print`. A zona captura o
      // que seria impresso: a saida do teste fica limpa e da para conferir
      // que o log aconteceu.
      final log = <String>[];
      final resposta = await runZoned(
        () => _get(controller, '/aluno'),
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, linha) => log.add(linha),
        ),
      );

      // Le uma vez so: o corpo de um Response nao pode ser lido duas vezes.
      final texto = await resposta.readAsString();
      expect(resposta.statusCode, 500);
      expect(
        (jsonDecode(texto) as Map<String, dynamic>)['codigo'],
        'ERRO_INTERNO',
      );
      expect(texto, isNot(contains('falha simulada')), reason: 'cliente');
      expect(log.join('\n'), contains('falha simulada'), reason: 'log');
    });
  });

  group('PATCH /aluno/<id>', () {
    Future<Response> patch(String caminho, Object corpo) =>
        controller.router.call(
          Request(
            'PATCH',
            Uri.parse('http://localhost$caminho'),
            body: corpo is String ? corpo : jsonEncode(corpo),
            headers: {'Content-Type': 'application/json'},
          ),
        );

    // O controller repassa o texto como veio; o `trim` e do service.
    test('200 com o aluno atualizado, so com o que veio', () async {
      servico.existentes[1] = _alunoExistente(1);

      final resposta = await patch('/aluno/1', {'nome': 'Novo Nome'});

      expect(resposta.statusCode, 200);
      final corpo =
          jsonDecode(await resposta.readAsString()) as Map<String, dynamic>;
      expect(corpo['nome'], 'Novo Nome');
      expect(corpo.containsKey('cpf'), isFalse);
      expect(servico.atualizacaoRecebida, {
        'nome': 'Novo Nome',
        'telefone': null,
        'email': null,
      });
    });

    for (final chave in const ['cpf', 'senha', 'restricao_medica', 'status']) {
      test('recusa "$chave" — nao e editavel por esta rota', () async {
        servico.existentes[1] = _alunoExistente(1);

        final resposta = await patch('/aluno/1', {chave: 'x'});

        await _esperaEnvelope(resposta, 400, 'CAMPO_INVALIDO', campo: chave);
        expect(servico.atualizacaoRecebida, isNull);
      });
    }

    test('corpo vazio -> CAMPO_OBRIGATORIO', () async {
      final resposta = await patch('/aluno/1', <String, Object>{});

      await _esperaEnvelope(resposta, 400, 'CAMPO_OBRIGATORIO');
      expect(servico.atualizacaoRecebida, isNull);
    });

    for (final valor in const [null, '', '   ', 123]) {
      test('recusa nome = ${jsonEncode(valor)}', () async {
        final resposta = await patch('/aluno/1', {'nome': valor});

        await _esperaEnvelope(resposta, 400, 'CAMPO_INVALIDO', campo: 'nome');
        expect(servico.atualizacaoRecebida, isNull);
      });
    }

    test('recusa telefone com mais de 20 caracteres', () async {
      final resposta = await patch('/aluno/1', {'telefone': '1' * 21});

      await _esperaEnvelope(resposta, 400, 'CAMPO_INVALIDO', campo: 'telefone');
    });

    test('JSON que nao e objeto -> JSON_INVALIDO', () async {
      final resposta = await patch('/aluno/1', '[1, 2]');

      await _esperaEnvelope(resposta, 400, 'JSON_INVALIDO');
    });

    test('aluno inexistente -> 404', () async {
      final resposta = await patch('/aluno/99', {'nome': 'X'});

      await _esperaEnvelope(resposta, 404, 'REGISTRO_NAO_ENCONTRADO');
    });
  });

  group('PATCH /aluno/<id>/status', () {
    Future<Response> patchStatus(String id, Object corpo) =>
        controller.router.call(
          Request(
            'PATCH',
            Uri.parse('http://localhost/aluno/$id/status'),
            body: jsonEncode(corpo),
            headers: {'Content-Type': 'application/json'},
          ),
        );

    for (final status in const [false, true]) {
      test('204 com status=$status', () async {
        servico.existentes[1] = _alunoExistente(1);

        final resposta = await patchStatus('1', {'status': status});

        expect(resposta.statusCode, 204);
        expect(servico.statusRecebido, status);
      });
    }

    test('sem status -> CAMPO_OBRIGATORIO', () async {
      final resposta = await patchStatus('1', <String, Object>{});

      await _esperaEnvelope(
        resposta,
        400,
        'CAMPO_OBRIGATORIO',
        campo: 'status',
      );
    });

    for (final valor in const ['false', 0, 'inativo']) {
      test('recusa status = ${jsonEncode(valor)} — so booleano', () async {
        final resposta = await patchStatus('1', {'status': valor});

        await _esperaEnvelope(resposta, 400, 'CAMPO_INVALIDO', campo: 'status');
        expect(servico.statusRecebido, isNull);
      });
    }

    test('aluno inexistente -> 404', () async {
      final resposta = await patchStatus('99', {'status': false});

      await _esperaEnvelope(resposta, 404, 'REGISTRO_NAO_ENCONTRADO');
    });
  });

  group('DELETE /aluno/<id>', () {
    Future<Response> delete(String id) => controller.router.call(
      Request('DELETE', Uri.parse('http://localhost/aluno/$id')),
    );

    test('204 e o aluno sai', () async {
      servico.existentes[1] = _alunoExistente(1);

      final resposta = await delete('1');

      expect(resposta.statusCode, 204);
      expect(servico.excluidos, [1]);
    });

    test('aluno inexistente -> 404', () async {
      final resposta = await delete('99');

      await _esperaEnvelope(resposta, 404, 'REGISTRO_NAO_ENCONTRADO');
    });

    test('id nao inteiro -> 400', () async {
      final resposta = await delete('abc');

      await _esperaEnvelope(resposta, 400, 'CAMPO_INVALIDO', campo: 'id');
    });
  });

  group('erros de regra do service chegam no envelope', () {
    final casos = <(String, AlunoException, int, String, String)>[
      (
        'CPF ja cadastrado',
        const AlunoConflictException(CodigoErro.cpfEmUso, campo: 'cpf'),
        409,
        'CPF_EM_USO',
        'cpf',
      ),
      (
        'e-mail ja cadastrado',
        const AlunoConflictException(CodigoErro.emailEmUso, campo: 'email'),
        409,
        'EMAIL_EM_USO',
        'email',
      ),
      (
        'CPF invalido',
        const AlunoValidationException(CodigoErro.cpfInvalido, campo: 'cpf'),
        400,
        'CPF_INVALIDO',
        'cpf',
      ),
      (
        'nascimento nao anterior a hoje',
        const AlunoValidationException(
          CodigoErro.dataNascimentoInvalida,
          campo: 'data_nascimento',
        ),
        400,
        'DATA_NASCIMENTO_INVALIDA',
        'data_nascimento',
      ),
    ];

    for (final (nome, erro, status, codigo, campo) in casos) {
      test('POST: $nome -> $status $codigo', () async {
        servico.erroDoServico = erro;

        final resposta = await _post(controller, _corpo());

        await _esperaEnvelope(resposta, status, codigo, campo: campo);
      });
    }

    test('PATCH: e-mail ja cadastrado -> 409 EMAIL_EM_USO', () async {
      servico.existentes[1] = _alunoExistente(1);
      servico.erroDoServico = const AlunoConflictException(
        CodigoErro.emailEmUso,
        campo: 'email',
      );

      final resposta = await controller.router.call(
        Request(
          'PATCH',
          Uri.parse('http://localhost/aluno/1'),
          body: jsonEncode({'email': 'outro@exemplo.com'}),
        ),
      );

      await _esperaEnvelope(resposta, 409, 'EMAIL_EM_USO', campo: 'email');
    });
  });

  group('tamanhos maximos', () {
    Map<String, dynamic> corpoValido() =>
        jsonDecode(_corpo()) as Map<String, dynamic>;

    test('POST: nome com 151 caracteres -> 400', () async {
      final resposta = await _post(
        controller,
        jsonEncode(corpoValido()..['nome'] = 'a' * 151),
      );

      await _esperaEnvelope(resposta, 400, 'CAMPO_INVALIDO', campo: 'nome');
      expect(servico.chamado, isFalse);
    });

    // A coluna e VARCHAR(255): sem esta checagem o Drift recusava o valor e
    // a resposta era 500.
    final emailLongo = '${'a' * 250}@exemplo.com';

    test('POST: e-mail com mais de 255 caracteres -> 400', () async {
      final resposta = await _post(
        controller,
        jsonEncode(corpoValido()..['email'] = emailLongo),
      );

      await _esperaEnvelope(resposta, 400, 'CAMPO_INVALIDO', campo: 'email');
      expect(servico.chamado, isFalse);
    });

    test('PATCH: e-mail com mais de 255 caracteres -> 400', () async {
      final resposta = await controller.router.call(
        Request(
          'PATCH',
          Uri.parse('http://localhost/aluno/1'),
          body: jsonEncode({'email': emailLongo}),
        ),
      );

      await _esperaEnvelope(resposta, 400, 'CAMPO_INVALIDO', campo: 'email');
      expect(servico.atualizacaoRecebida, isNull);
    });
  });
}
