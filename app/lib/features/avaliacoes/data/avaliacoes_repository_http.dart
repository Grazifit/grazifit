import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'avaliacoes_repository.dart';
import 'evolucao_aluno.dart';

/// Implementação real de [AvaliacoesRepository], sobre os endpoints
/// `GET /aluno/<id>/avaliacoes`, `GET /aluno/<id>/avaliacoes/atual` e
/// `POST /aluno/<id>/avaliacoes/hoje`. O IMC é calculado pelo banco; as telas
/// de aluno ainda mostram o IMC calculado a partir de peso e altura.
class AvaliacoesRepositoryHttp implements AvaliacoesRepository {
  const AvaliacoesRepositoryHttp(this._api, this._idAluno);

  final ApiClient _api;

  /// Id do aluno logado (da sessão). Nulo = sem login.
  final int? Function() _idAluno;

  int get _id {
    final id = _idAluno();
    if (id == null) throw const ApiException(statusCode: 401);
    return id;
  }

  @override
  Future<EvolucaoAluno> buscarEvolucao() async {
    final json = await _api.get(
      '/aluno/$_id/avaliacoes',
      query: const {'limit': '100', 'offset': '0'},
    );
    final itens = ((json['itens'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>();

    final medidas = itens
        .map(
          (a) => MedidaPeso(
            data: DateTime.parse(a['data_avaliacao'] as String),
            peso: double.parse(a['peso'].toString()),
          ),
        )
        .toList()
      ..sort((a, b) => a.data.compareTo(b.data));

    // Altura da avaliação mais recente. Sem nenhuma avaliação ainda, 0: o
    // aluno só consegue registrar depois que um professor avaliar (ver
    // registrarMedida).
    final maisRecente = itens.isEmpty
        ? null
        : (itens.toList()
              ..sort(
                (a, b) => (b['data_avaliacao'] as String).compareTo(
                  a['data_avaliacao'] as String,
                ),
              ))
            .first;
    final alturaM = maisRecente == null
        ? 0.0
        : double.parse(maisRecente['altura'].toString());

    return EvolucaoAluno(alturaM: alturaM, medidas: medidas);
  }

  @override
  Future<void> registrarMedida(double peso) async {
    // O backend exige peso e altura. A tela só pede o peso, então a altura
    // vem da avaliação atual; sem ela não há como registrar.
    final atual = await _api.get('/aluno/$_id/avaliacoes/atual');
    final altura = atual['altura'];
    if (altura == null) {
      throw const ApiException(codigo: 'ALTURA_NAO_INFORMADA');
    }
    await _api.post('/aluno/$_id/avaliacoes/hoje', {
      'peso': peso,
      'altura': double.parse(altura.toString()),
    });
  }
}
