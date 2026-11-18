import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/state/auth_controller.dart';

final avaliacaoRepositoryProvider = Provider(
  (ref) => AvaliacaoRepository(ref.watch(apiClientProvider)),
);
final historicoAvaliacoesProvider = FutureProvider<List<MedidaAvaliacao>>((
  ref,
) {
  final sessao = ref.watch(authControllerProvider).sessao;
  if (sessao == null || sessao.papel != 'aluno') {
    throw const ApiException(statusCode: 401);
  }
  return ref.watch(avaliacaoRepositoryProvider).historico(sessao.id);
});

class MedidaAvaliacao {
  MedidaAvaliacao.fromJson(Map<String, dynamic> json)
    : data = json['data_avaliacao'] as String,
      peso = (json['peso'] as num).toDouble(),
      altura = (json['altura'] as num).toDouble(),
      imc = (json['imc'] as num).toDouble(),
      observacao = json['observacao'] as String?;
  final String data;
  final double peso, altura, imc;
  final String? observacao;
  String get rotulo =>
      '${data.substring(8, 10)}/${data.substring(5, 7)}/${data.substring(2, 4)}';
}

class AvaliacaoRepository {
  AvaliacaoRepository(this.api);
  final ApiClient api;
  Future<List<MedidaAvaliacao>> historico(int id) async {
    final items = <MedidaAvaliacao>[];
    var offset = 0;
    while (true) {
      final page = await api.getJson(
        '/aluno/$id/avaliacoes?limit=100&offset=$offset',
      );
      final batch = (page['itens'] as List).cast<Map<String, dynamic>>();
      items.addAll(batch.map(MedidaAvaliacao.fromJson));
      offset += batch.length;
      if (offset >= (page['total'] as int) || batch.isEmpty) break;
    }
    items.sort((a, b) => a.data.compareTo(b.data));
    return items;
  }

  Future<MedidaAvaliacao?> atual(int id) async {
    final json = await api.getJson('/aluno/$id/avaliacoes/atual');
    return json.isEmpty ? null : MedidaAvaliacao.fromJson(json);
  }

  Future<MedidaAvaliacao> salvar(
    int id, {
    required double peso,
    required double altura,
    required String observacao,
  }) async => MedidaAvaliacao.fromJson(
    await api.postJson('/aluno/$id/avaliacoes/hoje', {
      'peso': peso,
      'altura': altura,
      'observacao': observacao,
    }),
  );
}

String mensagemAvaliacao(Object erro) {
  if (erro is ApiException) {
    if (erro.statusCode == 401) {
      return 'Entre novamente como aluno para acessar suas avaliações.';
    }
    if (erro.statusCode == 403) {
      return 'Você não tem permissão para esta avaliação.';
    }
    if (erro.statusCode == 400) {
      return 'Confira peso, altura e observação. Use até duas casas decimais.';
    }
  }
  return 'Não foi possível acessar as avaliações. Tente novamente.';
}
