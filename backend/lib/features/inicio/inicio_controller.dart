import 'package:shared/erros/codigo_erro.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../shared/http/respostas.dart';
import '../../shared/middleware/identidade_middleware.dart';
import 'inicio_service.dart';

/// Forma da requisicao e montagem do JSON. Sem regra de negocio.
class InicioController {
  InicioController(this._service);

  final InicioService _service;

  Router get router => Router()..get('/inicio', _painel);

  Future<Response> _painel(Request req) async {
    final identidade = identidadeDaRequisicao(req);
    if (identidade == null) {
      return envelopeErro(
        CodigoErro.tokenInvalido,
        mensagem: 'Autenticacao necessaria ou token invalido.',
      );
    }

    final painel = await _service.painel(identidade);
    return jsonResposta(200, {
      'data': painel.data,
      'aulas_hoje': painel.aulas.length,
      'ocupacao_percentual': painel.ocupacaoPercentual,
      'pessoas_inativas': painel.pessoasInativas,
      'aulas': [
        for (final a in painel.aulas)
          {
            'id_aula': a.idAula,
            'hora_inicio': a.horaInicio,
            'hora_fim': a.horaFim,
            'categoria': a.categoria,
            'tipo': a.tipo,
            'professor': a.professor,
            'vagas_ocupadas': a.vagasOcupadas,
            'vagas_maximas': a.vagasMaximas,
          },
      ],
    });
  }
}
