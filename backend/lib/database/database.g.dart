// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AdminTable extends Admin with TableInfo<$AdminTable, AdminData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdminTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idAdminMeta = const VerificationMeta(
    'idAdmin',
  );
  @override
  late final GeneratedColumn<int> idAdmin = GeneratedColumn<int>(
    'id_admin',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cpfMeta = const VerificationMeta('cpf');
  @override
  late final GeneratedColumn<String> cpf = GeneratedColumn<String>(
    'cpf',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 11,
      maxTextLength: 11,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _senhaHashMeta = const VerificationMeta(
    'senhaHash',
  );
  @override
  late final GeneratedColumn<String> senhaHash = GeneratedColumn<String>(
    'senha_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 150,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _telefoneMeta = const VerificationMeta(
    'telefone',
  );
  @override
  late final GeneratedColumn<String> telefone = GeneratedColumn<String>(
    'telefone',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    idAdmin,
    cpf,
    senhaHash,
    nome,
    email,
    telefone,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'admin';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdminData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_admin')) {
      context.handle(
        _idAdminMeta,
        idAdmin.isAcceptableOrUnknown(data['id_admin']!, _idAdminMeta),
      );
    }
    if (data.containsKey('cpf')) {
      context.handle(
        _cpfMeta,
        cpf.isAcceptableOrUnknown(data['cpf']!, _cpfMeta),
      );
    } else if (isInserting) {
      context.missing(_cpfMeta);
    }
    if (data.containsKey('senha_hash')) {
      context.handle(
        _senhaHashMeta,
        senhaHash.isAcceptableOrUnknown(data['senha_hash']!, _senhaHashMeta),
      );
    } else if (isInserting) {
      context.missing(_senhaHashMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('telefone')) {
      context.handle(
        _telefoneMeta,
        telefone.isAcceptableOrUnknown(data['telefone']!, _telefoneMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {idAdmin};
  @override
  AdminData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdminData(
      idAdmin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id_admin'],
      )!,
      cpf: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cpf'],
      )!,
      senhaHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}senha_hash'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      telefone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telefone'],
      ),
    );
  }

  @override
  $AdminTable createAlias(String alias) {
    return $AdminTable(attachedDatabase, alias);
  }
}

class AdminData extends DataClass implements Insertable<AdminData> {
  final int idAdmin;
  final String cpf;
  final String senhaHash;
  final String nome;
  final String email;
  final String? telefone;
  const AdminData({
    required this.idAdmin,
    required this.cpf,
    required this.senhaHash,
    required this.nome,
    required this.email,
    this.telefone,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_admin'] = Variable<int>(idAdmin);
    map['cpf'] = Variable<String>(cpf);
    map['senha_hash'] = Variable<String>(senhaHash);
    map['nome'] = Variable<String>(nome);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || telefone != null) {
      map['telefone'] = Variable<String>(telefone);
    }
    return map;
  }

  AdminCompanion toCompanion(bool nullToAbsent) {
    return AdminCompanion(
      idAdmin: Value(idAdmin),
      cpf: Value(cpf),
      senhaHash: Value(senhaHash),
      nome: Value(nome),
      email: Value(email),
      telefone: telefone == null && nullToAbsent
          ? const Value.absent()
          : Value(telefone),
    );
  }

  factory AdminData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdminData(
      idAdmin: serializer.fromJson<int>(json['idAdmin']),
      cpf: serializer.fromJson<String>(json['cpf']),
      senhaHash: serializer.fromJson<String>(json['senhaHash']),
      nome: serializer.fromJson<String>(json['nome']),
      email: serializer.fromJson<String>(json['email']),
      telefone: serializer.fromJson<String?>(json['telefone']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idAdmin': serializer.toJson<int>(idAdmin),
      'cpf': serializer.toJson<String>(cpf),
      'senhaHash': serializer.toJson<String>(senhaHash),
      'nome': serializer.toJson<String>(nome),
      'email': serializer.toJson<String>(email),
      'telefone': serializer.toJson<String?>(telefone),
    };
  }

  AdminData copyWith({
    int? idAdmin,
    String? cpf,
    String? senhaHash,
    String? nome,
    String? email,
    Value<String?> telefone = const Value.absent(),
  }) => AdminData(
    idAdmin: idAdmin ?? this.idAdmin,
    cpf: cpf ?? this.cpf,
    senhaHash: senhaHash ?? this.senhaHash,
    nome: nome ?? this.nome,
    email: email ?? this.email,
    telefone: telefone.present ? telefone.value : this.telefone,
  );
  AdminData copyWithCompanion(AdminCompanion data) {
    return AdminData(
      idAdmin: data.idAdmin.present ? data.idAdmin.value : this.idAdmin,
      cpf: data.cpf.present ? data.cpf.value : this.cpf,
      senhaHash: data.senhaHash.present ? data.senhaHash.value : this.senhaHash,
      nome: data.nome.present ? data.nome.value : this.nome,
      email: data.email.present ? data.email.value : this.email,
      telefone: data.telefone.present ? data.telefone.value : this.telefone,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdminData(')
          ..write('idAdmin: $idAdmin, ')
          ..write('cpf: $cpf, ')
          ..write('senhaHash: $senhaHash, ')
          ..write('nome: $nome, ')
          ..write('email: $email, ')
          ..write('telefone: $telefone')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(idAdmin, cpf, senhaHash, nome, email, telefone);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdminData &&
          other.idAdmin == this.idAdmin &&
          other.cpf == this.cpf &&
          other.senhaHash == this.senhaHash &&
          other.nome == this.nome &&
          other.email == this.email &&
          other.telefone == this.telefone);
}

class AdminCompanion extends UpdateCompanion<AdminData> {
  final Value<int> idAdmin;
  final Value<String> cpf;
  final Value<String> senhaHash;
  final Value<String> nome;
  final Value<String> email;
  final Value<String?> telefone;
  const AdminCompanion({
    this.idAdmin = const Value.absent(),
    this.cpf = const Value.absent(),
    this.senhaHash = const Value.absent(),
    this.nome = const Value.absent(),
    this.email = const Value.absent(),
    this.telefone = const Value.absent(),
  });
  AdminCompanion.insert({
    this.idAdmin = const Value.absent(),
    required String cpf,
    required String senhaHash,
    required String nome,
    required String email,
    this.telefone = const Value.absent(),
  }) : cpf = Value(cpf),
       senhaHash = Value(senhaHash),
       nome = Value(nome),
       email = Value(email);
  static Insertable<AdminData> custom({
    Expression<int>? idAdmin,
    Expression<String>? cpf,
    Expression<String>? senhaHash,
    Expression<String>? nome,
    Expression<String>? email,
    Expression<String>? telefone,
  }) {
    return RawValuesInsertable({
      if (idAdmin != null) 'id_admin': idAdmin,
      if (cpf != null) 'cpf': cpf,
      if (senhaHash != null) 'senha_hash': senhaHash,
      if (nome != null) 'nome': nome,
      if (email != null) 'email': email,
      if (telefone != null) 'telefone': telefone,
    });
  }

  AdminCompanion copyWith({
    Value<int>? idAdmin,
    Value<String>? cpf,
    Value<String>? senhaHash,
    Value<String>? nome,
    Value<String>? email,
    Value<String?>? telefone,
  }) {
    return AdminCompanion(
      idAdmin: idAdmin ?? this.idAdmin,
      cpf: cpf ?? this.cpf,
      senhaHash: senhaHash ?? this.senhaHash,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idAdmin.present) {
      map['id_admin'] = Variable<int>(idAdmin.value);
    }
    if (cpf.present) {
      map['cpf'] = Variable<String>(cpf.value);
    }
    if (senhaHash.present) {
      map['senha_hash'] = Variable<String>(senhaHash.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (telefone.present) {
      map['telefone'] = Variable<String>(telefone.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdminCompanion(')
          ..write('idAdmin: $idAdmin, ')
          ..write('cpf: $cpf, ')
          ..write('senhaHash: $senhaHash, ')
          ..write('nome: $nome, ')
          ..write('email: $email, ')
          ..write('telefone: $telefone')
          ..write(')'))
        .toString();
  }
}

abstract class _$GraziDatabase extends GeneratedDatabase {
  _$GraziDatabase(QueryExecutor e) : super(e);
  $GraziDatabaseManager get managers => $GraziDatabaseManager(this);
  late final $AdminTable admin = $AdminTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [admin];
}

typedef $$AdminTableCreateCompanionBuilder = AdminCompanion Function({
  Value<int> idAdmin,
  required String cpf,
  required String senhaHash,
  required String nome,
  required String email,
  Value<String?> telefone,
});
typedef $$AdminTableUpdateCompanionBuilder = AdminCompanion Function({
  Value<int> idAdmin,
  Value<String> cpf,
  Value<String> senhaHash,
  Value<String> nome,
  Value<String> email,
  Value<String?> telefone,
});

class $$AdminTableFilterComposer
    extends Composer<_$GraziDatabase, $AdminTable> {
  $$AdminTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get idAdmin => $composableBuilder(
    column: $table.idAdmin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cpf => $composableBuilder(
    column: $table.cpf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senhaHash => $composableBuilder(
    column: $table.senhaHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telefone => $composableBuilder(
    column: $table.telefone,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AdminTableOrderingComposer
    extends Composer<_$GraziDatabase, $AdminTable> {
  $$AdminTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get idAdmin => $composableBuilder(
    column: $table.idAdmin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cpf => $composableBuilder(
    column: $table.cpf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senhaHash => $composableBuilder(
    column: $table.senhaHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telefone => $composableBuilder(
    column: $table.telefone,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AdminTableAnnotationComposer
    extends Composer<_$GraziDatabase, $AdminTable> {
  $$AdminTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get idAdmin =>
      $composableBuilder(column: $table.idAdmin, builder: (column) => column);

  GeneratedColumn<String> get cpf =>
      $composableBuilder(column: $table.cpf, builder: (column) => column);

  GeneratedColumn<String> get senhaHash =>
      $composableBuilder(column: $table.senhaHash, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get telefone =>
      $composableBuilder(column: $table.telefone, builder: (column) => column);
}

class $$AdminTableTableManager
    extends
        RootTableManager<
          _$GraziDatabase,
          $AdminTable,
          AdminData,
          $$AdminTableFilterComposer,
          $$AdminTableOrderingComposer,
          $$AdminTableAnnotationComposer,
          $$AdminTableCreateCompanionBuilder,
          $$AdminTableUpdateCompanionBuilder,
          (AdminData, BaseReferences<_$GraziDatabase, $AdminTable, AdminData>),
          AdminData,
          PrefetchHooks Function()
        > {
  $$AdminTableTableManager(_$GraziDatabase db, $AdminTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdminTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdminTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AdminTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> idAdmin = const Value.absent(),
                Value<String> cpf = const Value.absent(),
                Value<String> senhaHash = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String?> telefone = const Value.absent(),
              }) => AdminCompanion(
                idAdmin: idAdmin,
                cpf: cpf,
                senhaHash: senhaHash,
                nome: nome,
                email: email,
                telefone: telefone,
              ),
          createCompanionCallback:
              ({
                Value<int> idAdmin = const Value.absent(),
                required String cpf,
                required String senhaHash,
                required String nome,
                required String email,
                Value<String?> telefone = const Value.absent(),
              }) => AdminCompanion.insert(
                idAdmin: idAdmin,
                cpf: cpf,
                senhaHash: senhaHash,
                nome: nome,
                email: email,
                telefone: telefone,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AdminTable, AdminData>(table),
                  BaseReferences<_$GraziDatabase, $AdminTable, AdminData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AdminTableProcessedTableManager =
    ProcessedTableManager<
      _$GraziDatabase,
      $AdminTable,
      AdminData,
      $$AdminTableFilterComposer,
      $$AdminTableOrderingComposer,
      $$AdminTableAnnotationComposer,
      $$AdminTableCreateCompanionBuilder,
      $$AdminTableUpdateCompanionBuilder,
      (AdminData, BaseReferences<_$GraziDatabase, $AdminTable, AdminData>),
      AdminData,
      PrefetchHooks Function()
    >;

class $GraziDatabaseManager {
  final _$GraziDatabase _db;
  $GraziDatabaseManager(this._db);
  $$AdminTableTableManager get admin =>
      $$AdminTableTableManager(_db, _db.admin);
}
