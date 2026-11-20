import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart' as pg;

/// Espelho da tabela `aula`; o schema SQL e quem define o banco.
class Aula extends Table {
  IntColumn get idAula => integer().autoIncrement()();
  IntColumn get idAdminCriador => integer().nullable()();
  IntColumn get idProfessor => integer()();

  /// Nulo = aula avulsa.
  IntColumn get idCronograma => integer().nullable()();

  PgDateColumn get data => customType(PgTypes.date)();
  Column<pg.Time> get horaInicio => customType(tipoHoraPg)();
  Column<pg.Time> get horaFim => customType(tipoHoraPg)();
  TextColumn get tipo => text().withLength(max: 20)();
  TextColumn get categoria => text().withLength(max: 40)();
  IntColumn get vagasMaxima => integer()();
  BoolColumn get status => boolean().withDefault(const Constant(true))();

  IntColumn get idProfessorCancelou => integer().nullable()();
  IntColumn get idAdminCancelou => integer().nullable()();
  TimestampColumn get dataCancelamento =>
      customType(PgTypes.timestampWithTimezone).nullable()();

  @override
  String get tableName => 'aula';
}

/// Tipo `TIME`, ausente em `PgTypes` do drift_postgres.
const tipoHoraPg = TipoHoraPg();

class TipoHoraPg implements CustomSqlType<pg.Time> {
  const TipoHoraPg();

  @override
  pg.Time read(Object fromSql) => fromSql as pg.Time;

  @override
  Object mapToSqlParameter(pg.Time dartValue) =>
      pg.TypedValue(pg.Type.time, dartValue);

  @override
  String mapToSqlLiteral(pg.Time dartValue) {
    final hora = dartValue.hour.toString().padLeft(2, '0');
    final minuto = dartValue.minute.toString().padLeft(2, '0');
    final segundo = dartValue.second.toString().padLeft(2, '0');
    return "'$hora:$minuto:$segundo'::time";
  }

  @override
  String sqlTypeName(GenerationContext context) => 'time';
}
