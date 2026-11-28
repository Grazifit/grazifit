import 'dart:convert';

import 'package:postgres/postgres.dart' as pg;
import 'package:shared/dtos/exercicio_serializer.dart';
import 'package:shared/dtos/pagina_serializer.dart';
import 'package:shared/erros/codigo_erro.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../database/database.dart' show ExercicioData;
import '../../shared/autorizacao/identidade.dart';
import '../../shared/erros/exercicio_exception.dart';
import '../../shared/erros/status_http.dart';
import '../../shared/erros/tradutor_erro_banco.dart';
import '../../shared/middleware/identidade_middleware.dart';
import 'exercicio_service.dart';

/// Forma da requisicao e montagem do DTO. Sem regra de negocio nem decisao
/// de permissao (`docs/guia-desenvolvimento.md` §4.3).
class ExercicioController {
  final ExercicioService _service;

  ExercicioController(this._service);

  Router get router {
    final router = Router();
    router.post('/exercicio', _createExercicio);
    router.get('/exercicio', _buscarExercicios);
    router.get('/exercicio/<id>', _buscarExercicioPorId);
    router.patch('/exercicio/<id>', _atualizarExercicio);
    router.delete('/exercicio/<id>', _excluirExercicio);
    return router;
  }

  // Tamanhos aceitos — espelham as colunas de `exercicio` no schema.
  static const int _nomeMax = 120;

  static const int _limitPadrao = 20;
  static const int _limitMaximo = 100;

  static const List<String> _editaveis = [
    'nome',
    'instrucoes',
    'descricao',
    'dificuldade',
  ];

  Future<Response> _createExercicio(Request req) async {
    final identidade = identidadeDaRequisicao(req);
    if (identidade == null) {
      return _envelope(CodigoErro.tokenInvalido);
    }
    final payload = await _lerObjeto(req);
    if (payload == null) {
      return _envelope(CodigoErro.jsonInvalido);
    }

    final nome = _texto(payload['nome']);
    final instrucoes = _texto(payload['instrucoes']);

    for (final obrigatorio in {'nome': nome, 'instrucoes': instrucoes}.entries) {
      if (obrigatorio.value == null) {
        return _envelope(CodigoErro.campoObrigatorio, campo: obrigatorio.key);
      }
    }

    // `dificuldade` e opcional (default `iniciante`), mas se vier precisa
    // ser texto valido.
    final dificuldade = payload.containsKey('dificuldade')
        ? payload['dificuldade']
        : 'iniciante';

    if (dificuldade == null) {
      return _campoInvalido(
        'dificuldade',
        'Deve ser um de: ${ExercicioService.dificuldades.join(', ')}.',
      );
    }

    final formaInvalida = _validarForma(nome: nome, dificuldade: dificuldade);
    if (formaInvalida != null) {
      return formaInvalida;
    }

    return _executar(() async {
      final exercicio = await _service.criar(
        identidade: identidade,
        nome: nome!,
        instrucoes: instrucoes!,
        descricao: _texto(payload['descricao']),
        dificuldade: dificuldade as String,
      );
      return _json(201, _exercicioJson(exercicio));
    });
  }

  Future<Response> _buscarExercicioPorId(Request req, String id) {
    final identidade = identidadeDaRequisicao(req);
    if (identidade == null) {
      return Future.value(_envelope(CodigoErro.tokenInvalido));
    }
    return _comId(id, (idExercicio) async {
      final exercicio = await _service.buscarExercicioPorId(
        idExercicio,
        identidade: identidade,
      );
      return _json(200, _exercicioJson(exercicio));
    });
  }

  Future<Response> _buscarExercicios(Request req) async {
    final identidade = identidadeDaRequisicao(req);
    if (identidade == null) return _envelope(CodigoErro.tokenInvalido);
    final parametros = req.url.queryParameters;

    final limit = _parametroInteiro(parametros['limit'], padrao: _limitPadrao);
    if (limit == null || limit < 1 || limit > _limitMaximo) {
      return _campoInvalido(
        'limit',
        'Deve ser um inteiro de 1 a $_limitMaximo.',
      );
    }

    final offset = _parametroInteiro(parametros['offset'], padrao: 0);
    if (offset == null || offset < 0) {
      return _campoInvalido('offset', 'Deve ser um inteiro >= 0.');
    }

    return _executar(() async {
      final pagina = await _service.buscarExercicios(
        identidade: identidade,
        limit: limit,
        offset: offset,
      );
      return _json(
        200,
        paginaToJson(
          itens: pagina.itens.map(_exercicioJson).toList(),
          limit: limit,
          offset: offset,
          total: pagina.total,
        ),
      );
    });
  }

  /// Edita so os campos que vierem no corpo. Qualquer outra chave e
  /// recusada: ignorar faria o cliente achar que mudou.
  Future<Response> _atualizarExercicio(Request req, String id) {
    final identidade = identidadeDaRequisicao(req);
    if (identidade == null) {
      return Future.value(_envelope(CodigoErro.tokenInvalido));
    }
    return _comId(id, (idExercicio) async {
      final payload = await _lerObjeto(req);
      if (payload == null) {
        return _envelope(CodigoErro.jsonInvalido);
      }

      final formaInvalida = _validarEdicao(payload);
      if (formaInvalida != null) {
        return formaInvalida;
      }

      final exercicio = await _service.atualizar(
        idExercicio,
        identidade: identidade,
        nome: _texto(payload['nome']),
        instrucoes: _texto(payload['instrucoes']),
        descricao: _texto(payload['descricao']),
        dificuldade: payload['dificuldade'] as String?,
      );
      return _json(200, _exercicioJson(exercicio));
    });
  }

  /// Exclusao real. Exercicio usado em treino: 409 `REGISTRO_EM_USO`.
  Future<Response> _excluirExercicio(Request req, String id) {
    final identidade = identidadeDaRequisicao(req);
    if (identidade == null) {
      return Future.value(_envelope(CodigoErro.tokenInvalido));
    }
    return _comId(id, (idExercicio) async {
      await _service.excluir(idExercicio, identidade: identidade);
      return Response(204);
    });
  }

  // --- Validacao de forma ---

  /// Chaves fora de [_editaveis], corpo vazio e valor que nao e texto
  /// preenchido sao recusados; depois, tamanho e dificuldade.
  Response? _validarEdicao(Map<String, dynamic> payload) {
    final naoEditavel = payload.keys
        .where((chave) => !_editaveis.contains(chave))
        .firstOrNull;
    if (naoEditavel != null) {
      return _campoInvalido(
        naoEditavel,
        'Nao pode ser alterado por esta rota. '
        'Editaveis: ${_editaveis.join(', ')}.',
      );
    }

    if (payload.isEmpty) {
      return _envelope(
        CodigoErro.campoObrigatorio,
        mensagem: 'Informe ao menos um campo: ${_editaveis.join(', ')}.',
      );
    }

    // `null` ou "" nao apagam um campo. Vale tambem para `descricao`: a
    // rota nao limpa a descricao (campo nulo fica como esta).
    final vazio = payload.keys
        .where((chave) => _texto(payload[chave]) == null)
        .firstOrNull;
    if (vazio != null) {
      return _campoInvalido(vazio, 'Deve ser um texto nao vazio.');
    }

    return _validarForma(
      nome: _texto(payload['nome']),
      dificuldade: payload['dificuldade'],
    );
  }

  /// Confere so os campos informados. [dificuldade] chega como veio no JSON:
  /// precisa ser texto de uma das opcoes fixas.
  Response? _validarForma({String? nome, Object? dificuldade}) {
    if (nome != null && nome.trim().length > _nomeMax) {
      return _campoInvalido('nome', 'Deve ter de 1 a $_nomeMax caracteres.');
    }
    if (dificuldade != null &&
        !ExercicioService.dificuldades.contains(dificuldade)) {
      return _campoInvalido(
        'dificuldade',
        'Deve ser um de: ${ExercicioService.dificuldades.join(', ')}.',
      );
    }
    return null;
  }

  /// Texto preenchido, ou `null` se ausente, em branco ou nao texto.
  String? _texto(Object? valor) {
    if (valor is! String) return null;
    return valor.trim().isEmpty ? null : valor;
  }

  /// Ausente vira [padrao]; presente e nao inteiro vira `null` (400).
  int? _parametroInteiro(String? bruto, {required int padrao}) =>
      bruto == null ? padrao : int.tryParse(bruto);

  /// O corpo como objeto JSON, ou `null` se nao for um.
  Future<Map<String, dynamic>?> _lerObjeto(Request req) async {
    try {
      final corpo = jsonDecode(await req.readAsString());
      return corpo is Map<String, dynamic> ? corpo : null;
    } on FormatException {
      return null;
    }
  }

  // --- Resposta ---

  Future<Response> _comId(
    String id,
    Future<Response> Function(int idExercicio) acao,
  ) {
    final idExercicio = int.tryParse(id);
    if (idExercicio == null) {
      return Future.value(_campoInvalido('id', 'Deve ser um numero inteiro.'));
    }
    return _executar(() => acao(idExercicio));
  }

  /// Unico ponto que converte excecao em resposta HTTP.
  Future<Response> _executar(Future<Response> Function() acao) async {
    try {
      return await acao();
    } catch (erro, stackTrace) {
      return switch (erro) {
        AcessoNegado() => _envelope(CodigoErro.acessoNegado),
        ExercicioException(:final codigo, :final campo) => _envelope(
          codigo,
          campo: campo,
        ),
        pg.ServerException() => _erroDoBanco(erro, stackTrace),
        _ => _erroInterno(erro, stackTrace),
      };
    }
  }

  /// Falha do banco pelo tradutor unico; sem mapeamento, 500.
  Response _erroDoBanco(pg.ServerException erro, StackTrace stackTrace) {
    final codigo = traduzirErroBanco(erro);
    if (codigo == null) {
      return _erroInterno(erro, stackTrace);
    }
    return _envelope(codigo, campo: _campoDe(codigo));
  }

  /// A excecao vai so para o log; o cliente recebe apenas o codigo.
  Response _erroInterno(Object erro, StackTrace stackTrace) {
    // ignore: avoid_print
    print('Erro em /exercicio: $erro');
    // ignore: avoid_print
    print(stackTrace);
    return _envelope(CodigoErro.erroInterno);
  }

  /// Envelope `{ codigo, mensagem, campo? }` (`docs/arquitetura.md` §7,
  /// D64). [mensagem] substitui a de apoio quando o erro pede detalhe.
  Response _envelope(CodigoErro codigo, {String? campo, String? mensagem}) =>
      _json(statusHttp(codigo), {
        'codigo': codigo.valor,
        'mensagem': mensagem ?? _mensagemDeApoio(codigo),
        'campo': ?campo,
      });

  Response _campoInvalido(String campo, String mensagem) =>
      _envelope(CodigoErro.campoInvalido, campo: campo, mensagem: mensagem);

  Response _json(int status, Object corpo) => Response(
    status,
    body: jsonEncode(corpo),
    headers: {'Content-Type': 'application/json'},
  );

  String _mensagemDeApoio(CodigoErro codigo) => switch (codigo) {
    CodigoErro.nomeEmUso => 'Ja existe um exercicio com esse nome.',
    CodigoErro.tokenInvalido => 'Autenticacao necessaria.',
    CodigoErro.acessoNegado => 'Acesso negado.',
    CodigoErro.registroNaoEncontrado => 'Exercicio nao encontrado.',
    CodigoErro.registroEmUso =>
      'Exercicio esta em uso em algum treino e nao pode ser excluido.',
    CodigoErro.jsonInvalido => 'Corpo da requisicao nao e um JSON valido.',
    CodigoErro.campoObrigatorio => 'Campo obrigatorio ausente.',
    CodigoErro.campoInvalido => 'Campo em formato invalido.',
    CodigoErro.erroInterno => 'Erro interno no servidor.',
    _ => 'Requisicao rejeitada.',
  };

  String? _campoDe(CodigoErro codigo) => switch (codigo) {
    CodigoErro.nomeEmUso => 'nome',
    _ => null,
  };

  /// Toda resposta com exercicio passa por aqui: o DTO e um so.
  Map<String, dynamic> _exercicioJson(ExercicioData exercicio) =>
      exercicioToPublicJson(
        idExercicio: exercicio.idExercicio,
        nome: exercicio.nome,
        instrucoes: exercicio.instrucoes,
        descricao: exercicio.descricao,
        dificuldade: exercicio.dificuldade,
      );
}
