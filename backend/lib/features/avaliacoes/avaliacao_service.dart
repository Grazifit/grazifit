import 'package:shared/dtos/avaliacao_serializer.dart';
import 'package:shared/erros/codigo_erro.dart';

import '../../shared/autorizacao/identidade.dart';
import 'avaliacao_exception.dart';
import 'avaliacao_repository.dart';

class AvaliacaoService {
  AvaliacaoService(this.repository);
  final AvaliacaoRepository repository;

  void _autorizar(Identidade identidade, int id) {
    if (identidade.papel != Papel.admin &&
        !(identidade.papel == Papel.aluno && identidade.id == id)) {
      throw const AcessoNegado();
    }
    if (id <= 0) {
      throw const AvaliacaoException(CodigoErro.campoInvalido, campo: 'id');
    }
  }

  Future<AvaliacaoDto> salvarHoje(
    Identidade identidade,
    int id, {
    required double peso,
    required double altura,
    String? observacao,
  }) {
    _autorizar(identidade, id);
    for (final (campo, valor, teto) in [
      ('peso', peso, 500),
      ('altura', altura, 3),
    ]) {
      if (!valor.isFinite ||
          valor <= 0 ||
          valor >= teto ||
          (valor * 100 - (valor * 100).round()).abs() > 0.0000001) {
        throw AvaliacaoException(CodigoErro.campoInvalido, campo: campo);
      }
    }
    final texto = observacao?.trim();
    if (observacao != null && observacao.length > 2000) {
      throw const AvaliacaoException(
        CodigoErro.campoInvalido,
        campo: 'observacao',
      );
    }
    return repository.salvarHoje(
      id,
      peso: peso,
      altura: altura,
      observacao: texto == null || texto.isEmpty ? null : texto,
    );
  }

  Future<AvaliacaoDto?> atual(Identidade identidade, int id) {
    _autorizar(identidade, id);
    return repository.atual(id);
  }

  Future<({List<AvaliacaoDto> itens, int total})> listar(
    Identidade identidade,
    int id, {
    int limit = 20,
    int offset = 0,
  }) {
    _autorizar(identidade, id);
    if (limit < 1 || limit > 100) {
      throw const AvaliacaoException(CodigoErro.campoInvalido, campo: 'limit');
    }
    if (offset < 0) {
      throw const AvaliacaoException(CodigoErro.campoInvalido, campo: 'offset');
    }
    return repository.listar(id, limit: limit, offset: offset);
  }
}
