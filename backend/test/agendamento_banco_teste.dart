import 'package:drift/drift.dart' show Variable;
import 'package:grazifit_backend/database/database.dart';

/// Helpers dos testes contra Postgres real (D66). Exigem `DATABASE_URL`
/// apontando para um banco com o schema de `database/schema/`.
///
/// Cada arquivo de teste usa uma `tag` propria: e-mails `*.<tag>@agend.test`
/// e faixa de CPF separada. Assim dois arquivos podem rodar em paralelo no
/// mesmo banco sem apagar dados um do outro. Valores sao controlados pelo
/// proprio teste: SQL literal, sem entrada externa.

/// CPF com digitos verificadores validos a partir de 9 digitos.
String cpfValido(int base) {
  final lista = base
      .toString()
      .padLeft(9, '0')
      .split('')
      .map(int.parse)
      .toList();
  final d1 = _dv(lista);
  final d2 = _dv([...lista, d1]);
  return [...lista, d1, d2].join();
}

int _dv(List<int> ds) {
  var soma = 0;
  for (var i = 0; i < ds.length; i++) {
    soma += ds[i] * (ds.length + 1 - i);
  }
  final resto = (soma * 10) % 11;
  return resto == 10 ? 0 : resto;
}

Future<void> limparDadosDeTeste(GraziDatabase db, String tag) async {
  final sufixo = '.$tag@agend.test';
  await db.customStatement('''
    DELETE FROM agendamento WHERE id_aula IN (
      SELECT au.id_aula FROM aula au
        JOIN professor p ON p.id_professor = au.id_professor
       WHERE p.email LIKE '%$sufixo')''');
  await db.customStatement('''
    DELETE FROM agendamento WHERE id_aluno IN (
      SELECT id_aluno FROM aluno WHERE email LIKE '%$sufixo')''');
  await db.customStatement('''
    DELETE FROM aula WHERE id_professor IN (
      SELECT id_professor FROM professor WHERE email LIKE '%$sufixo')''');
  await db.customStatement("DELETE FROM aluno WHERE email LIKE '%$sufixo'");
  await db.customStatement("DELETE FROM professor WHERE email LIKE '%$sufixo'");
}

Future<int> inserirProfessor(
  GraziDatabase db, {
  required String tag,
  required int cpfBase,
}) async {
  final linha = await db.customSelect('''
        INSERT INTO professor (cpf, senha_hash, nome, telefone, email)
        VALUES ('${cpfValido(cpfBase)}', 'hash', 'Professor $tag',
                '11999990000', 'professor.$tag@agend.test')
        RETURNING id_professor AS id''').getSingle();
  return linha.read<int>('id');
}

Future<int> inserirAluno(
  GraziDatabase db, {
  required String tag,
  required int indice,
  required int cpfBase,
}) async {
  final linha = await db.customSelect('''
        INSERT INTO aluno (cpf, senha_hash, nome, data_nascimento, telefone, email)
        VALUES ('${cpfValido(cpfBase)}', 'hash', 'Aluno $indice',
                '2000-01-01', '11999991111', 'aluno.$indice.$tag@agend.test')
        RETURNING id_aluno AS id''').getSingle();
  return linha.read<int>('id');
}

/// Insere aula direto no banco (sem service), para montar cenarios.
Future<int> inserirAula(
  GraziDatabase db, {
  required int idProfessor,
  required String dataIso,
  required String horaInicio,
  required String horaFim,
  int vagas = 10,
  bool ativa = true,
}) async {
  final linha = await db.customSelect('''
        INSERT INTO aula (id_professor, data, hora_inicio, hora_fim, tipo,
                          categoria, vagas_maxima, status)
        VALUES ($idProfessor, '$dataIso', '$horaInicio', '$horaFim',
                'coletiva', 'pilates', $vagas, ${ativa ? 'TRUE' : 'FALSE'})
        RETURNING id_aula AS id''').getSingle();
  return linha.read<int>('id');
}

/// Contagem de linhas em `agendamento` para uma aula, sem filtro de status.
Future<int> contarLinhas(GraziDatabase db, int idAula) async {
  final linha = await db
      .customSelect(
        'SELECT COUNT(*)::int AS total FROM agendamento WHERE id_aula = $idAula',
      )
      .getSingle();
  return linha.read<int>('total');
}

/// Data ISO (AAAA-MM-DD) de hoje em Brasilia + [dias], calculada pelo banco.
/// As regras de tempo leem o relogio do banco, e a vigencia aceita so o ano
/// corrente e o seguinte: por isso as aulas de teste usam datas relativas.
Future<String> dataRelativaIso(GraziDatabase db, int dias) async {
  final linha = await db
      .customSelect(
        r"SELECT ((now() AT TIME ZONE 'America/Sao_Paulo')::date"
        r' + $1::int)::text AS d',
        variables: [Variable.withInt(dias)],
      )
      .getSingle();
  return linha.read<String>('d');
}

/// Aula cujo inicio e "agora de Brasilia + [minutos]", montada no SQL. Fim
/// 1 minuto depois, ou 23:59:59 se cruzar a meia-noite.
Future<int> inserirAulaEmMinutos(
  GraziDatabase db, {
  required int idProfessor,
  required int minutos,
}) async {
  final linha = await db
      .customSelect(
        r"""
        WITH t AS (
          SELECT (now() AT TIME ZONE 'America/Sao_Paulo')
                 + make_interval(mins => $2::int) AS ts)
        INSERT INTO aula (id_professor, data, hora_inicio, hora_fim, tipo,
                          categoria, vagas_maxima, status)
        SELECT $1::int, ts::date, ts::time,
               CASE WHEN (ts + INTERVAL '1 minute')::date = ts::date
                    THEN (ts + INTERVAL '1 minute')::time
                    ELSE TIME '23:59:59.999999' END,
               'coletiva', 'pilates', 10, TRUE
          FROM t
        RETURNING id_aula AS id""",
        variables: [Variable.withInt(idProfessor), Variable.withInt(minutos)],
      )
      .getSingle();
  return linha.read<int>('id');
}
