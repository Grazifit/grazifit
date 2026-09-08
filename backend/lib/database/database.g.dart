// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
abstract class _$GraziDatabase extends GeneratedDatabase {
  _$GraziDatabase(QueryExecutor e) : super(e);
  $GraziDatabaseManager get managers => $GraziDatabaseManager(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [];
}

class $GraziDatabaseManager {
  final _$GraziDatabase _db;
  $GraziDatabaseManager(this._db);
}
