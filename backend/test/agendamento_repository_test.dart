@Timeout(Duration(minutes: 2))
library;

import 'package:drift_postgres/drift_postgres.dart' show PgDate, PgDateTime;
import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/agendamentos/agendamento_repository.dart';
import 'package:grazifit_backend/features/agendamentos/agendamento_service.dart';
import 'package:grazifit_backend/shared/autorizacao/identidade.dart';
import 'package:grazifit_backend/shared/erros/agendamento_exception.dart';
import 'package:grazifit_backend/shared/erros/aula_exception.dart';
import 'package:grazifit_backend/shared/erros/tradutor_erro_banco.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:shared/erros/codigo_erro.dart';
import 'package:test/test.dart';

import 'agendamento_banco_teste.dart';

/// Requer `DATABASE_URL` apontando para Postgres com o schema de produção.
/// Sem a variavel, falha.
void main() {
  const tag = 'repo';

  late GraziDatabase db;
  late AgendamentoRepository repo;
  late AgendamentoService service;
  late int idProfessor;
  late int idAluno1;
  late int idAluno2;
  late int idAluno3;
  late int idAluno4;

  final agora = DateTime(2099, 1, 1, 6);
  final hoje = PgDate(year: 2099, month: 1, day: 1);

  setUpAll(() async {
    db = GraziDatabase.doAmbiente();
    repo = AgendamentoRepository(db);
    service = AgendamentoService(repo, agora: () => agora);
    await limparDadosDeTeste(db, tag);
    idProfessor = await inserirProfessor(db, tag: tag, cpfBase: 700000021);
    idAluno1 = await inserirAluno(db, tag: tag, indice: 1, cpfBase: 210000001);
    idAluno2 = await inserirAluno(db, tag: tag, indice: 2, cpfBase: 210000002);
    idAluno3 = await inserirAluno(db, tag: tag, indice: 3, cpfBase: 210000003);
    idAluno4 = await inserirAluno(db, tag: tag, indice: 4, cpfBase: 210000004);
  });

  tearDownAll(() async {
    await limparDadosDeTeste(db, tag);
    await db.close();
  });

  Identidade alunoId(int id) => Identidade(id: id, papel: Papel.aluno);

  Future<int> vagasLivres(int idAula) async {
    final linha = await db
        .customSelect(
          'SELECT vagas_livres::int AS livres FROM vw_aula_ocupacao '
          'WHERE id_aula = $idAula',
        )
        .getSingle();
    return linha.read<int>('livres');
  }

  test(
    'reserva e cancela: data_cancelamento gravada e vaga volta na view (CA-7)',
    () async {
      final idAula = await inserirAula(
        db,
        idProfessor: idProfessor,
        dataIso: await dataRelativaIso(db, 10),
        horaInicio: '10:00',
        horaFim: '11:00',
        vagas: 1,
      );

      final reserva = await service.reservar(
        identidade: alunoId(idAluno1),
        idAula: idAula,
      );
      expect(await vagasLivres(idAula), 0);

      final cancelado = await service.cancelar(
        identidade: alunoId(idAluno1),
        idAgendamento: reserva.idAgendamento,
      );
      expect(cancelado.status, 'cancelado');
      expect(cancelado.dataCancelamento?.toDateTime().toUtc(), agora.toUtc());

      final linha = await db
          .customSelect(
            'SELECT status, data_cancelamento IS NOT NULL AS preenchida '
            'FROM agendamento WHERE id_agendamento = ${reserva.idAgendamento}',
          )
          .getSingle();
      expect(linha.read<String>('status'), 'cancelado');
      expect(linha.read<bool>('preenchida'), isTrue);
      expect(await vagasLivres(idAula), 1);
    },
  );

  test(
    'reagendar a mesma aula reativa a linha: uma linha so, trigger no UPDATE',
    () async {
      final idAula = await inserirAula(
        db,
        idProfessor: idProfessor,
        dataIso: await dataRelativaIso(db, 11),
        horaInicio: '10:00',
        horaFim: '11:00',
        vagas: 5,
      );

      final primeira = await service.reservar(
        identidade: alunoId(idAluno1),
        idAula: idAula,
      );
      await service.cancelar(
        identidade: alunoId(idAluno1),
        idAgendamento: primeira.idAgendamento,
      );
      final segunda = await service.reservar(
        identidade: alunoId(idAluno1),
        idAula: idAula,
      );

      expect(segunda.idAgendamento, primeira.idAgendamento);
      expect(segunda.status, 'agendado');
      expect(await contarLinhas(db, idAula), 1);

      final linha = await db
          .customSelect(
            'SELECT data_cancelamento IS NULL AS limpo FROM agendamento '
            'WHERE id_agendamento = ${segunda.idAgendamento}',
          )
          .getSingle();
      expect(linha.read<bool>('limpo'), isTrue);
    },
  );

  test('duplicidade no banco: uq_agendamento_aluno_aula vira AGENDAMENTO_DUPLICADO', () async {
    final idAula = await inserirAula(
      db,
      idProfessor: idProfessor,
      dataIso: '2099-01-12',
      horaInicio: '10:00',
      horaFim: '11:00',
      vagas: 5,
    );
    await repo.inserir(
      idAluno: idAluno1,
      idAula: idAula,
      dataAgendamento: hoje,
    );

    final erro = await repo
        .inserir(idAluno: idAluno1, idAula: idAula, dataAgendamento: hoje)
        .then<pg.ServerException?>((_) => null)
        .catchError((Object e) => e as pg.ServerException);

    expect(erro, isNotNull);
    expect(erro!.constraintName, 'uq_agendamento_aluno_aula');
    expect(traduzirErroBanco(erro), CodigoErro.agendamentoDuplicado);
  });

  test(
    'trigger GF001 sem vagas vira AULA_SEM_VAGAS (SQLSTATE do banco)',
    () async {
      final idAula = await inserirAula(
        db,
        idProfessor: idProfessor,
        dataIso: '2099-01-13',
        horaInicio: '10:00',
        horaFim: '11:00',
        vagas: 1,
      );
      await repo.inserir(
        idAluno: idAluno1,
        idAula: idAula,
        dataAgendamento: hoje,
      );

      final erro = await repo
          .inserir(idAluno: idAluno2, idAula: idAula, dataAgendamento: hoje)
          .then<pg.ServerException?>((_) => null)
          .catchError((Object e) => e as pg.ServerException);

      expect(erro, isNotNull);
      expect(erro!.code, 'GF001');
      expect(traduzirErroBanco(erro), CodigoErro.aulaSemVagas);
    },
  );

  test('trigger GF002 em aula inativa vira AULA_INATIVA', () async {
    final idAula = await inserirAula(
      db,
      idProfessor: idProfessor,
      dataIso: '2099-01-14',
      horaInicio: '10:00',
      horaFim: '11:00',
      ativa: false,
    );

    final erro = await repo
        .inserir(idAluno: idAluno1, idAula: idAula, dataAgendamento: hoje)
        .then<pg.ServerException?>((_) => null)
        .catchError((Object e) => e as pg.ServerException);

    expect(erro, isNotNull);
    expect(erro!.code, 'GF002');
    expect(traduzirErroBanco(erro), CodigoErro.aulaInativa);
  });

  test('agendamento cancelado nao ocupa vaga para o trigger', () async {
    final idAula = await inserirAula(
      db,
      idProfessor: idProfessor,
      dataIso: '2099-01-15',
      horaInicio: '10:00',
      horaFim: '11:00',
      vagas: 1,
    );
    final primeiro = await repo.inserir(
      idAluno: idAluno1,
      idAula: idAula,
      dataAgendamento: hoje,
    );
    await repo.cancelar(primeiro.idAgendamento, agora: agora);

    final segundo = await repo.inserir(
      idAluno: idAluno2,
      idAula: idAula,
      dataAgendamento: hoje,
    );
    expect(segundo.status, 'agendado');
    expect(await repo.contarAtivos(idAula), 1);
  });

  test('leitura do aluno: lista e total so dos proprios (CA-10)', () async {
    final idAula = await inserirAula(
      db,
      idProfessor: idProfessor,
      dataIso: await dataRelativaIso(db, 16),
      horaInicio: '10:00',
      horaFim: '11:00',
      vagas: 10,
    );
    await service.reservar(identidade: alunoId(idAluno1), idAula: idAula);
    await service.reservar(identidade: alunoId(idAluno2), idAula: idAula);

    final pagina = await service.listarDoAluno(
      alunoId(idAluno1),
      limit: 20,
      offset: 0,
    );
    expect(pagina.total, greaterThanOrEqualTo(1));
    expect(pagina.itens.every((a) => a.idAluno == idAluno1), isTrue);
  });

  test('cancelarAgendadosDaAula: so agendado da aula vira cancelado, com o '
      'instante dado', () async {
    // Precisao de microssegundo, igual ao TIMESTAMPTZ.
    final instante = DateTime.utc(2099, 1, 5, 13, 45, 7, 123, 456);
    final idAula = await inserirAula(
      db,
      idProfessor: idProfessor,
      dataIso: await dataRelativaIso(db, 12),
      horaInicio: '10:00',
      horaFim: '11:00',
    );
    final outraAula = await inserirAula(
      db,
      idProfessor: idProfessor,
      dataIso: await dataRelativaIso(db, 13),
      horaInicio: '10:00',
      horaFim: '11:00',
    );
    Future<void> agendar(int aula, int aluno, String status) =>
        db.customStatement(
          '''
          INSERT INTO agendamento (id_aluno, id_aula, status, data_presenca,
                                   data_cancelamento)
          VALUES ($aluno, $aula, '$status',
                  ${status == 'presente' ? "'2099-01-04T10:00:00Z'" : 'NULL'},
                  ${status == 'cancelado' ? "'2099-01-03T10:00:00Z'" : 'NULL'})''',
        );
    Future<Map<int, Map<String, Object?>>> ler(int aula) async => {
      for (final l in await db.customSelect('''
            SELECT id_aluno, status, data_presenca, data_cancelamento
              FROM agendamento WHERE id_aula = $aula''').get())
        l.read<int>('id_aluno'): l.data,
    };
    DateTime? utc(Object? valor) => switch (valor) {
      final DateTime d => d.toUtc(),
      final PgDateTime d => d.dateTime.toUtc(),
      _ => null,
    };

    await agendar(idAula, idAluno1, 'agendado');
    await agendar(idAula, idAluno2, 'presente');
    await agendar(idAula, idAluno3, 'faltou');
    await agendar(idAula, idAluno4, 'cancelado');
    await agendar(outraAula, idAluno1, 'agendado');
    final antes = await ler(idAula);
    final outraAntes = await ler(outraAula);

    final alterados = await repo.cancelarAgendadosDaAula(
      idAula,
      agora: instante,
    );

    expect(alterados, 1);
    final depois = await ler(idAula);
    expect(depois[idAluno1]!['status'], 'cancelado');
    expect(utc(depois[idAluno1]!['data_cancelamento']), instante);
    for (final aluno in [idAluno2, idAluno3, idAluno4]) {
      expect(depois[aluno], antes[aluno], reason: 'aluno $aluno mudou');
    }
    expect(await ler(outraAula), outraAntes);
    expect(
      await repo.cancelarAgendadosDaAula(idAula, agora: instante),
      0,
      reason: 'sem agendado restante',
    );
  });

  group('fuso: regras de tempo calculadas no Postgres', () {
    // Usam o relogio real do banco. As aulas saem do instante de Brasilia
    // dentro do SQL, nunca do relogio do host: o resultado nao depende do TZ
    // do processo.
    Matcher erroDe(CodigoErro codigo) => anyOf(
      isA<AgendamentoException>().having((e) => e.codigo, 'codigo', codigo),
      isA<AulaException>().having((e) => e.codigo, 'codigo', codigo),
    );

    String isoDe(PgDate d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    test('janela: 1h59 antes bloqueia; 2h01 antes permite', () async {
      final curta = await inserirAulaEmMinutos(
        db,
        idProfessor: idProfessor,
        minutos: 119,
      );
      await expectLater(
        service.reservar(identidade: alunoId(idAluno1), idAula: curta),
        throwsA(erroDe(CodigoErro.agendamentoForaDaJanela)),
      );

      final longa = await inserirAulaEmMinutos(
        db,
        idProfessor: idProfessor,
        minutos: 121,
      );
      final reserva = await service.reservar(
        identidade: alunoId(idAluno1),
        idAula: longa,
      );
      expect(reserva.status, 'agendado');
    });

    test('aula de ontem (dia civil de Brasilia): AULA_DATA_PASSADA', () async {
      final idAula = await inserirAula(
        db,
        idProfessor: idProfessor,
        dataIso: await dataRelativaIso(db, -1),
        horaInicio: '10:00',
        horaFim: '11:00',
      );
      await expectLater(
        service.reservar(identidade: alunoId(idAluno1), idAula: idAula),
        throwsA(erroDe(CodigoErro.aulaDataPassada)),
      );
    });

    test(
      'aula de hoje ja iniciada: FORA_DA_JANELA, nao DATA_PASSADA',
      () async {
        // Mesmo dia civil de Brasilia: 00:00 de hoje ja passou.
        final idAula = await inserirAula(
          db,
          idProfessor: idProfessor,
          dataIso: await dataRelativaIso(db, 0),
          horaInicio: '00:00',
          horaFim: '23:59',
        );
        await expectLater(
          service.reservar(identidade: alunoId(idAluno1), idAula: idAula),
          throwsA(erroDe(CodigoErro.agendamentoForaDaJanela)),
        );
      },
    );

    test('data_agendamento e o dia civil de Brasilia, lido do banco', () async {
      final idAula = await inserirAula(
        db,
        idProfessor: idProfessor,
        dataIso: await dataRelativaIso(db, 1),
        horaInicio: '23:00',
        horaFim: '23:30',
      );
      final reserva = await service.reservar(
        identidade: alunoId(idAluno1),
        idAula: idAula,
      );
      expect(isoDe(reserva.dataAgendamento), await dataRelativaIso(db, 0));
    });

    test('cancelamento: janela de 2h tambem vem do banco', () async {
      final idAula = await inserirAulaEmMinutos(
        db,
        idProfessor: idProfessor,
        minutos: 119,
      );
      // Insercao direta: o repositorio nao aplica regras de tempo.
      final ag = await repo.inserir(
        idAluno: idAluno1,
        idAula: idAula,
        dataAgendamento: hoje,
      );
      await expectLater(
        service.cancelar(
          identidade: alunoId(idAluno1),
          idAgendamento: ag.idAgendamento,
        ),
        throwsA(erroDe(CodigoErro.agendamentoForaDaJanela)),
      );
      final depois = await repo.buscarPorAlunoAula(idAluno1, idAula);
      expect(depois?.status, 'agendado');
    });
  });
}
