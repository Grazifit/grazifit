import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';

class Professor extends Table {
  IntColumn get idProfessor => integer().autoIncrement()();
  IntColumn get idAdminCriador => integer().nullable()();
  IntColumn get idEndereco => integer().nullable()();
  TextColumn get cpf => text().withLength(min: 11, max: 11).unique()();
  TextColumn get senhaHash => text().withLength(max: 255)();
  TextColumn get nome => text().withLength(min: 1, max: 150)();
  TextColumn get telefone => text().withLength(max: 20)();
  TextColumn get email => text().withLength(max: 255).unique()();
  BoolColumn get status =>
    boolean().withDefault(const Constant(true))();
  PgDateColumn get dataCadastro => customType(PgTypes.date)
    .withDefault(const CustomExpression<PgDate>('CURRENT_DATE'))();
  TimestampColumn get dataUltimoAcesso =>
    customType(PgTypes.timestampWithTimezone).nullable()();

  @override
  String get tableName => 'professor';
}
