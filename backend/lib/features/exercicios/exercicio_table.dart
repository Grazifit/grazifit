import 'package:drift/drift.dart';

class Exercicio extends Table {
  IntColumn get idExercicio => integer().autoIncrement()();
  IntColumn get idAdminCriador => integer()();
  TextColumn get nome => text().withLength(min: 1, max: 120).unique()();
  TextColumn get instrucoes => text()();
  TextColumn get descricao => text().nullable()();
  TextColumn get dificuldade =>
      text().withLength(max: 15).withDefault(const Constant('iniciante'))();

  @override
  String get tableName => 'exercicio';
}
