import 'package:shared/dtos/pagina_serializer.dart';
import 'package:shared/erros/codigo_erro.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../shared/http/respostas.dart';
import '../../shared/middleware/identidade_middleware.dart';
import 'treino_service.dart';

/// Forma da requisicao e montagem do JSON. Sem regra de negocio.
class TreinoController {
  TreinoController(this._service);

  final TreinoService _service;

  static const int _limitPadrao = 100;
  static const int _limitMaximo = 100;

  Router get router => Router()..get('/treinos/livres', _listarLivres);

  Future<Response> _listarLivres(Request req) async {
    final identidade = identidadeDaRequisicao(req);
    if (identidade == null) {
      return envelopeErro(
        CodigoErro.tokenInvalido,
        mensagem: 'Autenticacao necessaria ou token invalido.',
      );
    }

    final p = req.url.queryParameters;
    final limit = p['limit'] == null ? _limitPadrao : int.tryParse(p['limit']!);
    if (limit == null || limit < 1 || limit > _limitMaximo) {
      return campoInvalido('limit', 'Deve ser um inteiro de 1 a $_limitMaximo.');
    }
    final offset = p['offset'] == null ? 0 : int.tryParse(p['offset']!);
    if (offset == null || offset < 0) {
      return campoInvalido('offset', 'Deve ser um inteiro maior ou igual a 0.');
    }

    final pagina = await _service.listarLivres(
      identidade,
      limit: limit,
      offset: offset,
    );
    return jsonResposta(
      200,
      paginaToJson(
        itens: [
          for (final t in pagina.itens)
            {'id_treino': t.idTreino, 'nome': t.nome, 'tipo': t.tipo},
        ],
        limit: limit,
        offset: offset,
        total: pagina.total,
      ),
    );
  }
}
