@Timeout(Duration(minutes: 2))
library;

import 'package:drift_postgres/drift_postgres.dart' show PgDate, PgDateTime;
import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/agendamentos/agendamento_repository.dart';
import 'package:grazifit_backend/features/agendamentos/agendamento_service.dart';
import 'package:grazifit_backend/features/aulas/aula_repository.dart';
import 'package:grazifit_backend/features/aulas/aula_service.dart';
import 'package:grazifit_backend/shared/autorizacao/identidade.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';

import 'agendamento_banco_teste.dart' show cpfValido;

/// Requer `DATABASE_URL` apontando para o Postgres de desenvolvimento.
void main() {
  late GraziDatabase db;
  late AulaRepository repository;

  /// Cascata real, no mesmo `db` do [repository] (como em `bin/server.dart`).
  late AgendamentoService agendamentoService;
  late int idAdmin;
  late int idProfessor;
  late int idAluno;

  /// Alunos extras para a cascata (um agendamento por aluno e aula).
  late List<int> outrosAlunos;

  const emailAdmin = 'aula.repo.admin@aulas.test';
  const emailProfessor = 'aula.repo.professor@aulas.test';
  const emailAluno = 'aula.repo.aluno@aulas.test';
  const padraoOutrosAlunos = 'aula.repo.aluno.%@aulas.test';

  final dia1 = PgDate(year: 2099, month: 1, day: 10);
  final dia2 = PgDate(year: 2099, month: 1, day: 11);

  Future<void> limpar() async {
    await db.customStatement('''
      DELETE FROM agendamento WHERE id_aluno IN
        (SELECT id_aluno FROM aluno WHERE email = '$emailAluno'
                                       OR email LIKE '$padraoOutrosAlunos')''');
    await db.customStatement(
      '''
      DELETE FROM aula WHERE id_professor IN
        (SELECT id_professor FROM professor WHERE email = '$emailProfessor')''',
    );
    await db.customStatement("DELETE FROM aluno WHERE email = '$emailAluno'");
    await db.customStatement(
      "DELETE FROM aluno WHERE email LIKE '$padraoOutrosAlunos'",
    );
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
    agendamentoService = AgendamentoService(AgendamentoRepository(db));
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
    outrosAlunos = [
      for (var i = 1; i <= 3; i++)
        await inserirId('''
          INSERT INTO aluno (cpf, senha_hash, nome, data_nascimento, telefone,
                             email)
          VALUES ('${cpfValido(820000000 + i)}', 'hash', 'Aluno Aula $i',
                  '2000-01-01', '11999991111', 'aula.repo.aluno.$i@aulas.test')
          RETURNING id_aluno AS id'''),
    ];
  });

  tearDown(() async {
    await db.customStatement('''
      DELETE FROM agendamento WHERE id_aluno = $idAluno''');
    await db.customStatement('''
      DELETE FROM agendamento WHERE id_aula IN
        (SELECT id_aula FROM aula WHERE id_professor = $idProfessor)''');
    await db.customStatement(
      'DELETE FROM aula WHERE id_professor = $idProfessor',
    );
  });

  tearDownAll(() async {
    await limpar();
    await db.close();
  });

  /// Cancela pelo service, com repositories reais, como admin.
  Future<AulaData> cancelarPeloService(
    int idAula,
    DateTime instante, {
    CancelamentoDeAgendamentos? cascata,
  }) =>
      AulaService(
        repository,
        cascata ?? agendamentoService,
        agora: () => instante,
      ).cancelar(
        identidade: Identidade(id: idAdmin, papel: Papel.admin),
        idAula: idAula,
      );

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

  group('cancelamento', () {
    // Precisao de microssegundo, igual ao TIMESTAMPTZ.
    final instante = DateTime.utc(2099, 1, 5, 13, 45, 7, 123, 456);

    Future<Map<String, Object?>> lerAula(int idAula) async {
      final linha = await db.customSelect('''
        SELECT status, id_admin_cancelou, id_professor_cancelou,
               data_cancelamento
          FROM aula WHERE id_aula = $idAula''').getSingle();
      return linha.data;
    }

    Future<Map<int, Map<String, Object?>>> lerAgendamentos(int idAula) async {
      final linhas = await db.customSelect('''
        SELECT id_aluno, status, data_presenca, data_cancelamento
          FROM agendamento WHERE id_aula = $idAula''').get();
      return {for (final l in linhas) l.read<int>('id_aluno'): l.data};
    }

    Future<void> agendar(int idAula, int aluno, String status) =>
        db.customStatement(
          '''
          INSERT INTO agendamento (id_aluno, id_aula, status, data_presenca,
                                   data_cancelamento)
          VALUES ($aluno, $idAula, '$status',
                  ${status == 'presente' ? "'2099-01-04T10:00:00Z'" : 'NULL'},
                  ${status == 'cancelado' ? "'2099-01-03T10:00:00Z'" : 'NULL'})''',
        );

    DateTime? utc(Object? valor) => switch (valor) {
      final DateTime d => d.toUtc(),
      final PgDateTime d => d.dateTime.toUtc(),
      _ => null,
    };

    test(
      'admin: status false, id_admin_cancelou e data; XOR respeitado',
      () async {
        final aula = await criarAula();
        final cancelada = await repository.transacao(
          () => repository.cancelar(
            aula.idAula,
            agora: instante,
            idAdminCancelou: idAdmin,
          ),
        );

        expect(cancelada.status, isFalse);
        expect(cancelada.idAdminCancelou, idAdmin);
        expect(cancelada.idProfessorCancelou, isNull);
        expect(cancelada.dataCancelamento!.dateTime.toUtc(), instante);

        final lida = await lerAula(aula.idAula);
        expect(lida['status'], isFalse);
        expect(lida['id_admin_cancelou'], idAdmin);
        expect(lida['id_professor_cancelou'], isNull);
        expect(utc(lida['data_cancelamento']), instante);
      },
    );

    test(
      'professor: grava id_professor_cancelou e deixa o admin nulo',
      () async {
        final aula = await criarAula();
        await repository.transacao(
          () => repository.cancelar(
            aula.idAula,
            agora: instante,
            idProfessorCancelou: idProfessor,
          ),
        );

        final lida = await lerAula(aula.idAula);
        expect(lida['status'], isFalse);
        expect(lida['id_professor_cancelou'], idProfessor);
        expect(lida['id_admin_cancelou'], isNull);
        expect(utc(lida['data_cancelamento']), instante);
      },
    );

    test('ck_aula_cancelamento recusa cancelamento sem responsavel ou com '
        'dois', () async {
      final aula = await criarAula();
      Matcher violaXor() => throwsA(
        isA<pg.ServerException>()
            .having((e) => e.code, 'code', '23514')
            .having(
              (e) => e.constraintName,
              'constraint',
              'ck_aula_cancelamento',
            ),
      );

      await expectLater(
        repository.cancelar(aula.idAula, agora: instante),
        violaXor(),
      );
      await expectLater(
        repository.cancelar(
          aula.idAula,
          agora: instante,
          idAdminCancelou: idAdmin,
          idProfessorCancelou: idProfessor,
        ),
        violaXor(),
      );
      expect((await lerAula(aula.idAula))['status'], isTrue);
    });

    test(
      'fluxo completo pelo service: aula cancelada e, pela cascata do '
      'agendamento, so agendado vira cancelado com o mesmo instante',
      () async {
        final aula = await criarAula();
        final id = aula.idAula;
        final [presente, faltou, jaCancelado] = outrosAlunos;
        await agendar(id, idAluno, 'agendado');
        await agendar(id, presente, 'presente');
        await agendar(id, faltou, 'faltou');
        await agendar(id, jaCancelado, 'cancelado');
        final antes = await lerAgendamentos(id);

        final cancelada = await cancelarPeloService(id, instante);
        expect(cancelada.status, isFalse);
        expect(cancelada.idAdminCancelou, idAdmin);
        expect((await lerAula(id))['status'], isFalse);

        final depois = await lerAgendamentos(id);
        expect(depois[idAluno]!['status'], 'cancelado');
        expect(utc(depois[idAluno]!['data_cancelamento']), instante);
        expect(
          utc(depois[idAluno]!['data_cancelamento']),
          utc((await lerAula(id))['data_cancelamento']),
        );
        for (final aluno in [presente, faltou, jaCancelado]) {
          expect(depois[aluno], antes[aluno], reason: 'aluno $aluno mudou');
        }

        // Nenhuma linha cancelada sem data (ck_agendamento_cancelamento).
        final semData = await db.customSelect('''
        SELECT COUNT(*)::int AS total FROM agendamento
         WHERE id_aula = $id AND status = 'cancelado'
           AND data_cancelamento IS NULL''').getSingle();
        expect(semData.read<int>('total'), 0);
      },
    );

    test('falha depois da cascata desfaz aula e agendamentos juntos: a '
        'escrita do agendamento roda na transacao da aula', () async {
      final aula = await criarAula();
      await agendar(aula.idAula, idAluno, 'agendado');
      final cascata = _CascataQueFalha(agendamentoService);

      await expectLater(
        cancelarPeloService(aula.idAula, instante, cascata: cascata),
        throwsA(isA<StateError>()),
      );
      // A cascata chegou a gravar antes da falha.
      expect(cascata.alterados, 1);

      final lida = await lerAula(aula.idAula);
      expect(lida['status'], isTrue);
      expect(lida['data_cancelamento'], isNull);
      final agendamentos = await lerAgendamentos(aula.idAula);
      expect(agendamentos[idAluno]!['status'], 'agendado');
      expect(agendamentos[idAluno]!['data_cancelamento'], isNull);
    });
  });

  group('agendados e ocupacao', () {
    Future<int> agendar(int idAula, int aluno, String status) async {
      final linha = await db.customSelect('''
        INSERT INTO agendamento (id_aluno, id_aula, status, data_presenca,
                                 data_cancelamento)
        VALUES ($aluno, $idAula, '$status',
                ${status == 'presente' ? "'2099-01-04T10:00:00Z'" : 'NULL'},
                ${status == 'cancelado' ? "'2099-01-03T10:00:00Z'" : 'NULL'})
        RETURNING id_agendamento AS id''').getSingle();
      return linha.read<int>('id');
    }

    test('listarAgendados: JOIN com o nome, sem cancelados, ordem por nome '
        'e paginacao', () async {
      final aula = await criarAula();
      final id = aula.idAula;
      final [a1, a2, a3] = outrosAlunos;
      // Inseridos fora da ordem de nome, para a ordem nao vir do id.
      final agA3 = await agendar(id, a3, 'faltou');
      final agA2 = await agendar(id, a2, 'cancelado');
      final agA1 = await agendar(id, a1, 'presente');
      final agBase = await agendar(id, idAluno, 'agendado');

      final lista = await repository.listarAgendados(id, limit: 10, offset: 0);
      expect(
        lista.map((a) => (a.idAgendamento, a.idAluno, a.nomeAluno, a.status)),
        [
          (agBase, idAluno, 'Aluno Aula', 'agendado'),
          (agA1, a1, 'Aluno Aula 1', 'presente'),
          (agA3, a3, 'Aluno Aula 3', 'faltou'),
        ],
      );
      expect(lista.map((a) => a.idAgendamento), isNot(contains(agA2)));
      expect(await repository.contarAgendados(id), 3);

      final pagina = await repository.listarAgendados(id, limit: 1, offset: 1);
      expect(pagina.single.idAgendamento, agA1);

      // Aula cancelada: a cascata deixa so presente e faltou.
      await cancelarPeloService(id, DateTime.utc(2099, 1, 5));
      final daCancelada = await repository.listarAgendados(
        id,
        limit: 10,
        offset: 0,
      );
      expect(daCancelada.map((a) => a.status), ['presente', 'faltou']);
      expect(await repository.contarAgendados(id), 2);

      expect(
        await repository.listarAgendados(-1, limit: 10, offset: 0),
        isEmpty,
      );
    });

    test('listarAgendados: nome igual desempata por id_agendamento', () async {
      final [a1, a2, _] = outrosAlunos;
      await db.customStatement(
        "UPDATE aluno SET nome = 'Aluno Aula 1' WHERE id_aluno = $a2",
      );
      addTearDown(
        () => db.customStatement(
          "UPDATE aluno SET nome = 'Aluno Aula 2' WHERE id_aluno = $a2",
        ),
      );
      final aula = await criarAula();
      final primeiro = await agendar(aula.idAula, a2, 'agendado');
      final segundo = await agendar(aula.idAula, a1, 'agendado');

      final lista = await repository.listarAgendados(
        aula.idAula,
        limit: 10,
        offset: 0,
      );
      expect(lista.map((a) => a.idAgendamento), [primeiro, segundo]);
    });

    test(
      'contarOcupadasPorAula bate com vw_aula_ocupacao (status mistos)',
      () async {
        final mista = await criarAula(inicio: pg.Time(7));
        final vazia = await criarAula(inicio: pg.Time(8));
        final soAgendado = await criarAula(inicio: pg.Time(9));
        final [a1, a2, a3] = outrosAlunos;
        await agendar(mista.idAula, idAluno, 'agendado');
        await agendar(mista.idAula, a1, 'presente');
        await agendar(mista.idAula, a2, 'faltou');
        await agendar(mista.idAula, a3, 'cancelado');
        await agendar(soAgendado.idAula, idAluno, 'agendado');

        final ids = [mista.idAula, vazia.idAula, soAgendado.idAula];
        final contagem = await repository.contarOcupadasPorAula(ids);
        expect(contagem, {mista.idAula: 2, soAgendado.idAula: 1});

        final view = {
          for (final l in await db.customSelect('''
          SELECT id_aula, vagas_ocupadas::int AS ocupadas,
                 vagas_livres::int AS livres
            FROM vw_aula_ocupacao
           WHERE id_aula IN (${ids.join(', ')})''').get())
            l.read<int>('id_aula'): (
              l.read<int>('ocupadas'),
              l.read<int>('livres'),
            ),
        };
        expect(view.keys.toSet(), ids.toSet());
        for (final aula in [mista, vazia, soAgendado]) {
          final ocupadas = contagem[aula.idAula] ?? 0;
          expect(view[aula.idAula], (
            ocupadas,
            aula.vagasMaxima - ocupadas,
          ), reason: 'aula ${aula.idAula}');
          expect(
            await repository.contarAgendamentosAtivos(aula.idAula),
            ocupadas,
          );
        }

        expect(await repository.contarOcupadasPorAula([]), isEmpty);
      },
    );
  });
}

/// Chama a cascata real e falha logo depois, ainda dentro da transacao.
class _CascataQueFalha implements CancelamentoDeAgendamentos {
  final CancelamentoDeAgendamentos real;
  int? alterados;

  _CascataQueFalha(this.real);

  @override
  Future<int> cancelarEmCascata(int idAula, {required DateTime agora}) async {
    alterados = await real.cancelarEmCascata(idAula, agora: agora);
    throw StateError('falha simulada');
  }
}
