import 'package:drift/drift.dart';
import 'package:shared/erros/codigo_erro.dart';

import '../../database/database.dart';
import 'cronograma_model.dart';

class CronogramaRepository {
  CronogramaRepository(this.db);
  final GraziDatabase db;
  Future<T> transacao<T>(Future<T> Function() action) => db.transaction(action);
  Future<T> leituraConsistente<T>(Future<T> Function() action) =>
      db.transaction(() async {
        await db.customStatement(
          'SET TRANSACTION ISOLATION LEVEL REPEATABLE READ',
        );
        return action();
      });
  static const colunas =
      'id_cronograma, id_admin_criador, id_professor, categoria, '
      "to_char(hora_inicio, 'HH24:MI') AS hora_inicio, to_char(hora_fim, 'HH24:MI') AS hora_fim, "
      "to_char(data_inicio, 'YYYY-MM-DD') AS data_inicio, to_char(data_fim, 'YYYY-MM-DD') AS data_fim, vagas_maxima, status";

  Future<Cronograma?> buscar(int id, {bool bloquear = false}) async {
    final row = await db
        .customSelect(
          'SELECT $colunas FROM cronograma WHERE id_cronograma = \$1${bloquear ? ' FOR UPDATE' : ''}',
          variables: [Variable.withInt(id)],
        )
        .getSingleOrNull();
    if (row == null) return null;
    final dias = await db
        .customSelect(
          'SELECT dia_semana FROM cronograma_dia WHERE id_cronograma = \$1 ORDER BY dia_semana',
          variables: [Variable.withInt(id)],
        )
        .get();
    return Cronograma({
      ...row.data,
      'dias_semana': dias.map((d) => d.read<int>('dia_semana')).toList(),
    });
  }

  Future<void> exigirProfessorAtivo(int id) async {
    final row = await db
        .customSelect(
          'SELECT status FROM professor WHERE id_professor = \$1 FOR SHARE',
          variables: [Variable.withInt(id)],
        )
        .getSingleOrNull();
    if (row == null || !row.read<bool>('status')) {
      throw const CronogramaException(
        CodigoErro.campoInvalido,
        campo: 'id_professor',
      );
    }
  }

  Future<bool> temAulas(int id) async =>
      (await db
              .customSelect(
                'SELECT EXISTS(SELECT 1 FROM aula WHERE id_cronograma = \$1) AS existe',
                variables: [Variable.withInt(id)],
              )
              .getSingle())
          .read<bool>('existe');

  Future<Cronograma> criar(int admin, Map<String, dynamic> dados) async {
    final rows = await db.customWriteReturning(
      'INSERT INTO cronograma (id_admin_criador, id_professor, categoria, hora_inicio, hora_fim, data_inicio, data_fim, vagas_maxima, status) '
      'VALUES (\$1, \$2, \$3, \$4::time, \$5::time, \$6::date, \$7::date, \$8, \$9) RETURNING id_cronograma',
      variables: [Variable.withInt(admin), ..._variables(dados)],
      updates: {},
    );
    final id = rows.single.read<int>('id_cronograma');
    await _dias(id, (dados['dias_semana'] as List).cast<int>());
    return (await buscar(id))!;
  }

  List<Variable> _variables(Map<String, dynamic> d) => [
    Variable.withInt(d['id_professor'] as int),
    Variable.withString(d['categoria'] as String),
    Variable.withString(d['hora_inicio'] as String),
    Variable.withString(d['hora_fim'] as String),
    Variable.withString(d['data_inicio'] as String),
    Variable<String>(d['data_fim'] as String?),
    Variable.withInt(d['vagas_maxima'] as int),
    Variable.withBool(d['status'] as bool),
  ];

  Future<Cronograma> atualizar(
    int id,
    Map<String, dynamic> dados, {
    required bool somenteStatus,
  }) async {
    if (somenteStatus) {
      await db.customStatement(
        'UPDATE cronograma SET status = \$1 WHERE id_cronograma = \$2',
        [dados['status'], id],
      );
    } else {
      await db.customWriteReturning(
        'UPDATE cronograma SET id_professor = \$1, categoria = \$2, hora_inicio = \$3::time, hora_fim = \$4::time, data_inicio = \$5::date, data_fim = \$6::date, vagas_maxima = \$7, status = \$8 WHERE id_cronograma = \$9 RETURNING id_cronograma',
        variables: [..._variables(dados), Variable.withInt(id)],
        updates: {},
      );
      await _dias(id, (dados['dias_semana'] as List).cast<int>());
    }
    return (await buscar(id))!;
  }

  Future<void> _dias(int id, List<int> dias) async {
    await db.customStatement(
      'DELETE FROM cronograma_dia WHERE id_cronograma = \$1',
      [id],
    );
    for (final dia in dias) {
      await db.customStatement(
        'INSERT INTO cronograma_dia (id_cronograma, dia_semana) VALUES (\$1, \$2)',
        [id, dia],
      );
    }
  }

  Future<void> excluir(int id) => db.customStatement(
    'DELETE FROM cronograma WHERE id_cronograma = \$1',
    [id],
  );

  Future<Map<String, dynamic>> listar(
    int limit,
    int offset,
    bool? status,
  ) async {
    await db.customStatement('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ');
    final filtro = status == null
        ? ''
        : ' WHERE status = ${status ? 'TRUE' : 'FALSE'}';
    final total =
        (await db
                .customSelect('SELECT count(*) AS total FROM cronograma$filtro')
                .getSingle())
            .read<int>('total');
    final pagina = await db
        .customSelect(
          'SELECT $colunas FROM cronograma$filtro ORDER BY data_inicio DESC, id_cronograma DESC LIMIT \$1 OFFSET \$2',
          variables: [Variable.withInt(limit), Variable.withInt(offset)],
        )
        .get();
    final diasPorId = <int, List<int>>{};
    if (pagina.isNotEmpty) {
      final ids = pagina.map((row) => row.read<int>('id_cronograma')).toList();
      final parametros = List.generate(
        ids.length,
        (i) => '\$${i + 1}',
      ).join(', ');
      final dias = await db
          .customSelect(
            'SELECT id_cronograma, dia_semana FROM cronograma_dia '
            'WHERE id_cronograma IN ($parametros) ORDER BY id_cronograma, dia_semana',
            variables: ids.map(Variable.withInt).toList(),
          )
          .get();
      for (final dia in dias) {
        (diasPorId[dia.read<int>('id_cronograma')] ??= <int>[]).add(
          dia.read<int>('dia_semana'),
        );
      }
    }
    final itens = pagina
        .map(
          (row) => <String, dynamic>{
            ...row.data,
            'dias_semana': diasPorId[row.read<int>('id_cronograma')] ?? <int>[],
          },
        )
        .toList();
    return {'itens': itens, 'total': total, 'limit': limit, 'offset': offset};
  }
}
