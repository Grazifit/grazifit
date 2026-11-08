@Timeout(Duration(minutes: 2))
library;

import 'package:drift_postgres/drift_postgres.dart' show PgDate;
import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/aulas/aula_repository.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';

/// Requer `DATABASE_URL` apontando para o Postgres de desenvolvimento.
void main() {
  late GraziDatabase db;
  late AulaRepository repository;
  late int idAdmin;
  late int idProfessor;
  late int idAluno;

  const emailAdmin = 'aula.repo.admin@aulas.test';
  const emailProfessor = 'aula.repo.professor@aulas.test';
  const emailAluno = 'aula.repo.aluno@aulas.test';

  final dia1 = PgDate(year: 2099, month: 1, day: 10);
  final dia2 = PgDate(year: 2099, month: 1, day: 11);

  Future<void> limpar() async {
    await db.customStatement('''
      DELETE FROM agendamento WHERE id_aluno IN
        (SELECT id_aluno FROM aluno WHERE email = '$emailAluno')''');
    await db.customStatement(
      '''
      DELETE FROM aula WHERE id_professor IN
        (SELECT id_professor FROM professor WHERE email = '$emailProfessor')''',
    );
    await db.customStatement("DELETE FROM aluno WHERE email = '$emailAluno'");
    await db.customStatement(
      "DELETE FROM professor WHERE email = '$emailProfessor'",
    );
    await db.customStatement("DELETE FROM admin WHERE email = '$emailAdmin'");
  }

  Future<int> inserirId(String sql) async =>
      (await db.customSelect(sql).getSingle()).read<int>('id');

  Future<AulaData> criarAula({
    PgDate? data,
    pg.Time? inicio,
    String tipo = 'coletiva',
    int vagas = 10,
  }) => repository.create(
    idAdminCriador: idAdmin,
    idProfessor: idProfessor,
    data: data ?? dia1,
    horaInicio: inicio ?? pg.Time(7),
    horaFim: pg.Time(23),
    tipo: tipo,
    categoria: 'pilates',
    vagasMaxima: vagas,
  );

  setUpAll(() async {
    db = GraziDatabase.doAmbiente();
    repository = AulaRepository(db);
    await limpar();

    idAdmin = await inserirId('''
      INSERT INTO admin (cpf, senha_hash, nome, email)
      VALUES ('11144477735', 'hash', 'Admin Aula', '$emailAdmin')
      RETURNING id_admin AS id''');
    idProfessor = await inserirId('''
      INSERT INTO professor (cpf, senha_hash, nome, telefone, email)
      VALUES ('39053344705', 'hash', 'Professor Aula', '11999990000',
              '$emailProfessor')
      RETURNING id_professor AS id''');
    idAluno = await inserirId('''
      INSERT INTO aluno (cpf, senha_hash, nome, data_nascimento, telefone, email)
      VALUES ('12345678909', 'hash', 'Aluno Aula', '2000-01-01',
              '11999991111', '$emailAluno')
      RETURNING id_aluno AS id''');
  });

  tearDown(() async {
    await db.customStatement('''
      DELETE FROM agendamento WHERE id_aluno = $idAluno''');
    await db.customStatement(
      'DELETE FROM aula WHERE id_professor = $idProfessor',
    );
  });

  tearDownAll(() async {
    await limpar();
    await db.close();
  });

  test('create e buscarPorId fazem ida e volta de DATE e TIME', () async {
    final criada = await repository.create(
      idAdminCriador: idAdmin,
      idProfessor: idProfessor,
      data: dia1,
      horaInicio: pg.Time(7, 5),
      horaFim: pg.Time(18, 30),
      tipo: 'individual',
      categoria: 'pilates',
      vagasMaxima: 3,
    );

    expect(criada.idAula, greaterThan(0));
    expect(criada.status, isTrue);
    expect(criada.idCronograma, isNull);
    expect(criada.idAdminCriador, idAdmin);

    final lida = await repository.buscarPorId(criada.idAula);
    expect(lida, isNotNull);
    expect(lida!.data, dia1);
    expect(lida.horaInicio, pg.Time(7, 5));
    expect(lida.horaFim, pg.Time(18, 30));
    expect(lida.tipo, 'individual');

    expect(await repository.buscarPorId(-1), isNull);
  });

  test(
    'atualizar altera so os campos enviados; id inexistente da null',
    () async {
      final criada = await criarAula();

      final atualizada = await repository.atualizar(
        criada.idAula,
        horaInicio: pg.Time(8),
        vagasMaxima: 15,
      );
      expect(atualizada!.horaInicio, pg.Time(8));
      expect(atualizada.vagasMaxima, 15);
      expect(atualizada.categoria, 'pilates');
      expect(atualizada.data, dia1);

      expect(await repository.atualizar(-1, vagasMaxima: 5), isNull);
    },
  );

  test(
    'listar ordena por data e hora, filtra e contar bate com o filtro',
    () async {
      final tarde = await criarAula(data: dia1, inicio: pg.Time(18));
      final outroDia = await criarAula(data: dia2, inicio: pg.Time(6));
      final manha = await criarAula(data: dia1, inicio: pg.Time(7));

      final todas = await repository.listar(
        limit: 10,
        offset: 0,
        idProfessor: idProfessor,
      );
      expect(todas.map((a) => a.idAula), [
        manha.idAula,
        tarde.idAula,
        outroDia.idAula,
      ]);
      expect(await repository.contar(idProfessor: idProfessor), 3);

      final doDia1 = await repository.listar(
        limit: 1,
        offset: 1,
        data: dia1,
        idProfessor: idProfessor,
      );
      expect(doDia1.single.idAula, tarde.idAula);
      expect(await repository.contar(data: dia1, idProfessor: idProfessor), 2);

      expect(
        await repository.contar(categoria: 'danca', idProfessor: idProfessor),
        0,
      );
    },
  );

  test(
    'uq_aula_professor_horario recusa o mesmo professor no mesmo horario',
    () async {
      await criarAula();
      await expectLater(
        criarAula(),
        throwsA(
          isA<pg.ServerException>()
              .having((e) => e.code, 'code', '23505')
              .having(
                (e) => e.constraintName,
                'constraint',
                'uq_aula_professor_horario',
              ),
        ),
      );
    },
  );

  test(
    'ck_aula_personal_vagas recusa aula individual com mais de 3 vagas',
    () async {
      await expectLater(
        criarAula(tipo: 'individual', vagas: 4),
        throwsA(
          isA<pg.ServerException>()
              .having((e) => e.code, 'code', '23514')
              .having(
                (e) => e.constraintName,
                'constraint',
                'ck_aula_personal_vagas',
              ),
        ),
      );
    },
  );

  test('contarAgendamentosAtivos ignora cancelado e faltou', () async {
    final aula = await criarAula();
    expect(await repository.contarAgendamentosAtivos(aula.idAula), 0);

    await db.customStatement('''
      INSERT INTO agendamento (id_aluno, id_aula)
      VALUES ($idAluno, ${aula.idAula})''');
    expect(await repository.contarAgendamentosAtivos(aula.idAula), 1);

    await db.customStatement('''
      UPDATE agendamento
         SET status = 'cancelado', data_cancelamento = now()
       WHERE id_aula = ${aula.idAula}''');
    expect(await repository.contarAgendamentosAtivos(aula.idAula), 0);
  });

  test('professorAtivoExiste recusa inexistente e inativo', () async {
    expect(await repository.professorAtivoExiste(idProfessor), isTrue);
    expect(await repository.professorAtivoExiste(-1), isFalse);

    await db.customStatement(
      'UPDATE professor SET status = FALSE WHERE id_professor = $idProfessor',
    );
    expect(await repository.professorAtivoExiste(idProfessor), isFalse);
    await db.customStatement(
      'UPDATE professor SET status = TRUE WHERE id_professor = $idProfessor',
    );
  });

  test('buscarParaAtualizar le a aula dentro da transacao', () async {
    final criada = await criarAula(inicio: pg.Time(9, 15));

    final lida = await repository.transacao(
      () => repository.buscarParaAtualizar(criada.idAula),
    );
    expect(lida!.idAula, criada.idAula);
    expect(lida.horaInicio, pg.Time(9, 15));
    expect(lida.data, dia1);

    expect(
      await repository.transacao(() => repository.buscarParaAtualizar(-1)),
      isNull,
    );
  });
}
