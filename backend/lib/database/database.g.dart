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

class $AlunoTable extends Aluno with TableInfo<$AlunoTable, AlunoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlunoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idAlunoMeta = const VerificationMeta(
    'idAluno',
  );
  @override
  late final GeneratedColumn<int> idAluno = GeneratedColumn<int>(
    'id_aluno',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _idAdminCriadorMeta = const VerificationMeta(
    'idAdminCriador',
  );
  @override
  late final GeneratedColumn<int> idAdminCriador = GeneratedColumn<int>(
    'id_admin_criador',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idEnderecoMeta = const VerificationMeta(
    'idEndereco',
  );
  @override
  late final GeneratedColumn<int> idEndereco = GeneratedColumn<int>(
    'id_endereco',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 255),
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
  static const VerificationMeta _dataNascimentoMeta = const VerificationMeta(
    'dataNascimento',
  );
  @override
  late final GeneratedColumn<PgDate> dataNascimento = GeneratedColumn<PgDate>(
    'data_nascimento',
    aliasedName,
    false,
    type: PgTypes.date,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _telefoneMeta = const VerificationMeta(
    'telefone',
  );
  @override
  late final GeneratedColumn<String> telefone = GeneratedColumn<String>(
    'telefone',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 255),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _restricaoMedicaMeta = const VerificationMeta(
    'restricaoMedica',
  );
  @override
  late final GeneratedColumn<String> restricaoMedica = GeneratedColumn<String>(
    'restricao_medica',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _observacaoSaudeMeta = const VerificationMeta(
    'observacaoSaude',
  );
  @override
  late final GeneratedColumn<String> observacaoSaude = GeneratedColumn<String>(
    'observacao_saude',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<bool> status = GeneratedColumn<bool>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("status" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _dataCadastroMeta = const VerificationMeta(
    'dataCadastro',
  );
  @override
  late final GeneratedColumn<PgDate> dataCadastro = GeneratedColumn<PgDate>(
    'data_cadastro',
    aliasedName,
    false,
    type: PgTypes.date,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression<PgDate>('CURRENT_DATE'),
  );
  static const VerificationMeta _dataUltimoAcessoMeta = const VerificationMeta(
    'dataUltimoAcesso',
  );
  @override
  late final GeneratedColumn<PgDateTime> dataUltimoAcesso =
      GeneratedColumn<PgDateTime>(
        'data_ultimo_acesso',
        aliasedName,
        true,
        type: PgTypes.timestampWithTimezone,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    idAluno,
    idAdminCriador,
    idEndereco,
    cpf,
    senhaHash,
    nome,
    dataNascimento,
    telefone,
    email,
    restricaoMedica,
    observacaoSaude,
    status,
    dataCadastro,
    dataUltimoAcesso,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'aluno';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlunoData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_aluno')) {
      context.handle(
        _idAlunoMeta,
        idAluno.isAcceptableOrUnknown(data['id_aluno']!, _idAlunoMeta),
      );
    }
    if (data.containsKey('id_admin_criador')) {
      context.handle(
        _idAdminCriadorMeta,
        idAdminCriador.isAcceptableOrUnknown(
          data['id_admin_criador']!,
          _idAdminCriadorMeta,
        ),
      );
    }
    if (data.containsKey('id_endereco')) {
      context.handle(
        _idEnderecoMeta,
        idEndereco.isAcceptableOrUnknown(data['id_endereco']!, _idEnderecoMeta),
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
    if (data.containsKey('data_nascimento')) {
      context.handle(
        _dataNascimentoMeta,
        dataNascimento.isAcceptableOrUnknown(
          data['data_nascimento']!,
          _dataNascimentoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dataNascimentoMeta);
    }
    if (data.containsKey('telefone')) {
      context.handle(
        _telefoneMeta,
        telefone.isAcceptableOrUnknown(data['telefone']!, _telefoneMeta),
      );
    } else if (isInserting) {
      context.missing(_telefoneMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('restricao_medica')) {
      context.handle(
        _restricaoMedicaMeta,
        restricaoMedica.isAcceptableOrUnknown(
          data['restricao_medica']!,
          _restricaoMedicaMeta,
        ),
      );
    }
    if (data.containsKey('observacao_saude')) {
      context.handle(
        _observacaoSaudeMeta,
        observacaoSaude.isAcceptableOrUnknown(
          data['observacao_saude']!,
          _observacaoSaudeMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('data_cadastro')) {
      context.handle(
        _dataCadastroMeta,
        dataCadastro.isAcceptableOrUnknown(
          data['data_cadastro']!,
          _dataCadastroMeta,
        ),
      );
    }
    if (data.containsKey('data_ultimo_acesso')) {
      context.handle(
        _dataUltimoAcessoMeta,
        dataUltimoAcesso.isAcceptableOrUnknown(
          data['data_ultimo_acesso']!,
          _dataUltimoAcessoMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {idAluno};
  @override
  AlunoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlunoData(
      idAluno: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id_aluno'],
      )!,
      idAdminCriador: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id_admin_criador'],
      ),
      idEndereco: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id_endereco'],
      ),
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
      dataNascimento: attachedDatabase.typeMapping.read(
        PgTypes.date,
        data['${effectivePrefix}data_nascimento'],
      )!,
      telefone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telefone'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      restricaoMedica: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}restricao_medica'],
      ),
      observacaoSaude: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observacao_saude'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}status'],
      ),
      dataCadastro: attachedDatabase.typeMapping.read(
        PgTypes.date,
        data['${effectivePrefix}data_cadastro'],
      )!,
      dataUltimoAcesso: attachedDatabase.typeMapping.read(
        PgTypes.timestampWithTimezone,
        data['${effectivePrefix}data_ultimo_acesso'],
      ),
    );
  }

  @override
  $AlunoTable createAlias(String alias) {
    return $AlunoTable(attachedDatabase, alias);
  }
}

class AlunoData extends DataClass implements Insertable<AlunoData> {
  final int idAluno;
  final int? idAdminCriador;
  final int? idEndereco;
  final String cpf;
  final String senhaHash;
  final String nome;
  final PgDate dataNascimento;
  final String telefone;
  final String email;
  final String? restricaoMedica;
  final String? observacaoSaude;
  final bool? status;
  final PgDate dataCadastro;
  final PgDateTime? dataUltimoAcesso;
  const AlunoData({
    required this.idAluno,
    this.idAdminCriador,
    this.idEndereco,
    required this.cpf,
    required this.senhaHash,
    required this.nome,
    required this.dataNascimento,
    required this.telefone,
    required this.email,
    this.restricaoMedica,
    this.observacaoSaude,
    this.status,
    required this.dataCadastro,
    this.dataUltimoAcesso,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_aluno'] = Variable<int>(idAluno);
    if (!nullToAbsent || idAdminCriador != null) {
      map['id_admin_criador'] = Variable<int>(idAdminCriador);
    }
    if (!nullToAbsent || idEndereco != null) {
      map['id_endereco'] = Variable<int>(idEndereco);
    }
    map['cpf'] = Variable<String>(cpf);
    map['senha_hash'] = Variable<String>(senhaHash);
    map['nome'] = Variable<String>(nome);
    map['data_nascimento'] = Variable<PgDate>(dataNascimento, PgTypes.date);
    map['telefone'] = Variable<String>(telefone);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || restricaoMedica != null) {
      map['restricao_medica'] = Variable<String>(restricaoMedica);
    }
    if (!nullToAbsent || observacaoSaude != null) {
      map['observacao_saude'] = Variable<String>(observacaoSaude);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<bool>(status);
    }
    map['data_cadastro'] = Variable<PgDate>(dataCadastro, PgTypes.date);
    if (!nullToAbsent || dataUltimoAcesso != null) {
      map['data_ultimo_acesso'] = Variable<PgDateTime>(
        dataUltimoAcesso,
        PgTypes.timestampWithTimezone,
      );
    }
    return map;
  }

  AlunoCompanion toCompanion(bool nullToAbsent) {
    return AlunoCompanion(
      idAluno: Value(idAluno),
      idAdminCriador: idAdminCriador == null && nullToAbsent
          ? const Value.absent()
          : Value(idAdminCriador),
      idEndereco: idEndereco == null && nullToAbsent
          ? const Value.absent()
          : Value(idEndereco),
      cpf: Value(cpf),
      senhaHash: Value(senhaHash),
      nome: Value(nome),
      dataNascimento: Value(dataNascimento),
      telefone: Value(telefone),
      email: Value(email),
      restricaoMedica: restricaoMedica == null && nullToAbsent
          ? const Value.absent()
          : Value(restricaoMedica),
      observacaoSaude: observacaoSaude == null && nullToAbsent
          ? const Value.absent()
          : Value(observacaoSaude),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      dataCadastro: Value(dataCadastro),
      dataUltimoAcesso: dataUltimoAcesso == null && nullToAbsent
          ? const Value.absent()
          : Value(dataUltimoAcesso),
    );
  }

  factory AlunoData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlunoData(
      idAluno: serializer.fromJson<int>(json['idAluno']),
      idAdminCriador: serializer.fromJson<int?>(json['idAdminCriador']),
      idEndereco: serializer.fromJson<int?>(json['idEndereco']),
      cpf: serializer.fromJson<String>(json['cpf']),
      senhaHash: serializer.fromJson<String>(json['senhaHash']),
      nome: serializer.fromJson<String>(json['nome']),
      dataNascimento: serializer.fromJson<PgDate>(json['dataNascimento']),
      telefone: serializer.fromJson<String>(json['telefone']),
      email: serializer.fromJson<String>(json['email']),
      restricaoMedica: serializer.fromJson<String?>(json['restricaoMedica']),
      observacaoSaude: serializer.fromJson<String?>(json['observacaoSaude']),
      status: serializer.fromJson<bool?>(json['status']),
      dataCadastro: serializer.fromJson<PgDate>(json['dataCadastro']),
      dataUltimoAcesso: serializer.fromJson<PgDateTime?>(
        json['dataUltimoAcesso'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idAluno': serializer.toJson<int>(idAluno),
      'idAdminCriador': serializer.toJson<int?>(idAdminCriador),
      'idEndereco': serializer.toJson<int?>(idEndereco),
      'cpf': serializer.toJson<String>(cpf),
      'senhaHash': serializer.toJson<String>(senhaHash),
      'nome': serializer.toJson<String>(nome),
      'dataNascimento': serializer.toJson<PgDate>(dataNascimento),
      'telefone': serializer.toJson<String>(telefone),
      'email': serializer.toJson<String>(email),
      'restricaoMedica': serializer.toJson<String?>(restricaoMedica),
      'observacaoSaude': serializer.toJson<String?>(observacaoSaude),
      'status': serializer.toJson<bool?>(status),
      'dataCadastro': serializer.toJson<PgDate>(dataCadastro),
      'dataUltimoAcesso': serializer.toJson<PgDateTime?>(dataUltimoAcesso),
    };
  }

  AlunoData copyWith({
    int? idAluno,
    Value<int?> idAdminCriador = const Value.absent(),
    Value<int?> idEndereco = const Value.absent(),
    String? cpf,
    String? senhaHash,
    String? nome,
    PgDate? dataNascimento,
    String? telefone,
    String? email,
    Value<String?> restricaoMedica = const Value.absent(),
    Value<String?> observacaoSaude = const Value.absent(),
    Value<bool?> status = const Value.absent(),
    PgDate? dataCadastro,
    Value<PgDateTime?> dataUltimoAcesso = const Value.absent(),
  }) => AlunoData(
    idAluno: idAluno ?? this.idAluno,
    idAdminCriador: idAdminCriador.present
        ? idAdminCriador.value
        : this.idAdminCriador,
    idEndereco: idEndereco.present ? idEndereco.value : this.idEndereco,
    cpf: cpf ?? this.cpf,
    senhaHash: senhaHash ?? this.senhaHash,
    nome: nome ?? this.nome,
    dataNascimento: dataNascimento ?? this.dataNascimento,
    telefone: telefone ?? this.telefone,
    email: email ?? this.email,
    restricaoMedica: restricaoMedica.present
        ? restricaoMedica.value
        : this.restricaoMedica,
    observacaoSaude: observacaoSaude.present
        ? observacaoSaude.value
        : this.observacaoSaude,
    status: status.present ? status.value : this.status,
    dataCadastro: dataCadastro ?? this.dataCadastro,
    dataUltimoAcesso: dataUltimoAcesso.present
        ? dataUltimoAcesso.value
        : this.dataUltimoAcesso,
  );
  AlunoData copyWithCompanion(AlunoCompanion data) {
    return AlunoData(
      idAluno: data.idAluno.present ? data.idAluno.value : this.idAluno,
      idAdminCriador: data.idAdminCriador.present
          ? data.idAdminCriador.value
          : this.idAdminCriador,
      idEndereco: data.idEndereco.present
          ? data.idEndereco.value
          : this.idEndereco,
      cpf: data.cpf.present ? data.cpf.value : this.cpf,
      senhaHash: data.senhaHash.present ? data.senhaHash.value : this.senhaHash,
      nome: data.nome.present ? data.nome.value : this.nome,
      dataNascimento: data.dataNascimento.present
          ? data.dataNascimento.value
          : this.dataNascimento,
      telefone: data.telefone.present ? data.telefone.value : this.telefone,
      email: data.email.present ? data.email.value : this.email,
      restricaoMedica: data.restricaoMedica.present
          ? data.restricaoMedica.value
          : this.restricaoMedica,
      observacaoSaude: data.observacaoSaude.present
          ? data.observacaoSaude.value
          : this.observacaoSaude,
      status: data.status.present ? data.status.value : this.status,
      dataCadastro: data.dataCadastro.present
          ? data.dataCadastro.value
          : this.dataCadastro,
      dataUltimoAcesso: data.dataUltimoAcesso.present
          ? data.dataUltimoAcesso.value
          : this.dataUltimoAcesso,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlunoData(')
          ..write('idAluno: $idAluno, ')
          ..write('idAdminCriador: $idAdminCriador, ')
          ..write('idEndereco: $idEndereco, ')
          ..write('cpf: $cpf, ')
          ..write('senhaHash: $senhaHash, ')
          ..write('nome: $nome, ')
          ..write('dataNascimento: $dataNascimento, ')
          ..write('telefone: $telefone, ')
          ..write('email: $email, ')
          ..write('restricaoMedica: $restricaoMedica, ')
          ..write('observacaoSaude: $observacaoSaude, ')
          ..write('status: $status, ')
          ..write('dataCadastro: $dataCadastro, ')
          ..write('dataUltimoAcesso: $dataUltimoAcesso')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    idAluno,
    idAdminCriador,
    idEndereco,
    cpf,
    senhaHash,
    nome,
    dataNascimento,
    telefone,
    email,
    restricaoMedica,
    observacaoSaude,
    status,
    dataCadastro,
    dataUltimoAcesso,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlunoData &&
          other.idAluno == this.idAluno &&
          other.idAdminCriador == this.idAdminCriador &&
          other.idEndereco == this.idEndereco &&
          other.cpf == this.cpf &&
          other.senhaHash == this.senhaHash &&
          other.nome == this.nome &&
          other.dataNascimento == this.dataNascimento &&
          other.telefone == this.telefone &&
          other.email == this.email &&
          other.restricaoMedica == this.restricaoMedica &&
          other.observacaoSaude == this.observacaoSaude &&
          other.status == this.status &&
          other.dataCadastro == this.dataCadastro &&
          other.dataUltimoAcesso == this.dataUltimoAcesso);
}

class AlunoCompanion extends UpdateCompanion<AlunoData> {
  final Value<int> idAluno;
  final Value<int?> idAdminCriador;
  final Value<int?> idEndereco;
  final Value<String> cpf;
  final Value<String> senhaHash;
  final Value<String> nome;
  final Value<PgDate> dataNascimento;
  final Value<String> telefone;
  final Value<String> email;
  final Value<String?> restricaoMedica;
  final Value<String?> observacaoSaude;
  final Value<bool?> status;
  final Value<PgDate> dataCadastro;
  final Value<PgDateTime?> dataUltimoAcesso;
  const AlunoCompanion({
    this.idAluno = const Value.absent(),
    this.idAdminCriador = const Value.absent(),
    this.idEndereco = const Value.absent(),
    this.cpf = const Value.absent(),
    this.senhaHash = const Value.absent(),
    this.nome = const Value.absent(),
    this.dataNascimento = const Value.absent(),
    this.telefone = const Value.absent(),
    this.email = const Value.absent(),
    this.restricaoMedica = const Value.absent(),
    this.observacaoSaude = const Value.absent(),
    this.status = const Value.absent(),
    this.dataCadastro = const Value.absent(),
    this.dataUltimoAcesso = const Value.absent(),
  });
  AlunoCompanion.insert({
    this.idAluno = const Value.absent(),
    this.idAdminCriador = const Value.absent(),
    this.idEndereco = const Value.absent(),
    required String cpf,
    required String senhaHash,
    required String nome,
    required PgDate dataNascimento,
    required String telefone,
    required String email,
    this.restricaoMedica = const Value.absent(),
    this.observacaoSaude = const Value.absent(),
    this.status = const Value.absent(),
    this.dataCadastro = const Value.absent(),
    this.dataUltimoAcesso = const Value.absent(),
  }) : cpf = Value(cpf),
       senhaHash = Value(senhaHash),
       nome = Value(nome),
       dataNascimento = Value(dataNascimento),
       telefone = Value(telefone),
       email = Value(email);
  static Insertable<AlunoData> custom({
    Expression<int>? idAluno,
    Expression<int>? idAdminCriador,
    Expression<int>? idEndereco,
    Expression<String>? cpf,
    Expression<String>? senhaHash,
    Expression<String>? nome,
    Expression<PgDate>? dataNascimento,
    Expression<String>? telefone,
    Expression<String>? email,
    Expression<String>? restricaoMedica,
    Expression<String>? observacaoSaude,
    Expression<bool>? status,
    Expression<PgDate>? dataCadastro,
    Expression<PgDateTime>? dataUltimoAcesso,
  }) {
    return RawValuesInsertable({
      if (idAluno != null) 'id_aluno': idAluno,
      if (idAdminCriador != null) 'id_admin_criador': idAdminCriador,
      if (idEndereco != null) 'id_endereco': idEndereco,
      if (cpf != null) 'cpf': cpf,
      if (senhaHash != null) 'senha_hash': senhaHash,
      if (nome != null) 'nome': nome,
      if (dataNascimento != null) 'data_nascimento': dataNascimento,
      if (telefone != null) 'telefone': telefone,
      if (email != null) 'email': email,
      if (restricaoMedica != null) 'restricao_medica': restricaoMedica,
      if (observacaoSaude != null) 'observacao_saude': observacaoSaude,
      if (status != null) 'status': status,
      if (dataCadastro != null) 'data_cadastro': dataCadastro,
      if (dataUltimoAcesso != null) 'data_ultimo_acesso': dataUltimoAcesso,
    });
  }

  AlunoCompanion copyWith({
    Value<int>? idAluno,
    Value<int?>? idAdminCriador,
    Value<int?>? idEndereco,
    Value<String>? cpf,
    Value<String>? senhaHash,
    Value<String>? nome,
    Value<PgDate>? dataNascimento,
    Value<String>? telefone,
    Value<String>? email,
    Value<String?>? restricaoMedica,
    Value<String?>? observacaoSaude,
    Value<bool?>? status,
    Value<PgDate>? dataCadastro,
    Value<PgDateTime?>? dataUltimoAcesso,
  }) {
    return AlunoCompanion(
      idAluno: idAluno ?? this.idAluno,
      idAdminCriador: idAdminCriador ?? this.idAdminCriador,
      idEndereco: idEndereco ?? this.idEndereco,
      cpf: cpf ?? this.cpf,
      senhaHash: senhaHash ?? this.senhaHash,
      nome: nome ?? this.nome,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
      restricaoMedica: restricaoMedica ?? this.restricaoMedica,
      observacaoSaude: observacaoSaude ?? this.observacaoSaude,
      status: status ?? this.status,
      dataCadastro: dataCadastro ?? this.dataCadastro,
      dataUltimoAcesso: dataUltimoAcesso ?? this.dataUltimoAcesso,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idAluno.present) {
      map['id_aluno'] = Variable<int>(idAluno.value);
    }
    if (idAdminCriador.present) {
      map['id_admin_criador'] = Variable<int>(idAdminCriador.value);
    }
    if (idEndereco.present) {
      map['id_endereco'] = Variable<int>(idEndereco.value);
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
    if (dataNascimento.present) {
      map['data_nascimento'] = Variable<PgDate>(
        dataNascimento.value,
        PgTypes.date,
      );
    }
    if (telefone.present) {
      map['telefone'] = Variable<String>(telefone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (restricaoMedica.present) {
      map['restricao_medica'] = Variable<String>(restricaoMedica.value);
    }
    if (observacaoSaude.present) {
      map['observacao_saude'] = Variable<String>(observacaoSaude.value);
    }
    if (status.present) {
      map['status'] = Variable<bool>(status.value);
    }
    if (dataCadastro.present) {
      map['data_cadastro'] = Variable<PgDate>(dataCadastro.value, PgTypes.date);
    }
    if (dataUltimoAcesso.present) {
      map['data_ultimo_acesso'] = Variable<PgDateTime>(
        dataUltimoAcesso.value,
        PgTypes.timestampWithTimezone,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlunoCompanion(')
          ..write('idAluno: $idAluno, ')
          ..write('idAdminCriador: $idAdminCriador, ')
          ..write('idEndereco: $idEndereco, ')
          ..write('cpf: $cpf, ')
          ..write('senhaHash: $senhaHash, ')
          ..write('nome: $nome, ')
          ..write('dataNascimento: $dataNascimento, ')
          ..write('telefone: $telefone, ')
          ..write('email: $email, ')
          ..write('restricaoMedica: $restricaoMedica, ')
          ..write('observacaoSaude: $observacaoSaude, ')
          ..write('status: $status, ')
          ..write('dataCadastro: $dataCadastro, ')
          ..write('dataUltimoAcesso: $dataUltimoAcesso')
          ..write(')'))
        .toString();
  }
}

abstract class _$GraziDatabase extends GeneratedDatabase {
  _$GraziDatabase(QueryExecutor e) : super(e);
  $GraziDatabaseManager get managers => $GraziDatabaseManager(this);
  late final $AdminTable admin = $AdminTable(this);
  late final $AlunoTable aluno = $AlunoTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [admin, aluno];
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
typedef $$AlunoTableCreateCompanionBuilder = AlunoCompanion Function({
  Value<int> idAluno,
  Value<int?> idAdminCriador,
  Value<int?> idEndereco,
  required String cpf,
  required String senhaHash,
  required String nome,
  required PgDate dataNascimento,
  required String telefone,
  required String email,
  Value<String?> restricaoMedica,
  Value<String?> observacaoSaude,
  Value<bool?> status,
  Value<PgDate> dataCadastro,
  Value<PgDateTime?> dataUltimoAcesso,
});
typedef $$AlunoTableUpdateCompanionBuilder = AlunoCompanion Function({
  Value<int> idAluno,
  Value<int?> idAdminCriador,
  Value<int?> idEndereco,
  Value<String> cpf,
  Value<String> senhaHash,
  Value<String> nome,
  Value<PgDate> dataNascimento,
  Value<String> telefone,
  Value<String> email,
  Value<String?> restricaoMedica,
  Value<String?> observacaoSaude,
  Value<bool?> status,
  Value<PgDate> dataCadastro,
  Value<PgDateTime?> dataUltimoAcesso,
});

class $$AlunoTableFilterComposer
    extends Composer<_$GraziDatabase, $AlunoTable> {
  $$AlunoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get idAluno => $composableBuilder(
    column: $table.idAluno,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get idAdminCriador => $composableBuilder(
    column: $table.idAdminCriador,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get idEndereco => $composableBuilder(
    column: $table.idEndereco,
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

  ColumnFilters<PgDate> get dataNascimento => $composableBuilder(
    column: $table.dataNascimento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telefone => $composableBuilder(
    column: $table.telefone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get restricaoMedica => $composableBuilder(
    column: $table.restricaoMedica,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observacaoSaude => $composableBuilder(
    column: $table.observacaoSaude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<PgDate> get dataCadastro => $composableBuilder(
    column: $table.dataCadastro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<PgDateTime> get dataUltimoAcesso => $composableBuilder(
    column: $table.dataUltimoAcesso,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlunoTableOrderingComposer
    extends Composer<_$GraziDatabase, $AlunoTable> {
  $$AlunoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get idAluno => $composableBuilder(
    column: $table.idAluno,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get idAdminCriador => $composableBuilder(
    column: $table.idAdminCriador,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get idEndereco => $composableBuilder(
    column: $table.idEndereco,
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

  ColumnOrderings<PgDate> get dataNascimento => $composableBuilder(
    column: $table.dataNascimento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telefone => $composableBuilder(
    column: $table.telefone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get restricaoMedica => $composableBuilder(
    column: $table.restricaoMedica,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observacaoSaude => $composableBuilder(
    column: $table.observacaoSaude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<PgDate> get dataCadastro => $composableBuilder(
    column: $table.dataCadastro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<PgDateTime> get dataUltimoAcesso => $composableBuilder(
    column: $table.dataUltimoAcesso,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlunoTableAnnotationComposer
    extends Composer<_$GraziDatabase, $AlunoTable> {
  $$AlunoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get idAluno =>
      $composableBuilder(column: $table.idAluno, builder: (column) => column);

  GeneratedColumn<int> get idAdminCriador => $composableBuilder(
    column: $table.idAdminCriador,
    builder: (column) => column,
  );

  GeneratedColumn<int> get idEndereco => $composableBuilder(
    column: $table.idEndereco,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cpf =>
      $composableBuilder(column: $table.cpf, builder: (column) => column);

  GeneratedColumn<String> get senhaHash =>
      $composableBuilder(column: $table.senhaHash, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<PgDate> get dataNascimento => $composableBuilder(
    column: $table.dataNascimento,
    builder: (column) => column,
  );

  GeneratedColumn<String> get telefone =>
      $composableBuilder(column: $table.telefone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get restricaoMedica => $composableBuilder(
    column: $table.restricaoMedica,
    builder: (column) => column,
  );

  GeneratedColumn<String> get observacaoSaude => $composableBuilder(
    column: $table.observacaoSaude,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<PgDate> get dataCadastro => $composableBuilder(
    column: $table.dataCadastro,
    builder: (column) => column,
  );

  GeneratedColumn<PgDateTime> get dataUltimoAcesso => $composableBuilder(
    column: $table.dataUltimoAcesso,
    builder: (column) => column,
  );
}

class $$AlunoTableTableManager
    extends
        RootTableManager<
          _$GraziDatabase,
          $AlunoTable,
          AlunoData,
          $$AlunoTableFilterComposer,
          $$AlunoTableOrderingComposer,
          $$AlunoTableAnnotationComposer,
          $$AlunoTableCreateCompanionBuilder,
          $$AlunoTableUpdateCompanionBuilder,
          (AlunoData, BaseReferences<_$GraziDatabase, $AlunoTable, AlunoData>),
          AlunoData,
          PrefetchHooks Function()
        > {
  $$AlunoTableTableManager(_$GraziDatabase db, $AlunoTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlunoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlunoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlunoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> idAluno = const Value.absent(),
                Value<int?> idAdminCriador = const Value.absent(),
                Value<int?> idEndereco = const Value.absent(),
                Value<String> cpf = const Value.absent(),
                Value<String> senhaHash = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<PgDate> dataNascimento = const Value.absent(),
                Value<String> telefone = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String?> restricaoMedica = const Value.absent(),
                Value<String?> observacaoSaude = const Value.absent(),
                Value<bool?> status = const Value.absent(),
                Value<PgDate> dataCadastro = const Value.absent(),
                Value<PgDateTime?> dataUltimoAcesso = const Value.absent(),
              }) => AlunoCompanion(
                idAluno: idAluno,
                idAdminCriador: idAdminCriador,
                idEndereco: idEndereco,
                cpf: cpf,
                senhaHash: senhaHash,
                nome: nome,
                dataNascimento: dataNascimento,
                telefone: telefone,
                email: email,
                restricaoMedica: restricaoMedica,
                observacaoSaude: observacaoSaude,
                status: status,
                dataCadastro: dataCadastro,
                dataUltimoAcesso: dataUltimoAcesso,
              ),
          createCompanionCallback:
              ({
                Value<int> idAluno = const Value.absent(),
                Value<int?> idAdminCriador = const Value.absent(),
                Value<int?> idEndereco = const Value.absent(),
                required String cpf,
                required String senhaHash,
                required String nome,
                required PgDate dataNascimento,
                required String telefone,
                required String email,
                Value<String?> restricaoMedica = const Value.absent(),
                Value<String?> observacaoSaude = const Value.absent(),
                Value<bool?> status = const Value.absent(),
                Value<PgDate> dataCadastro = const Value.absent(),
                Value<PgDateTime?> dataUltimoAcesso = const Value.absent(),
              }) => AlunoCompanion.insert(
                idAluno: idAluno,
                idAdminCriador: idAdminCriador,
                idEndereco: idEndereco,
                cpf: cpf,
                senhaHash: senhaHash,
                nome: nome,
                dataNascimento: dataNascimento,
                telefone: telefone,
                email: email,
                restricaoMedica: restricaoMedica,
                observacaoSaude: observacaoSaude,
                status: status,
                dataCadastro: dataCadastro,
                dataUltimoAcesso: dataUltimoAcesso,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AlunoTable, AlunoData>(table),
                  BaseReferences<_$GraziDatabase, $AlunoTable, AlunoData>(
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

typedef $$AlunoTableProcessedTableManager =
    ProcessedTableManager<
      _$GraziDatabase,
      $AlunoTable,
      AlunoData,
      $$AlunoTableFilterComposer,
      $$AlunoTableOrderingComposer,
      $$AlunoTableAnnotationComposer,
      $$AlunoTableCreateCompanionBuilder,
      $$AlunoTableUpdateCompanionBuilder,
      (AlunoData, BaseReferences<_$GraziDatabase, $AlunoTable, AlunoData>),
      AlunoData,
      PrefetchHooks Function()
    >;

class $GraziDatabaseManager {
  final _$GraziDatabase _db;
  $GraziDatabaseManager(this._db);
  $$AdminTableTableManager get admin =>
      $$AdminTableTableManager(_db, _db.admin);
  $$AlunoTableTableManager get aluno =>
      $$AlunoTableTableManager(_db, _db.aluno);
}
