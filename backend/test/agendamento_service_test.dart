import 'package:drift_postgres/drift_postgres.dart' show PgDate, PgDateTime;
import 'package:grazifit_backend/database/database.dart' show AgendamentoData;
import 'package:grazifit_backend/features/agendamentos/agendamento_service.dart';
import 'package:grazifit_backend/shared/autorizacao/identidade.dart';
import 'package:grazifit_backend/shared/erros/agendamento_exception.dart';
import 'package:grazifit_backend/shared/erros/aula_exception.dart';
import 'package:shared/erros/codigo_erro.dart';
import 'package:test/test.dart';

import 'agendamento_fakes.dart';

Matcher erroDe(CodigoErro codigo) => anyOf(
  isA<AgendamentoException>().having((e) => e.codigo, 'codigo', codigo),
  isA<AulaException>().having((e) => e.codigo, 'codigo', codigo),
);

void main() {
  late RepositorioAgendamentoFalso repo;
  late AgendamentoService service;

  setUp(() {
    repo = RepositorioAgendamentoFalso();
    service = AgendamentoService(repo, agora: () => agoraFixo);
    repo.aula = aulaDe();
  });

  group('reservar (CA-1, CA-2, CA-8, CA-9)', () {
    test('aluno reserva aula ativa: linha criada com data de hoje', () async {
      final a = await service.reservar(identidade: aluno, idAula: 1);
      expect(a.idAluno, 5);
      expect(a.idAula, 1);
      expect(a.status, 'agendado');
      expect(a.dataAgendamento, PgDate(year: 2026, month: 6, day: 10));
      expect(a.dataCancelamento, isNull);
      expect(repo.agendamentos, hasLength(1));
    });

    test('professor e admin nao criam: AcessoNegado', () async {
      await expectLater(
        service.reservar(identidade: professor, idAula: 1),
        throwsA(isA<AcessoNegado>()),
      );
      await expectLater(
        service.reservar(identidade: admin, idAula: 1),
        throwsA(isA<AcessoNegado>()),
      );
      expect(repo.agendamentos, isEmpty);
    });

    test('aula inexistente: 404 REGISTRO_NAO_ENCONTRADO', () async {
      await expectLater(
        service.reservar(identidade: aluno, idAula: 99),
        throwsA(erroDe(CodigoErro.registroNaoEncontrado)),
      );
    });

    test('aula inativa: AULA_INATIVA', () async {
      repo.aula = aulaDe(status: false);
      await expectLater(
        service.reservar(identidade: aluno, idAula: 1),
        throwsA(erroDe(CodigoErro.aulaInativa)),
      );
    });

    test('aula com data anterior a hoje: AULA_DATA_PASSADA (CA-8)', () async {
      repo.aula = aulaDe(data: DateTime(2026, 6, 9));
      await expectLater(
        service.reservar(identidade: aluno, idAula: 1),
        throwsA(erroDe(CodigoErro.aulaDataPassada)),
      );
    });

    test('vigencia: ano fora do corrente e do seguinte (CA-9)', () async {
      repo.aula = aulaDe(data: DateTime(2028, 6, 20));
      await expectLater(
        service.reservar(identidade: aluno, idAula: 1),
        throwsA(
          isA<AulaValidationException>()
              .having((e) => e.codigo, 'codigo', CodigoErro.campoInvalido)
              .having((e) => e.campo, 'campo', 'data'),
        ),
      );
    });

    test('vigencia aceita o ano seguinte', () async {
      repo.aula = aulaDe(data: DateTime(2027, 1, 15));
      final a = await service.reservar(identidade: aluno, idAula: 1);
      expect(a.status, 'agendado');
    });
  });

  group('janela de 2 horas (CA-6)', () {
    test('faltando 1h30 para a aula: AGENDAMENTO_FORA_DA_JANELA', () async {
      repo.aula = aulaDe(
        data: DateTime(2026, 6, 10),
        horaInicio: const Duration(hours: 13, minutes: 30),
        horaFim: const Duration(hours: 14, minutes: 30),
      );
      await expectLater(
        service.reservar(identidade: aluno, idAula: 1),
        throwsA(erroDe(CodigoErro.agendamentoForaDaJanela)),
      );
      expect(repo.agendamentos, isEmpty);
    });

    test('exatamente 2 horas antes: permitido', () async {
      repo.aula = aulaDe(
        data: DateTime(2026, 6, 10),
        horaInicio: const Duration(hours: 14),
        horaFim: const Duration(hours: 15),
      );
      final a = await service.reservar(identidade: aluno, idAula: 1);
      expect(a.status, 'agendado');
    });

    test('aula ja iniciada: bloqueada', () async {
      repo.aula = aulaDe(
        data: DateTime(2026, 6, 10),
        horaInicio: const Duration(hours: 11),
        horaFim: const Duration(hours: 12),
      );
      await expectLater(
        service.reservar(identidade: aluno, idAula: 1),
        throwsA(erroDe(CodigoErro.agendamentoForaDaJanela)),
      );
    });
  });

  group('lotacao e duplicidade (CA-3, CA-4)', () {
    test('aula lotada: AULA_SEM_VAGAS, nao DUPLICADO (CA-3)', () async {
      repo.aula = aulaDe(vagas: 1);
      await service.reservar(identidade: outroAluno, idAula: 1);
      await expectLater(
        service.reservar(identidade: aluno, idAula: 1),
        throwsA(
          isA<AgendamentoConflictException>().having(
            (e) => e.codigo,
            'codigo',
            CodigoErro.aulaSemVagas,
          ),
        ),
      );
    });

    test(
      'aluno ja com agendamento ativo: AGENDAMENTO_DUPLICADO (CA-4)',
      () async {
        await service.reservar(identidade: aluno, idAula: 1);
        await expectLater(
          service.reservar(identidade: aluno, idAula: 1),
          throwsA(erroDe(CodigoErro.agendamentoDuplicado)),
        );
        expect(repo.agendamentos, hasLength(1));
      },
    );

    test(
      'aluno com vaga em aula lotada recebe DUPLICADO, nao SEM_VAGAS',
      () async {
        repo.aula = aulaDe(vagas: 1);
        await service.reservar(identidade: aluno, idAula: 1);
        await expectLater(
          service.reservar(identidade: aluno, idAula: 1),
          throwsA(erroDe(CodigoErro.agendamentoDuplicado)),
        );
      },
    );
  });

  group('cancelamento (CA-1, CA-6, CA-7)', () {
    test('aluno cancela o proprio agendamento fora da janela', () async {
      final a = await service.reservar(identidade: aluno, idAula: 1);
      final c = await service.cancelar(
        identidade: aluno,
        idAgendamento: a.idAgendamento,
      );
      expect(c.status, 'cancelado');
      expect(c.dataCancelamento?.dateTime.isAtSameMomentAs(agoraFixo), isTrue);
    });

    test(
      'cancelar libera a vaga: outro aluno reserva a aula lotada (CA-7)',
      () async {
        repo.aula = aulaDe(vagas: 1);
        final a = await service.reservar(identidade: aluno, idAula: 1);
        await expectLater(
          service.reservar(identidade: outroAluno, idAula: 1),
          throwsA(erroDe(CodigoErro.aulaSemVagas)),
        );
        await service.cancelar(
          identidade: aluno,
          idAgendamento: a.idAgendamento,
        );
        final b = await service.reservar(identidade: outroAluno, idAula: 1);
        expect(b.idAluno, 6);
      },
    );

    test('reagendar a mesma aula reativa a linha cancelada', () async {
      final a = await service.reservar(identidade: aluno, idAula: 1);
      await service.cancelar(identidade: aluno, idAgendamento: a.idAgendamento);
      final b = await service.reservar(identidade: aluno, idAula: 1);
      expect(b.idAgendamento, a.idAgendamento);
      expect(b.status, 'agendado');
      expect(b.dataCancelamento, isNull);
      expect(repo.agendamentos, hasLength(1));
    });

    test('aluno tentando cancelar agendamento de outro: 404, igual a id inexistente (CA-1)', () async {
      final a = await service.reservar(identidade: aluno, idAula: 1);
      await expectLater(
        service.cancelar(
          identidade: outroAluno,
          idAgendamento: a.idAgendamento,
        ),
        throwsA(
          isA<AgendamentoNotFoundException>()
              .having(
                (e) => e.codigo,
                'codigo',
                CodigoErro.registroNaoEncontrado,
              )
              .having(
                (e) => e.mensagem,
                'mensagem',
                'Agendamento nao encontrado.',
              ),
        ),
      );
      await expectLater(
        service.cancelar(identidade: outroAluno, idAgendamento: 999),
        throwsA(
          isA<AgendamentoNotFoundException>().having(
            (e) => e.mensagem,
            'mensagem',
            'Agendamento nao encontrado.',
          ),
        ),
      );
      expect(repo.agendamentos.single.status, 'agendado');
      // SEG-01: outro aluno nao chega ao FOR UPDATE da linha alheia.
      expect(repo.leiturasComTrava, 0);
    });

    test('professor e admin nao cancelam: AcessoNegado', () async {
      final a = await service.reservar(identidade: aluno, idAula: 1);
      await expectLater(
        service.cancelar(identidade: professor, idAgendamento: a.idAgendamento),
        throwsA(isA<AcessoNegado>()),
      );
      await expectLater(
        service.cancelar(identidade: admin, idAgendamento: a.idAgendamento),
        throwsA(isA<AcessoNegado>()),
      );
    });

    test('agendamento inexistente: 404', () async {
      await expectLater(
        service.cancelar(identidade: aluno, idAgendamento: 999),
        throwsA(erroDe(CodigoErro.registroNaoEncontrado)),
      );
    });

    test(
      'dentro da janela de 2h: AGENDAMENTO_FORA_DA_JANELA e nada muda',
      () async {
        final a = await service.reservar(identidade: aluno, idAula: 1);
        repo.aula = aulaDe(
          data: DateTime(2026, 6, 10),
          horaInicio: const Duration(hours: 13),
          horaFim: const Duration(hours: 14),
        );
        await expectLater(
          service.cancelar(identidade: aluno, idAgendamento: a.idAgendamento),
          throwsA(erroDe(CodigoErro.agendamentoForaDaJanela)),
        );
        expect(repo.agendamentos.single.status, 'agendado');
      },
    );

    test('cancelar de novo devolve o estado atual, sem erro', () async {
      final a = await service.reservar(identidade: aluno, idAula: 1);
      await service.cancelar(identidade: aluno, idAgendamento: a.idAgendamento);
      final de2 = await service.cancelar(
        identidade: aluno,
        idAgendamento: a.idAgendamento,
      );
      expect(de2.status, 'cancelado');
    });
  });

  group('leitura do aluno (CA-10)', () {
    test('lista so os proprios agendamentos', () async {
      await service.reservar(identidade: aluno, idAula: 1);
      await service.reservar(identidade: outroAluno, idAula: 1);
      final pagina = await service.listarDoAluno(aluno, limit: 20, offset: 0);
      expect(pagina.total, 1);
      expect(pagina.itens.map((a) => a.idAluno), everyElement(5));
    });

    test('professor e admin nao listam: AcessoNegado', () async {
      await expectLater(
        service.listarDoAluno(professor, limit: 20, offset: 0),
        throwsA(isA<AcessoNegado>()),
      );
    });
  });

  group('cancelarEmCascata', () {
    AgendamentoData agendamento(int id, int idAula, String status) =>
        AgendamentoData(
          idAgendamento: id,
          idAluno: 100 + id,
          idAula: idAula,
          dataAgendamento: PgDate(year: 2026, month: 6, day: 1),
          status: status,
          dataCancelamento: status == 'cancelado'
              ? PgDateTime(DateTime.utc(2026, 6, 2))
              : null,
        );

    test('repassa a aula e o instante; so agendado vira cancelado', () async {
      final instante = DateTime.utc(2026, 6, 10, 15, 30, 1, 2, 3);
      repo.agendamentos.addAll([
        agendamento(1, 1, 'agendado'),
        agendamento(2, 1, 'presente'),
        agendamento(3, 1, 'faltou'),
        agendamento(4, 1, 'cancelado'),
        agendamento(5, 1, 'agendado'),
        agendamento(6, 2, 'agendado'),
      ]);
      final antes = List.of(repo.agendamentos);

      final alterados = await service.cancelarEmCascata(1, agora: instante);

      expect(alterados, 2);
      expect(repo.cascatas, [(1, instante)]);
      for (final i in [0, 4]) {
        expect(repo.agendamentos[i].status, 'cancelado');
        expect(repo.agendamentos[i].dataCancelamento!.dateTime, instante);
      }
      for (final i in [1, 2, 3, 5]) {
        expect(repo.agendamentos[i], antes[i]);
      }
    });

    test('nao usa o relogio do service nem abre transacao propria', () async {
      final instante = DateTime.utc(2030, 1, 1);
      repo.agendamentos.add(agendamento(1, 1, 'agendado'));
      await service.cancelarEmCascata(1, agora: instante);
      expect(repo.cascatas.single.$2, instante);
      expect(repo.cascatas.single.$2, isNot(agoraFixo));
      expect(repo.transacoes, 0);
      expect(repo.leiturasComTrava, 0);
    });
  });

  test('a reserva le a aula travada dentro da transacao', () async {
    await service.reservar(identidade: aluno, idAula: 1);
    expect(repo.leiturasSemTransacao, 0);
  });
}
