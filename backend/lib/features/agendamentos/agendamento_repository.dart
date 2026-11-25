import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart' show PgDate, PgDateTime;

import '../../database/database.dart';

/// Regras de tempo calculadas pelo Postgres, na mesma consulta que le a aula.
/// O Dart nao converte fuso: "hoje" e "agora" sao de America/Sao_Paulo no
/// banco, qualquer que seja o fuso do host ou da sessao.
class RegrasDeTempo {
  /// Aula com data anterior ao dia civil de Brasilia.
  final bool dataPassada;

  /// Faltam menos de 2 horas para o inicio da aula, ou ela ja comecou.
  final bool dentroDaJanela;

  /// Ano civil de hoje em Brasilia, para a regra de vigencia.
  final int anoHoje;

  /// Dia civil de hoje em Brasilia. Grava `data_agendamento`.
  final PgDate hoje;

  const RegrasDeTempo({
    required this.dataPassada,
    required this.dentroDaJanela,
    required this.anoHoje,
    required this.hoje,
  });
}

/// Aula lida com as regras de tempo, numa so ida ao banco.
class AulaLida {
  final AulaData aula;
  final RegrasDeTempo regras;

  const AulaLida({required this.aula, required this.regras});
}

/// Aula travada para a chamada. [antesDoInicio] vem do Postgres, no mesmo
/// fuso das demais regras de tempo.
class AulaChamada {
  final AulaData aula;
  final bool antesDoInicio;

  const AulaChamada({required this.aula, required this.antesDoInicio});
}

/// Situacao lida sob a trava da aula, numa so ida ao banco.
class SituacaoReserva {
  /// Aula travada (FOR UPDATE).
  final AulaData aula;

  /// Regras de tempo, calculadas na mesma consulta da trava.
  final RegrasDeTempo regras;

  /// Agendamentos que ocupam vaga, na mesma leitura.
  final int ocupadas;

  /// Agendamento do aluno nesta aula, qualquer status. `null` se nao houver.
  final int? idAgendamentoExistente;
  final String? statusExistente;

  const SituacaoReserva({
    required this.aula,
    required this.regras,
    required this.ocupadas,
    this.idAgendamentoExistente,
    this.statusExistente,
  });
}

/// Status que NAO ocupam vaga. Fonte unica no Dart da regra "vaga ocupada":
/// usada no SQL de `agendamento_repository.dart` (via [condicaoVagaOcupada])
/// e nos fakes de teste. O trigger `fn_valida_vagas_aula` e a view
/// `vw_aula_ocupacao` (`database/schema/grazi_db_init_schema.sql`) repetem a
/// mesma lista em SQL: sem alterar o banco, mudar a lista exige mudar la tambem.
const List<String> statusQueNaoOcupamVaga = ['cancelado', 'faltou'];

/// Trecho SQL da regra "vaga ocupada", gerado de [statusQueNaoOcupamVaga].
/// [prefixo] e o alias da tabela com ponto (ex.: `'g.'`), ou vazio.
String condicaoVagaOcupada({String prefixo = ''}) {
  final lista = statusQueNaoOcupamVaga.map((s) => "'$s'").join(', ');
  return '${prefixo}status NOT IN ($lista)';
}

/// Colunas de regra de tempo, somadas ao SELECT de `aula`. O fuso e explicito
/// (`America/Sao_Paulo`) e o relogio vem do proprio banco.
/// `clock_timestamp()`. Na reserva, a checagem que roda depois da
/// trava (`FOR UPDATE`) precisa do horario real do momento, e nao do `BEGIN`,
/// que pode ser anterior por causa da espera da trava. A janela de 2 horas
/// (`INTERVAL`) tem que bater com `AgendamentoService.antecedenciaMinima`.
const _colunasDeRegra = r'''
             (au.data < (clock_timestamp() AT TIME ZONE 'America/Sao_Paulo')::date)
               AS regra_data_passada,
             (((au.data + au.hora_inicio) AT TIME ZONE 'America/Sao_Paulo')
                - clock_timestamp()) < INTERVAL '2 hours'
               AS regra_dentro_janela,
             EXTRACT(YEAR  FROM clock_timestamp() AT TIME ZONE 'America/Sao_Paulo')::int
               AS regra_ano,
             EXTRACT(MONTH FROM clock_timestamp() AT TIME ZONE 'America/Sao_Paulo')::int
               AS regra_mes,
             EXTRACT(DAY   FROM clock_timestamp() AT TIME ZONE 'America/Sao_Paulo')::int
               AS regra_dia''';

/// Acesso a tabela `agendamento`. Unica classe que escreve nela (regra de
/// propriedade). Le `aula` (e trava com FOR UPDATE), sem escrever nela.
class AgendamentoRepository {
  final GraziDatabase _db;

  AgendamentoRepository(this._db);

  Future<T> transacao<T>(Future<T> Function() acao) => _db.transaction(acao);

  /// Uma ida ao banco: trava a aula (`FOR UPDATE`, a mesma trava de
  /// `fn_valida_vagas_aula`) e devolve junto as vagas ocupadas e o
  /// agendamento do aluno nessa aula. Usar dentro de [transacao].
  /// `null` quando a aula nao existe.
  ///
  /// A subconsulta de vagas usa o snapshot do inicio do comando. Se a trava
  /// esperou outra transacao, o numero pode estar um commit atras. O
  /// INSERT/UPDATE seguinte roda com snapshot novo: o trigger
  /// `fn_valida_vagas_aula` e a unique
  /// `uq_agendamento_aluno_aula` continuam sendo a defesa final.
  Future<SituacaoReserva?> travarSituacaoParaReserva(
    int idAula,
    int idAluno,
  ) async {
    final linha = await _db
        .customSelect(
          r'''
      SELECT au.*,
             (SELECT COUNT(*)::int
                FROM agendamento g
               WHERE g.id_aula = au.id_aula
                 AND ''' +
              condicaoVagaOcupada(prefixo: 'g.') +
              r''') AS ocupadas,
             ag.id_agendamento AS ag_id,
             ag.status AS ag_status,
             ''' +
              _colunasDeRegra +
              r'''
             FROM aula au
        LEFT JOIN agendamento ag
               ON ag.id_aula = au.id_aula AND ag.id_aluno = $2
       WHERE au.id_aula = $1
         FOR UPDATE OF au
    ''',
          variables: [Variable.withInt(idAula), Variable.withInt(idAluno)],
          readsFrom: {_db.aula, _db.agendamento},
        )
        .getSingleOrNull();
    if (linha == null) return null;
    return SituacaoReserva(
      aula: _db.aula.map(linha.data),
      regras: _lerRegras(linha),
      ocupadas: linha.read<int>('ocupadas'),
      idAgendamentoExistente: linha.read<int?>('ag_id'),
      statusExistente: linha.read<String?>('ag_status'),
    );
  }

  /// Aula sem trava, com as regras de tempo na mesma consulta. `null` se nao
  /// existir.
  Future<AulaLida?> buscarAula(int idAula) async {
    final linha = await _db
        .customSelect(
          r'''
      SELECT au.*,
''' +
              _colunasDeRegra +
              r'''
        FROM aula au
       WHERE au.id_aula = $1
    ''',
          variables: [Variable.withInt(idAula)],
          readsFrom: {_db.aula},
        )
        .getSingleOrNull();
    if (linha == null) return null;
    return AulaLida(aula: _db.aula.map(linha.data), regras: _lerRegras(linha));
  }

  static RegrasDeTempo _lerRegras(QueryRow linha) => RegrasDeTempo(
    dataPassada: linha.read<bool>('regra_data_passada'),
    dentroDaJanela: linha.read<bool>('regra_dentro_janela'),
    anoHoje: linha.read<int>('regra_ano'),
    hoje: PgDate(
      year: linha.read<int>('regra_ano'),
      month: linha.read<int>('regra_mes'),
      day: linha.read<int>('regra_dia'),
    ),
  );

  /// Leitura simples, sem trava. Usada para checar o dono antes de travar a
  /// linha: quem nao e dono nao segura o `FOR UPDATE` de terceiros.
  Future<AgendamentoData?> buscarSemTrava(int idAgendamento) {
    return (_db.select(
      _db.agendamento,
    )..where((t) => t.idAgendamento.equals(idAgendamento))).getSingleOrNull();
  }

  /// Le o agendamento com `FOR UPDATE`; usar dentro de [transacao].
  Future<AgendamentoData?> buscarParaAtualizar(int idAgendamento) async {
    final linha = await _db
        .customSelect(
          r'SELECT * FROM agendamento WHERE id_agendamento = $1 FOR UPDATE',
          variables: [Variable.withInt(idAgendamento)],
          readsFrom: {_db.agendamento},
        )
        .getSingleOrNull();
    return linha == null ? null : _db.agendamento.map(linha.data);
  }

  /// Qualquer status: a constraint `uq_agendamento_aluno_aula` vale para todos.
  Future<AgendamentoData?> buscarPorAlunoAula(int idAluno, int idAula) {
    return (_db.select(_db.agendamento)
          ..where((t) => t.idAluno.equals(idAluno) & t.idAula.equals(idAula)))
        .getSingleOrNull();
  }

  /// Agendamentos que ocupam vaga (fora `cancelado` e `faltou`).
  Future<int> contarAtivos(int idAula) async {
    final linha = await _db
        .customSelect(
          r'''
      SELECT COUNT(*)::int AS total
        FROM agendamento
       WHERE id_aula = $1
         AND ''' +
              condicaoVagaOcupada() +
              r'''
    ''',
          variables: [Variable.withInt(idAula)],
          readsFrom: {_db.agendamento},
        )
        .getSingle();
    return linha.read<int>('total');
  }

  Future<AgendamentoData> inserir({
    required int idAluno,
    required int idAula,
    required PgDate dataAgendamento,
  }) {
    return _db
        .into(_db.agendamento)
        .insertReturning(
          AgendamentoCompanion.insert(
            idAluno: idAluno,
            idAula: idAula,
            dataAgendamento: dataAgendamento,
          ),
        );
  }

  /// Reagenda uma linha cancelada do mesmo aluno e aula: a constraint
  /// `uq_agendamento_aluno_aula` nao deixa uma segunda linha. O trigger de
  /// vagas roda no UPDATE de `status`.
  Future<AgendamentoData> reativar(
    int idAgendamento, {
    required PgDate dataAgendamento,
  }) async {
    final linhas =
        await (_db.update(
          _db.agendamento,
        )..where((t) => t.idAgendamento.equals(idAgendamento))).writeReturning(
          AgendamentoCompanion(
            status: const Value('agendado'),
            dataAgendamento: Value(dataAgendamento),
            dataCancelamento: const Value<PgDateTime?>(null),
          ),
        );
    return linhas.single;
  }

  Future<AgendamentoData> cancelar(
    int idAgendamento, {
    required DateTime agora,
  }) async {
    final linhas =
        await (_db.update(
          _db.agendamento,
        )..where((t) => t.idAgendamento.equals(idAgendamento))).writeReturning(
          AgendamentoCompanion(
            status: const Value('cancelado'),
            dataCancelamento: Value<PgDateTime?>(PgDateTime(agora)),
          ),
        );
    return linhas.single;
  }

  /// Cancela em lote os `agendado` da aula com o instante dado; `presente`,
  /// `faltou` e `cancelado` ficam como estao. Devolve quantos mudaram. Nao
  /// abre transacao: roda na de quem chama.
  Future<int> cancelarAgendadosDaAula(int idAula, {required DateTime agora}) {
    return (_db.update(_db.agendamento)
          ..where((t) => t.idAula.equals(idAula) & t.status.equals('agendado')))
        .write(
          AgendamentoCompanion(
            status: const Value('cancelado'),
            dataCancelamento: Value<PgDateTime?>(PgDateTime(agora)),
          ),
        );
  }

  /// Aula com `FOR UPDATE` e a regra de inicio, numa ida. Usar dentro de
  /// [transacao]. `null` quando a aula nao existe.
  Future<AulaChamada?> travarAulaParaChamada(int idAula) async {
    final linha = await _db
        .customSelect(
          r'''
      SELECT au.*,
             (clock_timestamp() < ((au.data + au.hora_inicio)
                AT TIME ZONE 'America/Sao_Paulo')) AS chamada_antes_inicio
        FROM aula au
       WHERE au.id_aula = $1
         FOR UPDATE OF au
    ''',
          variables: [Variable.withInt(idAula)],
          readsFrom: {_db.aula},
        )
        .getSingleOrNull();
    if (linha == null) return null;
    return AulaChamada(
      aula: _db.aula.map(linha.data),
      antesDoInicio: linha.read<bool>('chamada_antes_inicio'),
    );
  }

  /// Todos os agendamentos da aula, qualquer status, com `FOR UPDATE`. Usar
  /// dentro de [transacao].
  Future<List<AgendamentoData>> travarAgendamentosDaAula(int idAula) async {
    final linhas = await _db
        .customSelect(
          r'SELECT * FROM agendamento WHERE id_aula = $1 '
          r'ORDER BY id_agendamento FOR UPDATE',
          variables: [Variable.withInt(idAula)],
          readsFrom: {_db.agendamento},
        )
        .get();
    return [for (final linha in linhas) _db.agendamento.map(linha.data)];
  }

  /// Grava a presenca em lote: `presente` com [agora] em `data_presenca`;
  /// `faltou` com `data_presenca` nula. Devolve as linhas alteradas. Nao
  /// abre transacao: roda na de quem chama.
  Future<List<AgendamentoData>> gravarPresenca({
    required List<int> presentes,
    required List<int> faltaram,
    required DateTime agora,
  }) async {
    final gravadas = <AgendamentoData>[];
    if (presentes.isNotEmpty) {
      gravadas.addAll(
        await (_db.update(
          _db.agendamento,
        )..where((t) => t.idAgendamento.isIn(presentes))).writeReturning(
          AgendamentoCompanion(
            status: const Value('presente'),
            dataPresenca: Value<PgDateTime?>(PgDateTime(agora)),
          ),
        ),
      );
    }
    if (faltaram.isNotEmpty) {
      gravadas.addAll(
        await (_db.update(
          _db.agendamento,
        )..where((t) => t.idAgendamento.isIn(faltaram))).writeReturning(
          AgendamentoCompanion(
            status: const Value('faltou'),
            dataPresenca: const Value<PgDateTime?>(null),
          ),
        ),
      );
    }
    return gravadas;
  }

  /// Ordem por id, com desempate estavel para paginacao.
  Future<List<AgendamentoData>> listarDoAluno({
    required int idAluno,
    required int limit,
    required int offset,
  }) {
    return (_db.select(_db.agendamento)
          ..where((t) => t.idAluno.equals(idAluno))
          ..orderBy([(t) => OrderingTerm.asc(t.idAgendamento)])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<int> contarDoAluno(int idAluno) async {
    final total = _db.agendamento.idAgendamento.count();
    final consulta = _db.selectOnly(_db.agendamento)
      ..addColumns([total])
      ..where(_db.agendamento.idAluno.equals(idAluno));
    return (await consulta.getSingle()).read(total)!;
  }
}
