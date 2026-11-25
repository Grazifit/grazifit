import 'dart:convert';

import 'package:postgres/postgres.dart' as pg;
import 'package:shared/erros/codigo_erro.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../shared/autorizacao/identidade.dart';
import '../../shared/erros/status_http.dart';
import '../../shared/erros/tradutor_erro_banco.dart';
import '../../shared/middleware/identidade_middleware.dart';
import 'cronograma_model.dart';
import 'cronograma_service.dart';

class CronogramaController {
  CronogramaController(this.service);
  final CronogramaService service;
  Router get router => Router()
    ..post('/cronogramas', (Request r) => _executar(r))
    ..get('/cronogramas', (Request r) => _executar(r))
    ..get('/cronogramas/<id>', (Request r, String id) => _executar(r, id))
    ..patch('/cronogramas/<id>', (Request r, String id) => _executar(r, id))
    ..delete('/cronogramas/<id>', (Request r, String id) => _executar(r, id));

  Future<Response> _executar(Request r, [String? rawId]) async {
    final identidade = identidadeDaRequisicao(r);
    if (identidade == null) return _erro(CodigoErro.tokenInvalido);
    try {
      exigirAdmin(identidade);
      final id = rawId == null ? null : int.tryParse(rawId);
      if (rawId != null && (id == null || id <= 0 || id > 2147483647)) {
        return _erro(CodigoErro.campoInvalido, campo: 'id');
      }
      if (r.method == 'DELETE') {
        await service.excluir(identidade, id!);
        return Response(204);
      }
      if (r.method == 'GET') {
        if (id != null) {
          return _json(200, (await service.buscar(identidade, id)).toJson());
        }
        final p = r.url.queryParameters;
        for (final key in p.keys) {
          if (!{'limit', 'offset', 'status'}.contains(key)) {
            return _erro(CodigoErro.campoInvalido, campo: key);
          }
        }
        final limit = int.tryParse(p['limit'] ?? '20');
        final offset = int.tryParse(p['offset'] ?? '0');
        if (limit == null) {
          return _erro(CodigoErro.campoInvalido, campo: 'limit');
        }
        if (offset == null) {
          return _erro(CodigoErro.campoInvalido, campo: 'offset');
        }
        if (p.containsKey('status') &&
            !{'true', 'false'}.contains(p['status'])) {
          return _erro(CodigoErro.campoInvalido, campo: 'status');
        }
        return _json(
          200,
          await service.listar(
            identidade,
            limit: limit,
            offset: offset,
            status: p.containsKey('status') ? p['status'] == 'true' : null,
          ),
        );
      }
      Object? body;
      try {
        body = jsonDecode(await r.readAsString());
      } on FormatException {
        return _erro(CodigoErro.jsonInvalido);
      }
      if (body is! Map<String, dynamic>) return _erro(CodigoErro.jsonInvalido);
      final item = r.method == 'POST'
          ? await service.criar(identidade, body)
          : await service.atualizar(identidade, id!, body);
      return _json(r.method == 'POST' ? 201 : 200, item.toJson());
    } on AcessoNegado {
      return _erro(CodigoErro.acessoNegado);
    } on CronogramaException catch (e) {
      return _erro(e.codigo, campo: e.campo);
    } on pg.ServerException catch (e) {
      return _erro(traduzirErroBanco(e) ?? CodigoErro.erroInterno);
    }
  }

  Response _erro(CodigoErro codigo, {String? campo}) =>
      _json(statusHttp(codigo), {
        'codigo': codigo.valor,
        'mensagem': 'Operação rejeitada.',
        'campo': ?campo,
      });
  Response _json(int status, Object data) => Response(
    status,
    body: jsonEncode(data),
    headers: {'Content-Type': 'application/json; charset=utf-8'},
  );
}
