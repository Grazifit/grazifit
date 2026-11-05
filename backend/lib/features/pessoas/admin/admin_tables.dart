import 'package:drift/drift.dart';

class Admin extends Table{
  IntColumn get idAdmin => integer().autoIncrement()();
  TextColumn get cpf => text().withLength(min: 11, max: 11).unique()();
  TextColumn get senhaHash => text()();
  TextColumn get nome => text().withLength(min: 1, max: 150)();
  TextColumn get email => text().unique()();
  TextColumn get telefone => text().withLength(max: 20).nullable()();

  @override
  String get tableName => 'admin';
}