import 'dart:convert';

import 'package:postgres/postgres.dart' as pg;
import 'package:shared/dtos/agendamento_serializer.dart';
import 'package:shared/dtos/aula_agendado_serializer.dart';
import 'package:shared/dtos/aula_serializer.dart';
import 'package:shared/dtos/pagina_serializer.dart';
import 'package:shared/erros/codigo_erro.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../database/database.dart' show AgendamentoData, AulaData;
import '../../shared/autorizacao/identidade.dart';
import '../../shared/erros/agendamento_exception.dart';
import '../../shared/erros/aula_exception.dart';
import '../../shared/erros/status_http.dart';
import '../../shared/erros/tradutor_erro_banco.dart';
import '../../shared/middleware/identidade_middleware.dart';
import '../agendamentos/agendamento_service.dart';
import 'aula_repository.dart' show AgendadoDaAula;
import 'aula_service.dart';

/// Valida a forma da requisicao e monta o DTO; regras ficam no service.
class AulaController {
  final AulaService _service;

  final AgendamentoService _agendamentos;

  AulaController(this._service, this._agendamentos);

  Router get router {
    final router = Router();
    router.post('/aulas', _criar);
    router.get('/aulas', _listar);
    router.get('/aulas/<id>', _buscarPorId);
    router.patch('/aulas/<id>', _atualizar);
    router.post('/aulas/<id>/cancelar', _cancelar);
    router.get('/aulas/<id>/agendamentos', _listarAgendados);
    router.patch('/aulas/<id>/chamada', _chamada);
    return router;
  }

  static const int _limitPadrao = 20;
  static const int _limitMaximo = 100;

  static const List<String> _camposAula = [
    'id_professor',
    'data',
    'hora_inicio',
    'hora_fim',
    'tipo',
    'categoria',
    'vagas_maxima',
  ];

  Future<Response> _criar(Request req) async {
    final identidade = identidadeDaRequisicao(req);
    if (identidade == null) return _envelope(CodigoErro.tokenInvalido);

    final payload = await _lerObjeto(req);
    if (payload == null) return _envelope(CodigoErro.jsonInvalido);

    final ausente = _camposAula
        .where((campo) => payload[campo] == null)
        .firstOrNull;
    if (ausente != null) {
      return _envelope(CodigoErro.campoObrigatorio, campo: ausente);
    }

    final desconhecido = _chaveDesconhecida(payload);
    if (desconhecido != null) return desconhecido;

    final forma = _lerCampos(payload);
    if (forma.erro != null) return forma.erro!;
    final c = forma.campos;

    return _executar(() async {
      final aula = await _service.criar(
        identidade: identidade,
        idProfessor: c.idProfessor!,
        data: c.data!,
        horaInicio: c.horaInicio!,
        horaFim: c.horaFim!,
        tipo: c.tipo!,
        categoria: c.categoria!,
        vagasMaxima: c.vagasMaxima!,
      );
      return _json(201, _aulaJson(aula, ocupadas: 0));
    });
  }

  Future<Response> _listar(Request req) async {
    final identidade = identidadeDaRequisicao(req);
    if (identidade == null) return _envelope(CodigoErro.tokenInvalido);
    final parametros = req.url.queryParameters;

    final paginacao = _paginacao(parametros);
    if (paginacao.erro != null) return paginacao.erro!;
    final (:limit, :offset, erro: _) = paginacao;

    final dataBruta = parametros['data'];
    final data = dataBruta == null ? null : _dataCivil(dataBruta);
    if (dataBruta != null && data == null) {
      return _campoInvalido('data', 'Deve ser uma data existente AAAA-MM-DD.');
    }

    final idProfessorBruto = parametros['idProfessor'];
    final idProfessor = idProfessorBruto == null
        ? null
        : int.tryParse(idProfessorBruto);
    if (idProfessorBruto != null && idProfessor == null) {
      return _campoInvalido('idProfessor', 'Deve ser um numero inteiro.');
    }

    final categoria = parametros['categoria'];
    if (categoria != null && categoria.isEmpty) {
      return _campoInvalido('categoria', 'Nao pode ser vazio.');
    }

    return _executar(() async {
      final pagina = await _service.listar(
        identidade,
        limit: limit,
        offset: offset,
        data: data,
        categoria: categoria,
        idProfessor: idProfessor,
      );
      final ocupadas = await _service.vagasOcupadas(identidade, [
        for (final aula in pagina.itens) aula.idAula,
      ]);
      return _json(
        200,
        paginaToJson(
          itens: [
            for (final aula in pagina.itens)
              _aulaJson(aula, ocupadas: ocupadas[aula.idAula]!),
          ],
          limit: limit,
          offset: offset,
          total: pagina.total,
        ),
      );
    });
  }

  Future<Response> _buscarPorId(Request req, String id) {
    final identidade = identidadeDaRequisicao(req);
    if (identidade == null) {
      return Future.value(_envelope(CodigoErro.tokenInvalido));
    }
    return _comId(id, (idAula) async {
      final aula = await _service.buscarPorId(identidade, idAula);
      return _json(200, await _aulaComOcupacao(identidade, aula));
    });
  }

  /// So os campos enviados; chave desconhecida e recusada.
  Future<Response> _atualizar(Request req, String id) {
    final identidade = identidadeDaRequisicao(req);
    if (identidade == null) {
      return Future.value(_envelope(CodigoErro.tokenInvalido));
    }
    return _comId(id, (idAula) async {
      final payload = await _lerObjeto(req);
      if (payload == null) return _envelope(CodigoErro.jsonInvalido);

      final desconhecido = _chaveDesconhecida(payload);
      if (desconhecido != null) return desconhecido;

      if (payload.isEmpty) {
        return _envelope(
          CodigoErro.campoObrigatorio,
          mensagem: 'Informe ao menos um campo: ${_camposAula.join(', ')}.',
        );
      }

      final nulo = payload.keys.where((k) => payload[k] == null).firstOrNull;
      if (nulo != null) return _campoInvalido(nulo, 'Nao pode ser nulo.');

      final forma = _lerCampos(payload);
      if (forma.erro != null) return forma.erro!;
      final c = forma.campos;

      final aula = await _service.atualizar(
        identidade: identidade,
        idAula: idAula,
        idProfessor: c.idProfessor,
        data: c.data,
        horaInicio: c.horaInicio,
        horaFim: c.horaFim,
        tipo: c.tipo,
        categoria: c.categoria,
        vagasMaxima: c.vagasMaxima,
      );
      return _json(200, await _aulaComOcupacao(identidade, aula));
    });
  }

  /// Sem corpo; o que vier e ignorado.
  Future<Response> _cancelar(Request req, String id) {
    final identidade = identidadeDaRequisicao(req);
    if (identidade == null) {
      return Future.value(_envelope(CodigoErro.tokenInvalido));
    }
    return _comId(id, (idAula) async {
      final aula = await _service.cancelar(
        identidade: identidade,
        idAula: idAula,
      );
      return _json(200, await _aulaComOcupacao(identidade, aula));
    });
  }

  /// Sem cancelados; mesma paginacao de `GET /aulas`.
  Future<Response> _listarAgendados(Request req, String id) {
    final identidade = identidadeDaRequisicao(req);
    if (identidade == null) {
      return Future.value(_envelope(CodigoErro.tokenInvalido));
    }
    final paginacao = _paginacao(req.url.queryParameters);
    if (paginacao.erro != null) return Future.value(paginacao.erro!);
    final (:limit, :offset, erro: _) = paginacao;

    return _comId(id, (idAula) async {
      final pagina = await _service.listarAgendados(
        identidade,
        idAula,
        limit: limit,
        offset: offset,
      );
      return _json(
        200,
        paginaToJson(
          itens: pagina.itens.map(_agendadoJson).toList(),
          limit: limit,
          offset: offset,
          total: pagina.total,
        ),
      );
    });
  }

  /// Corpo: lista de `{id, status}`. Regras de presenca no service.
  Future<Response> _chamada(Request req, String id) {
    final identidade = identidadeDaRequisicao(req);
    if (identidade == null) {
      return Future.value(_envelope(CodigoErro.tokenInvalido));
    }
    return _comId(id, (idAula) async {
      final lida = await _lerPresencas(req);
      if (lida.erro != null) return lida.erro!;
      final atualizados = await _agendamentos.registrarChamada(
        identidade: identidade,
        idAula: idAula,
        itens: lida.itens!,
      );
      return _json(200, {
        'itens': [for (final a in atualizados) _agendamentoDaChamadaJson(a)],
      });
    });
  }

  /// So a forma: lista de objetos com `id` inteiro e `status` aceito.
  /// Duplicidade, pertencimento e estado ficam no service.
  Future<({List<PresencaInformada>? itens, Response? erro})> _lerPresencas(
    Request req,
  ) async {
    Object? corpo;
    try {
      corpo = jsonDecode(await req.readAsString());
    } on FormatException {
      return (itens: null, erro: _envelope(CodigoErro.jsonInvalido));
    }
    if (corpo is! List) {
      return (
        itens: null,
        erro: _campoInvalido('corpo', 'Deve ser uma lista de {id, status}.'),
      );
    }

    final itens = <PresencaInformada>[];
    for (final entrada in corpo) {
      if (entrada is! Map<String, dynamic>) {
        return (
          itens: null,
          erro: _campoInvalido(
            'corpo',
            'Cada item deve ser um objeto {id, status}.',
          ),
        );
      }
      final desconhecido = entrada.keys
          .where((k) => k != 'id' && k != 'status')
          .firstOrNull;
      if (desconhecido != null) {
        return (
          itens: null,
          erro: _campoInvalido(
            desconhecido,
            'Campo nao aceito. Aceitos: id, status.',
          ),
        );
      }
      final id = entrada['id'];
      if (id == null) {
        return (
          itens: null,
          erro: _envelope(CodigoErro.campoObrigatorio, campo: 'id'),
        );
      }
      if (id is! int) {
        return (
          itens: null,
          erro: _campoInvalido('id', 'Deve ser um numero inteiro.'),
        );
      }
      final status = entrada['status'];
      if (status == null) {
        return (
          itens: null,
          erro: _envelope(CodigoErro.campoObrigatorio, campo: 'status'),
        );
      }
      if (status != 'presente' && status != 'faltou') {
        return (
          itens: null,
          erro: _campoInvalido(
            'status',
            'Valores aceitos: presente, faltou.',
          ),
        );
      }
      itens.add(
        PresencaInformada(idAgendamento: id, presente: status == 'presente'),
      );
    }
    return (itens: itens, erro: null);
  }

  ({int limit, int offset, Response? erro}) _paginacao(
    Map<String, String> parametros,
  ) {
    final limit = _parametroInteiro(parametros['limit'], padrao: _limitPadrao);
    if (limit == null || limit < 1 || limit > _limitMaximo) {
      return (
        limit: 0,
        offset: 0,
        erro: _campoInvalido(
          'limit',
          'Deve ser um inteiro de 1 a $_limitMaximo.',
        ),
      );
    }

    final offset = _parametroInteiro(parametros['offset'], padrao: 0);
    if (offset == null || offset < 0) {
      return (
        limit: 0,
        offset: 0,
        erro: _campoInvalido('offset', 'Deve ser um inteiro >= 0.'),
      );
    }
    return (limit: limit, offset: offset, erro: null);
  }

  /// Ausente vira `null`; presente e invalido devolve 400.
  ({_CamposAula campos, Response? erro}) _lerCampos(
    Map<String, dynamic> payload,
  ) {
    ({_CamposAula campos, Response? erro}) falha(String campo, String msg) =>
        (campos: const _CamposAula(), erro: _campoInvalido(campo, msg));

    int? idProfessor;
    if (payload.containsKey('id_professor')) {
      idProfessor = _inteiroJson(payload['id_professor']);
      if (idProfessor == null) {
        return falha('id_professor', 'Deve ser um numero inteiro.');
      }
    }

    int? vagas;
    if (payload.containsKey('vagas_maxima')) {
      vagas = _inteiroJson(payload['vagas_maxima']);
      if (vagas == null) {
        return falha('vagas_maxima', 'Deve ser um numero inteiro.');
      }
    }

    DateTime? data;
    if (payload.containsKey('data')) {
      final bruto = payload['data'];
      data = bruto is String ? _dataCivil(bruto) : null;
      if (data == null) {
        return falha('data', 'Deve ser uma data existente AAAA-MM-DD.');
      }
    }

    Duration? horaInicio;
    if (payload.containsKey('hora_inicio')) {
      horaInicio = _hora(payload['hora_inicio']);
      if (horaInicio == null) {
        return falha('hora_inicio', 'Deve estar no formato HH:MM.');
      }
    }

    Duration? horaFim;
    if (payload.containsKey('hora_fim')) {
      horaFim = _hora(payload['hora_fim']);
      if (horaFim == null) {
        return falha('hora_fim', 'Deve estar no formato HH:MM.');
      }
    }

    String? tipo;
    if (payload.containsKey('tipo')) {
      tipo = _texto(payload['tipo']);
      if (tipo == null) return falha('tipo', 'Deve ser um texto nao vazio.');
    }

    String? categoria;
    if (payload.containsKey('categoria')) {
      categoria = _texto(payload['categoria']);
      if (categoria == null) {
        return falha('categoria', 'Deve ser um texto nao vazio.');
      }
    }

    return (
      campos: _CamposAula(
        idProfessor: idProfessor,
        data: data,
        horaInicio: horaInicio,
        horaFim: horaFim,
        tipo: tipo,
        categoria: categoria,
        vagasMaxima: vagas,
      ),
      erro: null,
    );
  }

  Response? _chaveDesconhecida(Map<String, dynamic> payload) {
    final chave = payload.keys
        .where((k) => !_camposAula.contains(k))
        .firstOrNull;
    if (chave == null) return null;
    return _campoInvalido(
      chave,
      'Campo nao aceito. Aceitos: ${_camposAula.join(', ')}.',
    );
  }

  static final RegExp _formatoData = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static final RegExp _formatoHora = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

  /// `AAAA-MM-DD` existente; recusa o rollover do parse (ex.: 2025-02-30).
  DateTime? _dataCivil(String bruto) {
    if (!_formatoData.hasMatch(bruto)) return null;
    final data = DateTime.tryParse(bruto);
    if (data == null) return null;
    return dataParaJson(data) == bruto ? data : null;
  }

  Duration? _hora(Object? bruto) {
    if (bruto is! String) return null;
    final m = _formatoHora.firstMatch(bruto);
    if (m == null) return null;
    return Duration(
      hours: int.parse(m.group(1)!),
      minutes: int.parse(m.group(2)!),
    );
  }

  int? _inteiroJson(Object? valor) => valor is int ? valor : null;

  String? _texto(Object? valor) {
    if (valor is! String) return null;
    final limpo = valor.trim();
    return limpo.isEmpty ? null : limpo;
  }

  int? _parametroInteiro(String? bruto, {required int padrao}) =>
      bruto == null ? padrao : int.tryParse(bruto);

  Future<Map<String, dynamic>?> _lerObjeto(Request req) async {
    try {
      final corpo = jsonDecode(await req.readAsString());
      return corpo is Map<String, dynamic> ? corpo : null;
    } on FormatException {
      return null;
    }
  }

  Future<Response> _comId(
    String id,
    Future<Response> Function(int idAula) acao,
  ) {
    final idAula = int.tryParse(id);
    if (idAula == null) {
      return Future.value(_campoInvalido('id', 'Deve ser um numero inteiro.'));
    }
    return _executar(() => acao(idAula));
  }

  Future<Response> _executar(Future<Response> Function() acao) async {
    try {
      return await acao();
    } catch (erro, stackTrace) {
      return switch (erro) {
        AcessoNegado() => _envelope(CodigoErro.acessoNegado),
        AulaException(:final codigo, :final campo) => _envelope(
          codigo,
          campo: campo,
        ),
        ChamadaException(:final codigo, :final campo, :final mensagem) =>
          _envelope(codigo, campo: campo, mensagem: mensagem),
        AgendamentoException(:final codigo, :final campo, :final mensagem) =>
          _envelope(codigo, campo: campo, mensagem: mensagem),
        pg.ServerException() => _erroDoBanco(erro, stackTrace),
        _ => _erroInterno(erro, stackTrace),
      };
    }
  }

  /// Sem mapeamento no tradutor, vira 500.
  Response _erroDoBanco(pg.ServerException erro, StackTrace stackTrace) {
    final codigo = traduzirErroBanco(erro);
    if (codigo == null) return _erroInterno(erro, stackTrace);
    return _envelope(codigo);
  }

  Response _erroInterno(Object erro, StackTrace stackTrace) {
    // ignore: avoid_print
    print('Erro em /aulas: $erro');
    // ignore: avoid_print
    print(stackTrace);
    return _envelope(CodigoErro.erroInterno);
  }

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
    CodigoErro.tokenInvalido => 'Autenticacao necessaria.',
    CodigoErro.acessoNegado => 'Acesso negado.',
    CodigoErro.registroNaoEncontrado => 'Aula nao encontrada.',
    CodigoErro.aulaInativa => 'Aula cancelada nao pode ser editada.',
    CodigoErro.aulaDataPassada => 'Aula ja realizada nao pode ser cancelada.',
    CodigoErro.registroEmUso =>
      'Aula com agendamentos: data, horario e professor ficam travados e '
          'as vagas nao descem abaixo da ocupacao.',
    CodigoErro.horarioConflitante =>
      'O professor ja tem aula nesta data e horario.',
    CodigoErro.aulaCategoriaDivergente =>
      'Categoria difere da do cronograma da aula.',
    CodigoErro.aulaProfessorDivergente =>
      'Professor difere do do cronograma da aula.',
    CodigoErro.aulaSemVagas => 'Aula sem vagas disponiveis.',
    CodigoErro.jsonInvalido => 'Corpo da requisicao nao e um JSON valido.',
    CodigoErro.campoObrigatorio => 'Campo obrigatorio ausente.',
    CodigoErro.campoInvalido => 'Campo invalido.',
    CodigoErro.erroInterno => 'Erro interno no servidor.',
    _ => 'Requisicao rejeitada.',
  };

  Future<Map<String, dynamic>> _aulaComOcupacao(
    Identidade identidade,
    AulaData aula,
  ) async {
    final ocupadas = await _service.vagasOcupadas(identidade, [aula.idAula]);
    return _aulaJson(aula, ocupadas: ocupadas[aula.idAula]!);
  }

  Map<String, dynamic> _aulaJson(AulaData aula, {required int ocupadas}) =>
      aulaToJson(
        idAula: aula.idAula,
        idProfessor: aula.idProfessor,
        idCronograma: aula.idCronograma,
        data: aula.data.toDateTime(),
        horaInicio: Duration(microseconds: aula.horaInicio.microseconds),
        horaFim: Duration(microseconds: aula.horaFim.microseconds),
        tipo: aula.tipo,
        categoria: aula.categoria,
        vagasMaxima: aula.vagasMaxima,
        status: aula.status,
        dataCancelamento: aula.dataCancelamento?.dateTime,
        idProfessorCancelou: aula.idProfessorCancelou,
        idAdminCancelou: aula.idAdminCancelou,
        vagasOcupadas: ocupadas,
      );

  Map<String, dynamic> _agendamentoDaChamadaJson(AgendamentoData a) =>
      agendamentoToJson(
        idAgendamento: a.idAgendamento,
        idAluno: a.idAluno,
        idAula: a.idAula,
        dataAgendamento: a.dataAgendamento.toDateTime(),
        status: a.status,
        dataPresenca: a.dataPresenca?.toDateTime(),
        dataCancelamento: a.dataCancelamento?.toDateTime(),
      );

  Map<String, dynamic> _agendadoJson(AgendadoDaAula a) => aulaAgendadoToJson(
    idAgendamento: a.idAgendamento,
    idAluno: a.idAluno,
    nomeAluno: a.nomeAluno,
    status: a.status,
  );
}

class _CamposAula {
  final int? idProfessor;
  final DateTime? data;
  final Duration? horaInicio;
  final Duration? horaFim;
  final String? tipo;
  final String? categoria;
  final int? vagasMaxima;

  const _CamposAula({
    this.idProfessor,
    this.data,
    this.horaInicio,
    this.horaFim,
    this.tipo,
    this.categoria,
    this.vagasMaxima,
  });
}
