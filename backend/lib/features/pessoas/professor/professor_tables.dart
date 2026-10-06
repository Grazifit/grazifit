import 'package:drift/drift.dart';

class Professor extends Table {
  IntColumn get idProfessor => integer().autoIncrement()();
  IntColumn get idAdminCriador => integer().nullable()();
  TextColumn get cpf => text().withLength(min: 11, max: 11).unique()();
  TextColumn get senhaHash => text().withLength(max: 255)();
  TextColumn get nome => text().withLength(min: 1, max: 150)();
  TextColumn get telefone => text().withLength(max: 20)(); // sem nullable
  TextColumn get email => text().withLength(max: 255).unique()();
  BoolColumn get status => boolean().withDefault(const Constant(true))();

  @override
  String get tableName => 'professor';
}