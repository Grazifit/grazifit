import '../../database/database.dart';

/// Aula do dia, pronta para o painel inicial.
class AulaDoDia {
  const AulaDoDia({
    required this.idAula,
    required this.horaInicio,
    required this.horaFim,
    required this.categoria,
    required this.tipo,
    required this.professor,
    required this.vagasOcupadas,
    required this.vagasMaximas,
  });

  final int idAula;

  /// `HH:MM`.
  final String horaInicio;

  /// `HH:MM`.
  final String horaFim;
  final String categoria;
  final String tipo;
  final String professor;
  final int vagasOcupadas;
  final int vagasMaximas;
}

/// Leitura composta do painel inicial. Nao possui tabela e nao escreve:
/// so le `vw_aula_ocupacao` e o status de alunos e professores.
class InicioRepository {
  InicioRepository(this._db);

  final GraziDatabase _db;

  /// Dia corrente em Brasilia, pelo relogio do proprio banco.
  static const _hojeBrasilia =
      "(clock_timestamp() AT TIME ZONE 'America/Sao_Paulo')::date";

  /// Data de hoje (`AAAA-MM-DD`, fuso de Brasilia).
  Future<String> dataDeHoje() async {
    final linha = await _db
        .customSelect("SELECT to_char($_hojeBrasilia, 'YYYY-MM-DD') AS d")
        .getSingle();
    return linha.read<String>('d');
  }

  /// Aulas ativas de hoje, da mais cedo para a mais tarde.
  Future<List<AulaDoDia>> aulasDeHoje() async {
    final linhas = await _db
        .customSelect(
          '''
      SELECT o.id_aula,
             to_char(au.hora_inicio, 'HH24:MI') AS hora_inicio,
             to_char(au.hora_fim, 'HH24:MI') AS hora_fim,
             au.categoria,
             au.tipo,
             p.nome AS professor,
             o.vagas_ocupadas::int AS vagas_ocupadas,
             o.vagas_maxima AS vagas_maxima
        FROM vw_aula_ocupacao o
        JOIN aula au ON au.id_aula = o.id_aula
        JOIN professor p ON p.id_professor = au.id_professor
       WHERE o.data = $_hojeBrasilia
       ORDER BY au.hora_inicio, o.id_aula
    ''',
          readsFrom: {_db.aula, _db.professor},
        )
        .get();
    return linhas
        .map(
          (l) => AulaDoDia(
            idAula: l.read<int>('id_aula'),
            horaInicio: l.read<String>('hora_inicio'),
            horaFim: l.read<String>('hora_fim'),
            categoria: l.read<String>('categoria'),
            tipo: l.read<String>('tipo'),
            professor: l.read<String>('professor'),
            vagasOcupadas: l.read<int>('vagas_ocupadas'),
            vagasMaximas: l.read<int>('vagas_maxima'),
          ),
        )
        .toList();
  }

  /// Alunos e professores com `status = FALSE`.
  Future<int> contarPessoasInativas() async {
    final linha = await _db
        .customSelect(
          '''
      SELECT (SELECT COUNT(*) FROM aluno WHERE status = FALSE)::int
           + (SELECT COUNT(*) FROM professor WHERE status = FALSE)::int AS total
    ''',
          readsFrom: {_db.aluno, _db.professor},
        )
        .getSingle();
    return linha.read<int>('total');
  }
}
