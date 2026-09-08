import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart' as pg;

part 'database.g.dart';

/// Monta o `Endpoint` do Drift a partir de uma URL de conexao.
///
/// Formato:
///   postgresql://USUARIO:SENHA@HOST:PORTA/BANCO?sslmode=disable
///
/// O pacote `postgres` tem `Connection.openFromUrl`, mas ele devolve uma
/// conexao ja aberta — e o `PgDatabase` do Drift quer um `Endpoint`, para
/// abrir e reabrir por conta propria. Por isso a URL e traduzida aqui.
({pg.Endpoint endpoint, pg.SslMode sslMode}) _daUrl(String url) {
  final uri = Uri.parse(url);

  if (uri.scheme != 'postgresql' && uri.scheme != 'postgres') {
    throw ArgumentError.value(
      url,
      'DATABASE_URL',
      'esquema invalido: use postgresql:// ou postgres://',
    );
  }

  final credenciais = uri.userInfo.split(':');
  final banco = uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;

  if (credenciais.length != 2 || banco.isEmpty) {
    throw ArgumentError.value(
      url,
      'DATABASE_URL',
      'formato esperado: '
          'postgresql://USUARIO:SENHA@HOST:PORTA/BANCO?sslmode=disable',
    );
  }

  final sslMode = switch (uri.queryParameters['sslmode']) {
    'disable' => pg.SslMode.disable,
    'require' => pg.SslMode.require,
    null => pg.SslMode.require,
    final outro => throw ArgumentError.value(
        outro,
        'sslmode',
        'valor nao suportado: use disable ou require',
      ),
  };

  return (
    endpoint: pg.Endpoint(
      host: uri.host,
      port: uri.hasPort ? uri.port : 5432,
      database: banco,
      username: Uri.decodeComponent(credenciais[0]),
      password: Uri.decodeComponent(credenciais[1]),
    ),
    sslMode: sslMode,
  );
}

/// Acesso tipado ao PostgreSQL do GraziFit.
///
/// A lista de tabelas esta VAZIA de proposito.
///
/// As classes `Table` do Drift chegam com cada feature, na pasta da
/// feature dona (Fase 4+), e descrevem apenas o subconjunto necessario
/// para consultas tipadas. Elas nunca definem o banco.
///
/// Ver docs/arquitetura.md secao 1 (D58) e secao 4.
@DriftDatabase(tables: [])
class GraziDatabase extends _$GraziDatabase {
  GraziDatabase(super.executor);

  /// Conecta usando `DATABASE_URL`.
  ///
  /// **Nao existe default.** A URL carrega a senha do banco, e D65 e
  /// explicito: *fail fast*, nenhum default silencioso para segredo. Sem
  /// a variavel, o processo nao sobe.
  ///
  /// O `.env` NAO e lido aqui: quem le arquivo de ambiente e o
  /// `config.dart` da Fase 3 (D65). Ate la, a variavel precisa estar no
  /// ambiente do processo.
  factory GraziDatabase.doAmbiente() {
    final url = Platform.environment['DATABASE_URL'];

    if (url == null || url.isEmpty) {
      throw StateError(
        'DATABASE_URL nao esta definida no ambiente deste processo.\n'
        'Formato: '
        'postgresql://USUARIO:SENHA@HOST:PORTA/BANCO?sslmode=disable\n'
        'Veja .env.example na raiz do repositorio.',
      );
    }

    final conexao = _daUrl(url);

    return GraziDatabase(
      PgDatabase(
        endpoint: conexao.endpoint,
        settings: pg.ConnectionSettings(sslMode: conexao.sslMode),

        // Segunda tranca de D58: impede o Drift de criar e manter a
        // propria tabela de versao de schema no banco.
        enableMigrations: false,
      ),
    );
  }

  /// Exigido pelo Drift. **Sem significado neste projeto.**
  ///
  /// O versionamento do banco e feito por SQL numerado em
  /// `database/migrations/`, aplicado por `database/aplicar.sh`. Este
  /// numero nao e consultado por ninguem e nao deve ser incrementado
  /// quando o schema mudar.
  @override
  int get schemaVersion => 1;

  /// Estrategia de migracao DELIBERADAMENTE VAZIA.
  ///
  /// **Nao preencha isto. Nao e um esquecimento.**
  ///
  /// D58: o SQL e a fonte de verdade; o Dart orquestra, nao define o
  /// banco. Todo objeto — tabela, coluna, constraint, indice, view,
  /// funcao e trigger — nasce em `database/schema/` ou em uma migration
  /// numerada, e e aplicado por `database/aplicar.sh`.
  ///
  /// Com estes dois metodos vazios, o Drift nunca emite DDL. Se algum dia
  /// ele discordar do banco, **quem esta errado e o Drift**.
  ///
  /// O schema usa construcoes que nao tem representacao em classe Dart e
  /// que sustentam requisitos verificados:
  ///
  ///   - `GENERATED ALWAYS AS ... STORED` em `avaliacao.imc` (RF-03)
  ///   - `fn_valida_vagas_aula` com `FOR UPDATE` (teste de concorrencia)
  ///   - `fn_valida_aula_cronograma`
  ///   - `CREATE DOMAIN dom_cpf` e `dom_email`
  ///   - as views `vw_aluno_medida_atual` e `vw_aula_ocupacao`
  ///
  /// Deixar o Drift gerar o schema apagaria todas elas.
  ///
  /// Ver docs/arquitetura.md secao 1 e prompt-fase-2 secao 9.2.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {},
        onUpgrade: (m, from, to) async {},
      );
}
