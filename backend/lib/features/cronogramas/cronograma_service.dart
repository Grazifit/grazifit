import 'package:shared/erros/codigo_erro.dart';

import '../../shared/autorizacao/identidade.dart';
import 'cronograma_model.dart';
import 'cronograma_repository.dart';

class CronogramaService {
  CronogramaService(this.repository);
  final CronogramaRepository repository;
  static const campos = {
    'id_professor',
    'categoria',
    'hora_inicio',
    'hora_fim',
    'data_inicio',
    'data_fim',
    'vagas_maxima',
    'dias_semana',
    'status',
  };
  Never _invalido(String campo) =>
      throw CronogramaException(CodigoErro.campoInvalido, campo: campo);
  void _forma(Map<String, dynamic> dados, {required bool parcial}) {
    for (final key in dados.keys) {
      if (!campos.contains(key)) _invalido(key);
    }
    if (parcial && dados.isEmpty) _invalido('corpo');
    if (!parcial) {
      for (final key in campos.difference({'data_fim', 'status'})) {
        if (!dados.containsKey(key)) {
          throw CronogramaException(CodigoErro.campoObrigatorio, campo: key);
        }
      }
    }
  }

  void _validar(Map<String, dynamic> d) {
    for (final campo in ['id_professor', 'vagas_maxima']) {
      final n = d[campo];
      if (n is! int || n <= 0 || n > 2147483647) _invalido(campo);
    }
    if (!{
      'musculacao',
      'funcional',
      'pilates',
      'crossfit',
      'danca',
      'spinning',
    }.contains(d['categoria'])) {
      _invalido('categoria');
    }
    for (final campo in ['hora_inicio', 'hora_fim']) {
      final valor = d[campo];
      if (valor is! String ||
          !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(valor)) {
        _invalido(campo);
      }
    }
    if ((d['hora_fim'] as String).compareTo(d['hora_inicio'] as String) <= 0) {
      _invalido('hora_fim');
    }
    for (final campo in ['data_inicio', 'data_fim']) {
      final valor = d[campo];
      if (campo == 'data_fim' && valor == null) continue;
      if (valor is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(valor)) {
        _invalido(campo);
      }
      final data = DateTime.tryParse(valor);
      if (data == null ||
          data.year < 1 ||
          data.toIso8601String().substring(0, 10) != valor) {
        _invalido(campo);
      }
    }
    if (d['data_fim'] != null &&
        (d['data_fim'] as String).compareTo(d['data_inicio'] as String) < 0) {
      _invalido('data_fim');
    }
    final dias = d['dias_semana'];
    if (dias is! List ||
        dias.isEmpty ||
        dias.length > 7 ||
        dias.any((v) => v is! int || v < 0 || v > 6) ||
        dias.toSet().length != dias.length) {
      _invalido('dias_semana');
    }
    if (d['status'] is! bool) _invalido('status');
  }

  Future<Cronograma> _exigir(int id, {bool bloquear = false}) async {
    if (id <= 0 || id > 2147483647) _invalido('id');
    final item = await repository.buscar(id, bloquear: bloquear);
    if (item == null) {
      throw const CronogramaException(CodigoErro.registroNaoEncontrado);
    }
    return item;
  }

  Future<Cronograma> criar(Identidade identidade, Map<String, dynamic> dados) {
    exigirAdmin(identidade);
    _forma(dados, parcial: false);
    final completo = {'status': true, 'data_fim': null, ...dados};
    _validar(completo);
    return repository.transacao(() async {
      await repository.exigirProfessorAtivo(completo['id_professor'] as int);
      return repository.criar(identidade.id, completo);
    });
  }

  Future<Cronograma> buscar(Identidade identidade, int id) {
    exigirAdmin(identidade);
    return repository.leituraConsistente(() => _exigir(id));
  }

  Future<Map<String, dynamic>> listar(
    Identidade identidade, {
    int limit = 20,
    int offset = 0,
    bool? status,
  }) {
    exigirAdmin(identidade);
    if (limit < 1 || limit > 100) _invalido('limit');
    if (offset < 0) _invalido('offset');
    return repository.transacao(() => repository.listar(limit, offset, status));
  }

  Future<Cronograma> atualizar(
    Identidade identidade,
    int id,
    Map<String, dynamic> dados,
  ) {
    exigirAdmin(identidade);
    _forma(dados, parcial: true);
    return repository.transacao(() async {
      final atual = await _exigir(id, bloquear: true);
      final completo = {...atual.dados, ...dados};
      _validar(completo);
      final somenteStatus = dados.keys.every((k) => k == 'status');
      if (!somenteStatus && await repository.temAulas(id)) {
        throw const CronogramaException(CodigoErro.registroEmUso);
      }
      if (!somenteStatus || completo['status'] == true) {
        await repository.exigirProfessorAtivo(completo['id_professor'] as int);
      }
      return repository.atualizar(id, completo, somenteStatus: somenteStatus);
    });
  }

  Future<void> excluir(Identidade identidade, int id) {
    exigirAdmin(identidade);
    return repository.transacao(() async {
      await _exigir(id, bloquear: true);
      if (await repository.temAulas(id)) {
        throw const CronogramaException(CodigoErro.registroEmUso);
      }
      await repository.excluir(id);
    });
  }
}
