import 'package:postgres/postgres.dart' as pg;
import 'package:shared/dtos/agendamento_serializer.dart';
import 'package:shared/dtos/pagina_serializer.dart';
import 'package:shared/erros/codigo_erro.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../database/database.dart' show AgendamentoData;
import '../../shared/autorizacao/identidade.dart';
import '../../shared/erros/agendamento_exception.dart';
import '../../shared/erros/aula_exception.dart';
import '../../shared/erros/tradutor_erro_banco.dart';
import '../../shared/http/respostas.dart';
import '../../shared/limite/limitador_janela.dart';
import '../../shared/middleware/identidade_middleware.dart';
import 'agendamento_service.dart';

/// Valida a forma da requisicao e monta a resposta; regras ficam no service.
///
/// Limite de requisicoes por usuario autenticado nas rotas que escrevem
/// (POST e PATCH). Fica aqui, e nao no service, para os testes de
/// concorrencia do service nao serem afetados.
class AgendamentoController {
  final AgendamentoService _service;
  final LimitadorJanela _limitePost;
  final LimitadorJanela _limitePatch;

  AgendamentoController(
    this._service, {
    LimitadorJanela? limitePost,
    LimitadorJanela? limitePatch,
  }) : _limitePost =
           limitePost ??
           LimitadorJanela(maximo: 10, janela: const Duration(minutes: 1)),
       _limitePatch =
           limitePatch ??
           LimitadorJanela(maximo: 20, janela: const Duration(minutes: 1));

  Router get router {
    final router = Router();
    router.post('/agendamentos', _reservar);
    router.get('/agendamentos', _listar);
    router.patch('/agendamentos/<id>', _atualizar);
    return router;
  }

  static const int _limitPadrao = 20;
  static const int _limitMaximo = 100;

  Future<Response> _reservar(Request req) async {
    final identidade = identidadeDaRequisicao(req);
    if (identidade == null) return _envelope(CodigoErro.tokenInvalido);
    final espera = _limitePost.registrar((identidade.papel, identidade.id));
    if (espera != null) return _limite(espera);

    final payload = await lerObjetoJson(req);
    if (payload == null) return _envelope(CodigoErro.jsonInvalido);

    if (!payload.containsKey('id_aula') || payload['id_aula'] == null) {
      return _envelope(CodigoErro.campoObrigatorio, campo: 'id_aula');
    }
    final desconhecido = chaveDesconhecida(payload, const ['id_aula']);
    if (desconhecido != null) return desconhecido;

    final idAula = payload['id_aula'];
    if (idAula is! int) {
      return campoInvalido('id_aula', 'Deve ser um numero inteiro.');
    }

    return _executar(() async {
      final agendamento = await _service.reservar(
        identidade: identidade,
        idAula: idAula,
      );
      return jsonResposta(201, _agendamentoJson(agendamento));
    });
  }

  Future<Response> _listar(Request req) async {
    final identidade = identidadeDaRequisicao(req);
    if (identidade == null) return _envelope(CodigoErro.tokenInvalido);
    final parametros = req.url.queryParameters;

    final limit = _parametroInteiro(parametros['limit'], padrao: _limitPadrao);
    if (limit == null || limit < 1 || limit > _limitMaximo) {
      return campoInvalido(
        'limit',
        'Deve ser um inteiro de 1 a $_limitMaximo.',
      );
    }

    final offset = _parametroInteiro(parametros['offset'], padrao: 0);
    if (offset == null || offset < 0) {
      return campoInvalido('offset', 'Deve ser um inteiro >= 0.');
    }

    return _executar(() async {
      final pagina = await _service.listarDoAluno(
        identidade,
        limit: limit,
        offset: offset,
      );
      return jsonResposta(
        200,
        paginaToJson(
          itens: pagina.itens.map(_agendamentoJson).toList(),
          limit: limit,
          offset: offset,
          total: pagina.total,
        ),
      );
    });
  }

  /// Corpo aceito: so `{"status": "cancelado"}`.
  Future<Response> _atualizar(Request req, String id) async {
    final identidade = identidadeDaRequisicao(req);
    if (identidade == null) return _envelope(CodigoErro.tokenInvalido);
    final espera = _limitePatch.registrar((identidade.papel, identidade.id));
    if (espera != null) return _limite(espera);

    final idAgendamento = int.tryParse(id);
    if (idAgendamento == null) {
      return campoInvalido('id', 'Deve ser um numero inteiro.');
    }

    final payload = await lerObjetoJson(req);
    if (payload == null) return _envelope(CodigoErro.jsonInvalido);

    final desconhecido = chaveDesconhecida(payload, const ['status']);
    if (desconhecido != null) return desconhecido;

    if (!payload.containsKey('status') || payload['status'] == null) {
      return _envelope(CodigoErro.campoObrigatorio, campo: 'status');
    }
    if (payload['status'] != 'cancelado') {
      return campoInvalido('status', 'Unico valor aceito: cancelado.');
    }

    return _executar(() async {
      final agendamento = await _service.cancelar(
        identidade: identidade,
        idAgendamento: idAgendamento,
      );
      return jsonResposta(200, _agendamentoJson(agendamento));
    });
  }

  int? _parametroInteiro(String? bruto, {required int padrao}) =>
      bruto == null ? padrao : int.tryParse(bruto);

  Future<Response> _executar(Future<Response> Function() acao) async {
    try {
      return await acao();
    } catch (erro, stackTrace) {
      return switch (erro) {
        AcessoNegado() => _envelope(CodigoErro.acessoNegado),
        AgendamentoException(:final codigo, :final campo, :final mensagem) =>
          _envelope(codigo, campo: campo, mensagem: mensagem),
        // Validacao de vigencia reaproveitada da feature aulas (CA-9).
        AulaException(:final codigo, :final campo) => _envelope(
          codigo,
          campo: campo,
        ),
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

  Response _erroInterno(Object erro, StackTrace stackTrace) =>
      erroInterno(erro, stackTrace, rotulo: '/agendamentos');

  /// 429 com `Retry-After`, no envelope de erro. Mesmo codigo do login.
  Response _limite(int segundos) => _envelope(
    CodigoErro.muitasTentativas,
    mensagem: 'Muitas tentativas. Tente novamente mais tarde.',
    headers: {'Retry-After': '$segundos'},
  );

  Response _envelope(
    CodigoErro codigo, {
    String? campo,
    String? mensagem,
    Map<String, String>? headers,
  }) => envelopeErro(
    codigo,
    mensagem: mensagem ?? _mensagemDeApoio(codigo),
    campo: campo,
    headers: headers,
  );

  String _mensagemDeApoio(CodigoErro codigo) => switch (codigo) {
    CodigoErro.tokenInvalido => 'Autenticacao necessaria.',
    CodigoErro.acessoNegado => 'Acesso negado.',
    CodigoErro.registroNaoEncontrado => 'Registro nao encontrado.',
    CodigoErro.aulaInativa => 'Aula cancelada nao aceita agendamento.',
    CodigoErro.aulaDataPassada =>
      'Aula com data anterior a hoje nao aceita agendamento.',
    CodigoErro.aulaSemVagas => 'Aula sem vagas disponiveis.',
    CodigoErro.agendamentoDuplicado => 'Voce ja tem agendamento nesta aula.',
    CodigoErro.agendamentoForaDaJanela => 'Agendar ou cancelar exige ao menos 2 horas de antecedencia do inicio da aula.',
    CodigoErro.jsonInvalido => 'Corpo da requisicao nao e um JSON valido.',
    CodigoErro.campoObrigatorio => 'Campo obrigatorio ausente.',
    CodigoErro.campoInvalido => 'Campo invalido.',
    CodigoErro.erroInterno => 'Erro interno no servidor.',
    _ => 'Requisicao rejeitada.',
  };

  Map<String, dynamic> _agendamentoJson(AgendamentoData a) => agendamentoToJson(
    idAgendamento: a.idAgendamento,
    idAluno: a.idAluno,
    idAula: a.idAula,
    dataAgendamento: a.dataAgendamento.toDateTime(),
    status: a.status,
    dataPresenca: a.dataPresenca?.toDateTime(),
    dataCancelamento: a.dataCancelamento?.toDateTime(),
  );
}
