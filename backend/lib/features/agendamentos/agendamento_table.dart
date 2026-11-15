import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';

/// Espelho da tabela `agendamento`; o schema SQL e quem define o banco.
class Agendamento extends Table {
  IntColumn get idAgendamento => integer().autoIncrement()();
  IntColumn get idAluno => integer()();
  IntColumn get idAula => integer()();
  PgDateColumn get dataAgendamento => customType(PgTypes.date)();
  TextColumn get status =>
      text().withLength(max: 15).withDefault(const Constant('agendado'))();
  TimestampColumn get dataPresenca =>
      customType(PgTypes.timestampWithTimezone).nullable()();
  TimestampColumn get dataCancelamento =>
      customType(PgTypes.timestampWithTimezone).nullable()();

  @override
  String get tableName => 'agendamento';
}
