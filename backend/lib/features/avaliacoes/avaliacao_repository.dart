import 'package:drift/drift.dart';
import 'package:shared/dtos/avaliacao_serializer.dart';
import 'package:shared/erros/codigo_erro.dart';

import '../../database/database.dart';
import 'avaliacao_exception.dart';

/// SQL parametrizado via Drift, preservando NUMERIC e a coluna IMC gerada.
class AvaliacaoRepository {
  AvaliacaoRepository(this.db);
  final GraziDatabase db;
  static const _colunas =
      'id_avaliacao, id_aluno, '
      "to_char(data_avaliacao, 'YYYY-MM-DD') AS data_avaliacao, "
      'peso::text AS peso, altura::text AS altura, imc::text AS imc, observacao';

  Future<void> _exigirAluno(int id, {bool escrita = false}) async {
    final row = await db
        .customSelect(
          'SELECT status FROM aluno WHERE id_aluno = \$1 FOR SHARE',
          variables: [Variable.withInt(id)],
        )
        .getSingleOrNull();
    if (row == null) {
      throw const AvaliacaoException(CodigoErro.registroNaoEncontrado);
    }
    if (escrita && !row.read<bool>('status')) {
      throw const AvaliacaoException(CodigoErro.acessoNegado);
    }
  }

  Future<AvaliacaoDto> salvarHoje(
    int id, {
    required double peso,
    required double altura,
    String? observacao,
  }) => db.transaction(() async {
    await _exigirAluno(id, escrita: true);
    final rows = await db.customWriteReturning(
      'INSERT INTO avaliacao (id_aluno, data_avaliacao, peso, altura, observacao) '
      "VALUES (\$1, (statement_timestamp() AT TIME ZONE 'America/Sao_Paulo')::date, "
      '\$2::numeric, \$3::numeric, \$4) '
      'ON CONFLICT (id_aluno, data_avaliacao) DO UPDATE SET '
      'peso = EXCLUDED.peso, altura = EXCLUDED.altura, observacao = EXCLUDED.observacao '
      'RETURNING $_colunas',
      variables: [
        Variable.withInt(id),
        Variable.withString(peso.toStringAsFixed(2)),
        Variable.withString(altura.toStringAsFixed(2)),
        Variable<String>(observacao),
      ],
      updates: {},
    );
    return _dto(rows.single);
  });

  Future<AvaliacaoDto?> atual(int id) => db.transaction(() async {
    await _exigirAluno(id);
    final row = await db
        .customSelect(
          'SELECT $_colunas FROM avaliacao WHERE id_aluno = \$1 '
          'ORDER BY data_avaliacao DESC, id_avaliacao DESC LIMIT 1',
          variables: [Variable.withInt(id)],
        )
        .getSingleOrNull();
    return row == null ? null : _dto(row);
  });

  Future<({List<AvaliacaoDto> itens, int total})> listar(
    int id, {
    required int limit,
    required int offset,
  }) => db.transaction(() async {
    await db.customStatement('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ');
    await _exigirAluno(id);
    final total = await db
        .customSelect(
          'SELECT count(*) AS total FROM avaliacao WHERE id_aluno = \$1',
          variables: [Variable.withInt(id)],
        )
        .getSingle();
    final rows = await db
        .customSelect(
          'SELECT $_colunas FROM avaliacao WHERE id_aluno = \$1 '
          'ORDER BY data_avaliacao DESC, id_avaliacao DESC LIMIT \$2 OFFSET \$3',
          variables: [
            Variable.withInt(id),
            Variable.withInt(limit),
            Variable.withInt(offset),
          ],
        )
        .get();
    return (itens: rows.map(_dto).toList(), total: total.read<int>('total'));
  });

  AvaliacaoDto _dto(QueryRow row) => AvaliacaoDto(
    idAvaliacao: row.read<int>('id_avaliacao'),
    idAluno: row.read<int>('id_aluno'),
    dataAvaliacao: row.read<String>('data_avaliacao'),
    peso: double.parse(row.read<String>('peso')),
    altura: double.parse(row.read<String>('altura')),
    imc: double.parse(row.read<String>('imc')),
    observacao: row.readNullable<String>('observacao'),
  );
}
