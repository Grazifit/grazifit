import 'dart:convert';

import 'package:postgres/postgres.dart' as pg;
import 'package:shared/dtos/aluno_serializer.dart';
import 'package:shared/dtos/pagina_serializer.dart';
import 'package:shared/erros/codigo_erro.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../database/database.dart' show AlunoData;
import '../../../shared/erros/status_http.dart';
import '../../../shared/erros/tradutor_erro_banco.dart';
import '../../../shared/erros/aluno_exception.dart';
import 'aluno_service.dart';

/// Forma da requisicao e montagem do DTO. Sem regra de negocio nem decisao
/// de permissao (`docs/guia-desenvolvimento.md` §4.3).
class AlunoController {
  final AlunoService _service;

  AlunoController(this._service);

  Router get router {
    final router = Router();
    router.post('/aluno', _createAluno);
    router.get('/aluno', _buscarAlunos);
    router.get('/aluno/<id>', _buscarAlunoPorId);
    router.patch('/aluno/<id>', _atualizarAluno);
    router.patch('/aluno/<id>/status', _alterarStatus);
    router.delete('/aluno/<id>', _excluirAluno);
    return router;
  }

  // Tamanhos aceitos — espelham as colunas de `aluno` no schema.
  static const int _nomeMax = 150;
  static const int _telefoneMax = 20;
  static const int _emailMax = 255;
  static const int _senhaMin = 8;
  static const int _senhaMax = 12;

  // Paginacao (`docs/guia-desenvolvimento.md` §6, "Listas").
  static const int _limitPadrao = 20;
  static const int _limitMaximo = 100;

  static const List<String> _editaveis = ['nome', 'telefone', 'email'];

  Future<Response> _createAluno(Request req) async {
    final payload = await _lerObjeto(req);
    if (payload == null) {
      return _envelope(CodigoErro.jsonInvalido);
    }

    final cpf = _texto(payload['cpf']);
    final senha = _texto(payload['senha']);
    final nome = _texto(payload['nome']);
    final telefone = _texto(payload['telefone']);
    final email = _texto(payload['email']);
    final dataNascimentoBruta = _texto(payload['data_nascimento']);

    for (final obrigatorio in {
      'cpf': cpf,
      'senha': senha,
      'nome': nome,
      'telefone': telefone,
      'email': email,
      'data_nascimento': dataNascimentoBruta,
    }.entries) {
      if (obrigatorio.value == null) {
        return _envelope(CodigoErro.campoObrigatorio, campo: obrigatorio.key);
      }
    }

    final dataNascimento = _dataCivil(dataNascimentoBruta!);
    if (dataNascimento == null) {
      return _campoInvalido(
        'data_nascimento',
        'Deve ser uma data existente no formato AAAA-MM-DD.',
      );
    }

    final tamanhoInvalido = _validarTamanhos(
      nome: nome,
      telefone: telefone,
      email: email,
      senha: senha,
    );
    if (tamanhoInvalido != null) {
      return tamanhoInvalido;
    }

    return _executar(() async {
      final aluno = await _service.criar(
        identidade: identidade,
        cpf: cpf!,
        senha: senha!,
        nome: nome!,
        dataNascimento: dataNascimento,
        telefone: telefone!,
        email: email!,
        idAdminCriador: identidade.id,
        idEndereco: _inteiro(payload['id_endereco']),
        restricaoMedica: _texto(payload['restricao_medica']),
        observacaoSaude: _texto(payload['observacao_saude']),
      );
      return _json(201, _alunoJson(aluno));
    });
  }

  Future<Response> _buscarAlunoPorId(Request req, String id) =>
      _comId(id, (idAluno) async {
        final aluno = await _service.buscarAlunoPorId(idAluno);
        return _json(200, _alunoJson(aluno));
      });

  Future<Response> _buscarAlunos(Request req) async {
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
      final pagina = await _service.buscarAlunos(limit: limit, offset: offset);
      return _json(
        200,
        paginaToJson(
          itens: pagina.itens.map(_alunoJson).toList(),
          limit: limit,
          offset: offset,
          total: pagina.total,
        ),
      );
    });
  }

  /// Edita nome, telefone e e-mail — so os que vierem no corpo. Qualquer
  /// outra chave e recusada: ignorar faria o cliente achar que mudou.
  Future<Response> _atualizarAluno(Request req, String id) =>
      _comId(id, (idAluno) async {
        final payload = await _lerObjeto(req);
        if (payload == null) {
          return _envelope(CodigoErro.jsonInvalido);
        }

        final formaInvalida = _validarEdicao(payload);
        if (formaInvalida != null) {
          return formaInvalida;
        }

        final aluno = await _service.atualizar(
          idAluno,
          nome: _texto(payload['nome']),
          telefone: _texto(payload['telefone']),
          email: _texto(payload['email']),
        );
        return _json(200, _alunoJson(aluno));
      });

  /// Corpo `{ "status": false }` inativa; `{ "status": true }` reativa.
  Future<Response> _alterarStatus(Request req, String id) =>
      _comId(id, (idAluno) async {
        final payload = await _lerObjeto(req);
        if (payload == null) {
          return _envelope(CodigoErro.jsonInvalido);
        }

        final status = payload['status'];
        if (status == null) {
          return _envelope(CodigoErro.campoObrigatorio, campo: 'status');
        }
        if (status is! bool) {
          return _campoInvalido('status', 'Deve ser true ou false.');
        }

        await _service.alterarStatus(idAluno, status: status);
        return Response(204);
      });

  /// Exclusao real. Aluno com historico: 409 `REGISTRO_EM_USO`.
  Future<Response> _excluirAluno(Request req, String id) =>
      _comId(id, (idAluno) async {
        await _service.excluir(idAluno);
        return Response(204);
      });

  // --- Validacao de forma ---

  /// Chaves fora de [_editaveis], corpo vazio e valor que nao e texto
  /// preenchido sao recusados; depois, os tamanhos.
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

    // `null` ou "" nao apagam um campo NOT NULL.
    final vazio = payload.keys
        .where((chave) => _texto(payload[chave]) == null)
        .firstOrNull;
    if (vazio != null) {
      return _campoInvalido(vazio, 'Deve ser um texto nao vazio.');
    }

    return _validarTamanhos(
      nome: _texto(payload['nome']),
      telefone: _texto(payload['telefone']),
      email: _texto(payload['email']),
    );
  }

  /// Confere so os campos informados. Nome, telefone e e-mail sao medidos
  /// sem os espacos das pontas, como serao gravados.
  Response? _validarTamanhos({
    String? nome,
    String? telefone,
    String? email,
    String? senha,
  }) {
    if (nome != null && nome.trim().length > _nomeMax) {
      return _campoInvalido('nome', 'Deve ter de 1 a $_nomeMax caracteres.');
    }
    if (telefone != null && telefone.trim().length > _telefoneMax) {
      return _campoInvalido(
        'telefone',
        'Deve ter ate $_telefoneMax caracteres.',
      );
    }
    if (email != null && email.trim().length > _emailMax) {
      return _campoInvalido('email', 'Deve ter ate $_emailMax caracteres.');
    }
    if (senha != null &&
        (senha.length < _senhaMin || senha.length > _senhaMax)) {
      return _campoInvalido(
        'senha',
        'Deve ter de $_senhaMin a $_senhaMax caracteres.',
      );
    }
    return null;
  }

  static final RegExp _formatoData = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Data `AAAA-MM-DD` estrita e existente no calendario
  /// (`openspec/changes/formato-data-contrato-rest/proposal.md`, D68).
  DateTime? _dataCivil(String bruto) {
    if (!_formatoData.hasMatch(bruto)) return null;

    final data = DateTime.tryParse(bruto);
    if (data == null) return null;

    String dois(int n) => n.toString().padLeft(2, '0');
    final normalizada =
        '${data.year.toString().padLeft(4, '0')}-'
        '${dois(data.month)}-${dois(data.day)}';

    return normalizada == bruto ? data : null;
  }

  /// Texto preenchido, ou `null` se ausente, em branco ou nao texto.
  String? _texto(Object? valor) {
    if (valor is! String) return null;
    return valor.trim().isEmpty ? null : valor;
  }

  int? _inteiro(Object? valor) => switch (valor) {
    final int i => i,
    final String s => int.tryParse(s),
    _ => null,
  };

  /// Ausente vira [padrao]; presente e nao inteiro vira `null` (400).
  /// `?limit=` vazio conta como presente: o cliente mandou algo errado.
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

  /// Converte o `<id>` da rota e executa [acao] com o tratamento de erro
  /// comum.
  Future<Response> _comId(
    String id,
    Future<Response> Function(int idAluno) acao,
  ) {
    final idAluno = int.tryParse(id);
    if (idAluno == null) {
      return Future.value(_campoInvalido('id', 'Deve ser um numero inteiro.'));
    }
    return _executar(() => acao(idAluno));
  }

  /// Unico ponto que converte excecao em resposta HTTP.
  Future<Response> _executar(Future<Response> Function() acao) async {
    try {
      return await acao();
    } catch (erro, stackTrace) {
      return switch (erro) {
        AlunoException(:final codigo, :final campo) => _envelope(
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
    print('Erro em /aluno: $erro');
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
    CodigoErro.cpfInvalido => 'CPF em formato invalido.',
    CodigoErro.emailInvalido => 'E-mail em formato invalido.',
    CodigoErro.cpfEmUso => 'CPF ja cadastrado.',
    CodigoErro.emailEmUso => 'E-mail ja cadastrado.',
    CodigoErro.dataNascimentoInvalida =>
      'Data de nascimento deve ser anterior a hoje.',
    CodigoErro.registroNaoEncontrado => 'Aluno nao encontrado.',
    CodigoErro.registroEmUso =>
      'Aluno possui historico e nao pode ser excluido. Inative-o.',
    CodigoErro.jsonInvalido => 'Corpo da requisicao nao e um JSON valido.',
    CodigoErro.campoObrigatorio => 'Campo obrigatorio ausente.',
    CodigoErro.campoInvalido => 'Campo em formato invalido.',
    CodigoErro.erroInterno => 'Erro interno no servidor.',
    _ => 'Requisicao rejeitada.',
  };

  String? _campoDe(CodigoErro codigo) => switch (codigo) {
    CodigoErro.cpfEmUso || CodigoErro.cpfInvalido => 'cpf',
    CodigoErro.emailEmUso || CodigoErro.emailInvalido => 'email',
    CodigoErro.dataNascimentoInvalida => 'data_nascimento',
    _ => null,
  };

  /// Toda resposta com aluno passa por aqui: o DTO e um so.
  Map<String, dynamic> _alunoJson(AlunoData aluno) => alunoToPublicJson(
    idAluno: aluno.idAluno,
    nome: aluno.nome,
    email: aluno.email,
    telefone: aluno.telefone,
    status: aluno.status,
  );
}
