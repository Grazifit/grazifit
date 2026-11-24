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

  group('registrarChamada', () {
    const outroProfessor = Identidade(id: 99, papel: Papel.professor);

    AgendamentoData ag(int id, int idAluno, String status, {int idAula = 1}) =>
        AgendamentoData(
          idAgendamento: id,
          idAluno: idAluno,
          idAula: idAula,
          dataAgendamento: PgDate(year: 2026, month: 6, day: 1),
          status: status,
          dataCancelamento: status == 'cancelado'
              ? PgDateTime(DateTime.utc(2026, 6, 2))
              : null,
        );

    PresencaInformada p(int id, {required bool presente}) =>
        PresencaInformada(idAgendamento: id, presente: presente);

    AgendamentoData linha(int id) =>
        repo.agendamentos.firstWhere((a) => a.idAgendamento == id);

    String statusDe(int id) => linha(id).status;

    List<String> fotoDosStatus() =>
        [for (final a in repo.agendamentos) '${a.idAgendamento}:${a.status}'];

    Matcher erroCodigo(CodigoErro c) => anyOf(
      isA<ChamadaException>().having((e) => e.codigo, 'codigo', c),
      isA<AgendamentoException>().having((e) => e.codigo, 'codigo', c),
      isA<AulaException>().having((e) => e.codigo, 'codigo', c),
    );

    List<PresencaInformada> listaCompleta() => [
      p(1, presente: true),
      p(2, presente: false),
      p(3, presente: true),
    ];

    Future<void> primeiroEnvio({Identidade quem = professor}) async {
      await service.registrarChamada(
        identidade: quem,
        idAula: 1,
        itens: listaCompleta(),
      );
    }

    setUp(() {
      repo.aula = aulaDe(data: DateTime(2026, 6, 9));
      repo.agendamentos.addAll([
        ag(1, 5, 'agendado'),
        ag(2, 6, 'agendado'),
        ag(3, 7, 'agendado'),
        ag(4, 8, 'cancelado'),
      ]);
    });

    test('CA-1: professor da aula envia a lista completa; data_presenca so em presente', () async {
      final r = await service.registrarChamada(
        identidade: professor,
        idAula: 1,
        itens: listaCompleta(),
      );

      expect([for (final a in r) a.idAgendamento], [1, 2, 3]);
      expect(statusDe(1), 'presente');
      expect(statusDe(2), 'faltou');
      expect(statusDe(3), 'presente');
      expect(linha(1).dataPresenca!.dateTime, agoraFixo);
      expect(linha(2).dataPresenca, isNull);
      expect(linha(3).dataPresenca!.dateTime, agoraFixo);
    });

    test('CA-2: admin envia a mesma lista', () async {
      await service.registrarChamada(
        identidade: admin,
        idAula: 1,
        itens: listaCompleta(),
      );
      expect(statusDe(1), 'presente');
      expect(statusDe(2), 'faltou');
      expect(statusDe(3), 'presente');
    });

    test('CA-3: aluno nao envia e nada e gravado', () async {
      final antes = fotoDosStatus();
      await expectLater(
        service.registrarChamada(
          identidade: aluno,
          idAula: 1,
          itens: listaCompleta(),
        ),
        throwsA(isA<AcessoNegado>()),
      );
      expect(fotoDosStatus(), antes);
    });

    test('CA-4: professor de outra aula: 404 igual a aula inexistente, sem travar a aula, nada e gravado', () async {
      final antes = fotoDosStatus();
      await expectLater(
        service.registrarChamada(
          identidade: outroProfessor,
          idAula: 1,
          itens: listaCompleta(),
        ),
        throwsA(erroCodigo(CodigoErro.registroNaoEncontrado)),
      );
      expect(repo.travasDaAula, 0);
      expect(fotoDosStatus(), antes);
    });

    test('CA-4: professor de outra aula e aula inexistente geram o mesmo erro', () async {
      final outra = service.registrarChamada(
        identidade: outroProfessor,
        idAula: 1,
        itens: listaCompleta(),
      );
      final inexistente = service.registrarChamada(
        identidade: professor,
        idAula: 77,
        itens: listaCompleta(),
      );
      await expectLater(outra, throwsA(isA<AulaNotFoundException>()));
      await expectLater(inexistente, throwsA(isA<AulaNotFoundException>()));
    });

    test('professor da aula trava a aula uma vez; admin tambem', () async {
      await primeiroEnvio();
      expect(repo.travasDaAula, 1);
      await service.registrarChamada(
        identidade: admin,
        idAula: 1,
        itens: [p(2, presente: true)],
      );
      expect(repo.travasDaAula, 2);
    });

    test('CA-5: primeiro envio com lista incompleta: 409, nada muda', () async {
      final antes = fotoDosStatus();
      await expectLater(
        service.registrarChamada(
          identidade: professor,
          idAula: 1,
          itens: [p(1, presente: true), p(2, presente: false)],
        ),
        throwsA(erroCodigo(CodigoErro.registroEmUso)),
      );
      expect(fotoDosStatus(), antes);
    });

    test('CA-6: id de outra aula no primeiro envio: 400, nada muda', () async {
      repo.agendamentos.add(ag(9, 9, 'agendado', idAula: 2));
      final antes = fotoDosStatus();
      await expectLater(
        service.registrarChamada(
          identidade: professor,
          idAula: 1,
          itens: [...listaCompleta(), p(9, presente: true)],
        ),
        throwsA(erroCodigo(CodigoErro.campoInvalido)),
      );
      expect(fotoDosStatus(), antes);
    });

    test('CA-6: id repetido na lista: 400, nada muda', () async {
      final antes = fotoDosStatus();
      await expectLater(
        service.registrarChamada(
          identidade: professor,
          idAula: 1,
          itens: [p(1, presente: true), p(1, presente: false), p(2, presente: true), p(3, presente: true)],
        ),
        throwsA(erroCodigo(CodigoErro.campoInvalido)),
      );
      expect(fotoDosStatus(), antes);
    });

    test('CA-7: agendamento cancelado fica fora da lista e nao muda', () async {
      await primeiroEnvio();
      expect(statusDe(4), 'cancelado');
      expect(linha(4).dataPresenca, isNull);
    });

    test('CA-8: aula cancelada: 409, nada muda', () async {
      repo.aula = aulaDe(data: DateTime(2026, 6, 9), status: false);
      final antes = fotoDosStatus();
      await expectLater(
        service.registrarChamada(
          identidade: professor,
          idAula: 1,
          itens: listaCompleta(),
        ),
        throwsA(erroCodigo(CodigoErro.aulaInativa)),
      );
      expect(fotoDosStatus(), antes);
    });

    test('CA-9: antes do inicio da aula: 409, nada muda', () async {
      repo.aula = aulaDe();
      final antes = fotoDosStatus();
      await expectLater(
        service.registrarChamada(
          identidade: professor,
          idAula: 1,
          itens: listaCompleta(),
        ),
        throwsA(erroCodigo(CodigoErro.agendamentoForaDaJanela)),
      );
      expect(fotoDosStatus(), antes);
    });

    test('CA-9: no instante exato do inicio a chamada e aceita', () async {
      final inicio = DateTime.utc(2026, 6, 9, 21); // 18:00 de Brasilia
      repo.agora = () => inicio;
      final noInicio = AgendamentoService(repo, agora: () => inicio);
      await noInicio.registrarChamada(
        identidade: professor,
        idAula: 1,
        itens: listaCompleta(),
      );
      expect(statusDe(1), 'presente');
      expect(statusDe(2), 'faltou');
    });

    test('CA-9: um segundo antes do inicio: 409, nada muda', () async {
      final umSegundoAntes = DateTime.utc(2026, 6, 9, 20, 59, 59);
      repo.agora = () => umSegundoAntes;
      final antes = AgendamentoService(repo, agora: () => umSegundoAntes);
      final foto = fotoDosStatus();
      await expectLater(
        antes.registrarChamada(
          identidade: professor,
          idAula: 1,
          itens: listaCompleta(),
        ),
        throwsA(erroCodigo(CodigoErro.agendamentoForaDaJanela)),
      );
      expect(fotoDosStatus(), foto);
    });

    test('CA-12: ajuste antes do primeiro envio: 409, nada muda', () async {
      final antes = fotoDosStatus();
      await expectLater(
        service.registrarChamada(
          identidade: professor,
          idAula: 1,
          itens: [p(2, presente: true)],
        ),
        throwsA(erroCodigo(CodigoErro.registroEmUso)),
      );
      expect(fotoDosStatus(), antes);
    });

    test('CA-10: corrige um aluno; os demais e a data_presenca original nao mudam', () async {
      await primeiroEnvio();
      final depois = AgendamentoService(
        repo,
        agora: () => agoraFixo.add(const Duration(minutes: 30)),
      );

      await depois.registrarChamada(
        identidade: professor,
        idAula: 1,
        itens: [p(2, presente: true)],
      );

      expect(statusDe(2), 'presente');
      expect(linha(2).dataPresenca!.dateTime, agoraFixo.add(const Duration(minutes: 30)));
      expect(statusDe(1), 'presente');
      expect(linha(1).dataPresenca!.dateTime, agoraFixo);
      expect(statusDe(3), 'presente');
      expect(statusDe(4), 'cancelado');
    });

    test('CA-11: presente volta para faltou e data_presenca fica nula', () async {
      await primeiroEnvio();
      await service.registrarChamada(
        identidade: professor,
        idAula: 1,
        itens: [p(1, presente: false)],
      );
      expect(statusDe(1), 'faltou');
      expect(linha(1).dataPresenca, isNull);
    });

    test('CA-16: envio so dos alterados, sem mexer nos demais', () async {
      await primeiroEnvio();
      repo.agendamentos.add(ag(5, 10, 'faltou'));
      final antesDoAluno3 = linha(3);

      await service.registrarChamada(
        identidade: professor,
        idAula: 1,
        itens: [p(2, presente: true), p(5, presente: true)],
      );

      expect(statusDe(2), 'presente');
      expect(statusDe(5), 'presente');
      expect(linha(5).dataPresenca!.dateTime, agoraFixo);
      expect(linha(3), antesDoAluno3);
    });

    test('CA-16: mesmo status enviado de novo nao regrava data_presenca', () async {
      await primeiroEnvio();
      final depois = AgendamentoService(
        repo,
        agora: () => agoraFixo.add(const Duration(hours: 1)),
      );
      await depois.registrarChamada(
        identidade: professor,
        idAula: 1,
        itens: [p(1, presente: true)],
      );
      expect(linha(1).dataPresenca!.dateTime, agoraFixo);
    });

    test('CA-16: lista vazia: 400, nada muda, em qualquer fase', () async {
      final antes = fotoDosStatus();
      await expectLater(
        service.registrarChamada(identidade: professor, idAula: 1, itens: const []),
        throwsA(erroCodigo(CodigoErro.campoInvalido)),
      );
      expect(fotoDosStatus(), antes);

      await primeiroEnvio();
      await expectLater(
        service.registrarChamada(identidade: professor, idAula: 1, itens: const []),
        throwsA(erroCodigo(CodigoErro.campoInvalido)),
      );
    });

    test('CA-13: id de agendamento de outra aula na correcao: 404, nada muda', () async {
      await primeiroEnvio();
      repo.agendamentos.add(ag(9, 9, 'agendado', idAula: 2));
      final antes = fotoDosStatus();
      await expectLater(
        service.registrarChamada(
          identidade: professor,
          idAula: 1,
          itens: [p(9, presente: true)],
        ),
        throwsA(erroCodigo(CodigoErro.registroNaoEncontrado)),
      );
      expect(fotoDosStatus(), antes);
    });

    test('CA-14: correcao por aluno: 403, nada muda', () async {
      await primeiroEnvio();
      final antes = fotoDosStatus();
      await expectLater(
        service.registrarChamada(
          identidade: aluno,
          idAula: 1,
          itens: [p(2, presente: true)],
        ),
        throwsA(isA<AcessoNegado>()),
      );
      expect(fotoDosStatus(), antes);
    });

    test('CA-14: correcao por professor de outra aula: 404, nada muda', () async {
      await primeiroEnvio();
      final antes = fotoDosStatus();
      await expectLater(
        service.registrarChamada(
          identidade: outroProfessor,
          idAula: 1,
          itens: [p(2, presente: true)],
        ),
        throwsA(erroCodigo(CodigoErro.registroNaoEncontrado)),
      );
      expect(fotoDosStatus(), antes);
    });

    test('CA-15: correcao de agendamento cancelado: 409, nada muda', () async {
      await primeiroEnvio();
      final antes = fotoDosStatus();
      await expectLater(
        service.registrarChamada(
          identidade: professor,
          idAula: 1,
          itens: [p(4, presente: true)],
        ),
        throwsA(erroCodigo(CodigoErro.registroEmUso)),
      );
      expect(fotoDosStatus(), antes);
    });

    test('CA-15: correcao com aula cancelada: 409, nada muda', () async {
      await primeiroEnvio();
      repo.aula = aulaDe(data: DateTime(2026, 6, 9), status: false);
      final antes = fotoDosStatus();
      await expectLater(
        service.registrarChamada(
          identidade: professor,
          idAula: 1,
          itens: [p(2, presente: true)],
        ),
        throwsA(erroCodigo(CodigoErro.aulaInativa)),
      );
      expect(fotoDosStatus(), antes);
    });

    test('a chamada roda numa unica transacao com a aula travada', () async {
      await primeiroEnvio();
      expect(repo.transacoes, 1);
      expect(repo.leiturasSemTransacao, 0);
    });
  });
}
