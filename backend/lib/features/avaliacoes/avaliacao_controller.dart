import 'dart:convert';

import 'package:postgres/postgres.dart' as pg;
import 'package:shared/dtos/pagina_serializer.dart';
import 'package:shared/erros/codigo_erro.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../shared/autorizacao/identidade.dart';
import '../../shared/erros/status_http.dart';
import '../../shared/middleware/identidade_middleware.dart';
import 'avaliacao_exception.dart';
import 'avaliacao_service.dart';

class AvaliacaoController {
  AvaliacaoController(this.service);
  final AvaliacaoService service;
  Router get router => Router()
    ..post(
      '/aluno/<id>/avaliacoes/hoje',
      (Request r, String id) => _executar(r, id, 'salvar'),
    )
    ..get(
      '/aluno/<id>/avaliacoes/atual',
      (Request r, String id) => _executar(r, id, 'atual'),
    )
    ..get(
      '/aluno/<id>/avaliacoes',
      (Request r, String id) => _executar(r, id, 'listar'),
    );

  Future<Response> _executar(Request req, String rawId, String acao) async {
    final identidade = identidadeDaRequisicao(req);
    if (identidade == null) return _erro(CodigoErro.tokenInvalido);
    final id = int.tryParse(rawId);
    if (id == null || id <= 0) {
      return _erro(CodigoErro.campoInvalido, campo: 'id');
    }
    try {
      if (acao == 'salvar') {
        Object? decoded;
        try {
          decoded = jsonDecode(await req.readAsString());
        } on FormatException {
          return _erro(CodigoErro.jsonInvalido);
        }
        if (decoded is! Map<String, dynamic>) {
          return _erro(CodigoErro.jsonInvalido);
        }
        for (final key in decoded.keys) {
          if (!['peso', 'altura', 'observacao'].contains(key)) {
            return _erro(CodigoErro.campoInvalido, campo: key);
          }
        }
        for (final key in ['peso', 'altura']) {
          if (!decoded.containsKey(key)) {
            return _erro(CodigoErro.campoObrigatorio, campo: key);
          }
          if (decoded[key] is! num) {
            return _erro(CodigoErro.campoInvalido, campo: key);
          }
        }
        if (decoded['observacao'] != null && decoded['observacao'] is! String) {
          return _erro(CodigoErro.campoInvalido, campo: 'observacao');
        }
        final item = await service.salvarHoje(
          identidade,
          id,
          peso: (decoded['peso'] as num).toDouble(),
          altura: (decoded['altura'] as num).toDouble(),
          observacao: decoded['observacao'] as String?,
        );
        return _json(200, item.toJson());
      }
      if (acao == 'atual') {
        final item = await service.atual(identidade, id);
        return item == null ? Response(204) : _json(200, item.toJson());
      }
      final params = req.url.queryParameters;
      final limit = params.containsKey('limit')
          ? int.tryParse(params['limit']!)
          : 20;
      final offset = params.containsKey('offset')
          ? int.tryParse(params['offset']!)
          : 0;
      if (limit == null) return _erro(CodigoErro.campoInvalido, campo: 'limit');
      if (offset == null) {
        return _erro(CodigoErro.campoInvalido, campo: 'offset');
      }
      final pagina = await service.listar(
        identidade,
        id,
        limit: limit,
        offset: offset,
      );
      return _json(
        200,
        paginaToJson(
          itens: pagina.itens.map((i) => i.toJson()).toList(),
          limit: limit,
          offset: offset,
          total: pagina.total,
        ),
      );
    } on AcessoNegado {
      return _erro(CodigoErro.acessoNegado);
    } on AvaliacaoException catch (e) {
      return _erro(e.codigo, campo: e.campo);
    } on pg.ServerException catch (e) {
      // Medidas validas individualmente podem exceder NUMERIC(5,2) do IMC.
      if (e.code == '22003') {
        return _erro(CodigoErro.campoInvalido, campo: 'medidas');
      }
      return _erro(CodigoErro.erroInterno);
    } catch (_) {
      return _erro(CodigoErro.erroInterno);
    }
  }

  Response _erro(CodigoErro codigo, {String? campo}) =>
      _json(statusHttp(codigo), {
        'codigo': codigo.valor,
        'mensagem': 'Operacao rejeitada.',
        'campo': ?campo,
      });
  Response _json(int status, Object body) => Response(
    status,
    body: jsonEncode(body),
    headers: {'Content-Type': 'application/json; charset=utf-8'},
  );
}
