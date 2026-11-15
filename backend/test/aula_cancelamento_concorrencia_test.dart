@Timeout(Duration(minutes: 10))
library;

import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/agendamentos/agendamento_repository.dart';
import 'package:grazifit_backend/features/agendamentos/agendamento_service.dart';
import 'package:grazifit_backend/features/aulas/aula_repository.dart';
import 'package:grazifit_backend/features/aulas/aula_service.dart';
import 'package:grazifit_backend/shared/autorizacao/identidade.dart';
import 'package:grazifit_backend/shared/erros/agendamento_exception.dart';
import 'package:shared/erros/codigo_erro.dart';
import 'package:test/test.dart';

import 'agendamento_banco_teste.dart';

/// Cancelamento de aula concorrendo com reservas na mesma aula. Cada
/// cliente tem a sua conexao, senao o Drift serializa tudo e o teste nao
/// exercita o `FOR UPDATE`.
///
/// Requer `DATABASE_URL` apontando para o container de teste.
const _alunos = 8;
const _jaReservados = 3;
const _rodadas = 10;
const _confirmadasAntes = 3;

void main() {
  const tag = 'aucanc';

  late GraziDatabase admin;
  late GraziDatabase conexaoCancelamento;
  late List<GraziDatabase> conexoesReserva;
  late AulaService aulaService;
  late List<AgendamentoService> reservas;
  late List<int> alunos;
  late int idProfessor;

  setUpAll(() async {
    admin = GraziDatabase.doAmbiente();
    await limparDadosDeTeste(admin, tag);
    idProfessor = await inserirProfessor(admin, tag: tag, cpfBase: 700000023);
    alunos = [
      for (var i = 0; i < _alunos + _jaReservados; i++)
        await inserirAluno(admin, tag: tag, indice: i, cpfBase: 410000000 + i),
    ];

    conexaoCancelamento = GraziDatabase.doAmbiente();
    // Cascata na mesma conexao da aula: entra na transacao do cancelamento.
    aulaService = AulaService(
      AulaRepository(conexaoCancelamento),
      AgendamentoService(AgendamentoRepository(conexaoCancelamento)),
    );
    conexoesReserva = List.generate(_alunos, (_) => GraziDatabase.doAmbiente());
    reservas = [
      for (final c in conexoesReserva)
        AgendamentoService(AgendamentoRepository(c)),
    ];
    await Future.wait([
      for (final c in [conexaoCancelamento, ...conexoesReserva])
        c.customSelect('SELECT 1').get(),
    ]);
  });

  tearDownAll(() async {
    for (final c in [conexaoCancelamento, ...conexoesReserva]) {
      await c.close();
    }
    await limparDadosDeTeste(admin, tag);
    await admin.close();
  });

  test('cancelamento e $_alunos reservas simultaneas: nenhum agendado em aula '
      'cancelada, zero erro inesperado, $_rodadas rodadas', () async {
    var reservasAntes = 0;
    var recusadasInativa = 0;
    var confirmadasNoTotal = 0;
    var pedidosNoTotal = 0;

    for (var rodada = 0; rodada < _rodadas; rodada++) {
      final idAula = await inserirAula(
        admin,
        idProfessor: idProfessor,
        dataIso: await dataRelativaIso(admin, 10 + rodada),
        horaInicio: '10:00',
        horaFim: '11:00',
        vagas: _alunos + _jaReservados,
      );
      // Reservas ja existentes, que a cascata precisa cancelar.
      final jaExistentes = <int>[
        for (var i = 0; i < _jaReservados; i++)
          (await admin
                  .customSelect(
                    'INSERT INTO agendamento (id_aluno, id_aula) '
                    'VALUES (${alunos[_alunos + i]}, $idAula) '
                    'RETURNING id_agendamento AS id',
                  )
                  .getSingle())
              .read<int>('id'),
      ];

      // Rodadas impares: reservas pelo service, ja commitadas antes do
      // cancelamento. Garante o caminho "reserva entra primeiro".
      final confirmadas = rodada.isOdd ? _confirmadasAntes : 0;
      for (var i = 0; i < confirmadas; i++) {
        final agendamento = await reservas[i].reservar(
          identidade: Identidade(id: alunos[i], papel: Papel.aluno),
          idAula: idAula,
        );
        expect(agendamento.status, 'agendado');
        jaExistentes.add(agendamento.idAgendamento);
      }
      confirmadasNoTotal += confirmadas;

      final cancelamento = _capturar(
        () => aulaService.cancelar(
          identidade: Identidade(id: idProfessor, papel: Papel.professor),
          idAula: idAula,
        ),
      );
      final pedidos = [
        for (var i = confirmadas; i < _alunos; i++)
          _capturar(
            () => reservas[i].reservar(
              identidade: Identidade(id: alunos[i], papel: Papel.aluno),
              idAula: idAula,
            ),
          ),
      ];
      pedidosNoTotal += pedidos.length;
      final resultadoCancelamento = await cancelamento;
      final resultados = await Future.wait(pedidos);

      expect(
        resultadoCancelamento.erro,
        isNull,
        reason: 'rodada $rodada: cancelamento falhou',
      );
      expect(resultadoCancelamento.valor!.status, isFalse);
      expect(resultadoCancelamento.valor!.dataCancelamento, isNotNull);

      final inesperados = <Object>[];
      for (final r in resultados) {
        if (r.erro == null) {
          reservasAntes++;
        } else if (r.erro is AgendamentoConflictException &&
            (r.erro as AgendamentoConflictException).codigo ==
                CodigoErro.aulaInativa) {
          recusadasInativa++;
        } else {
          inesperados.add(r.erro!);
        }
      }
      expect(
        inesperados,
        isEmpty,
        reason: 'rodada $rodada: erro fora do contrato',
      );

      final estado = await admin.customSelect('''
          SELECT au.status AS ativa,
                 COUNT(*) FILTER (WHERE ag.status = 'agendado')::int
                   AS agendados,
                 COUNT(*) FILTER (WHERE ag.status = 'cancelado'
                   AND ag.data_cancelamento IS DISTINCT FROM
                       au.data_cancelamento)::int AS fora_do_instante
            FROM aula au
            LEFT JOIN agendamento ag ON ag.id_aula = au.id_aula
           WHERE au.id_aula = $idAula
           GROUP BY au.status''').getSingle();
      expect(estado.read<bool>('ativa'), isFalse, reason: 'rodada $rodada');
      expect(
        estado.read<int>('agendados'),
        0,
        reason: 'rodada $rodada: agendado em aula cancelada',
      );
      expect(
        estado.read<int>('fora_do_instante'),
        0,
        reason: 'rodada $rodada: cancelado com instante diferente da aula',
      );

      // Toda reserva commitada antes do cancelamento foi pega pela cascata.
      final canceladasPelaCascata = await admin.customSelect('''
          SELECT COUNT(*)::int AS total
            FROM agendamento ag
            JOIN aula au ON au.id_aula = ag.id_aula
           WHERE ag.id_agendamento IN (${jaExistentes.join(', ')})
             AND ag.status = 'cancelado'
             AND au.data_cancelamento IS NOT NULL
             AND ag.data_cancelamento = au.data_cancelamento''').getSingle();
      expect(
        canceladasPelaCascata.read<int>('total'),
        jaExistentes.length,
        reason: 'rodada $rodada: reserva anterior nao cancelada pela cascata',
      );
    }

    // ignore: avoid_print
    print(
      'cancelamento x reserva ($_rodadas rodadas): $confirmadasNoTotal '
      'reservas confirmadas antes do cancelamento, $reservasAntes reservas '
      'simultaneas entraram antes e foram canceladas, $recusadasInativa '
      'recusadas com AULA_INATIVA',
    );
    expect(confirmadasNoTotal, greaterThan(0));
    expect(reservasAntes + recusadasInativa, pedidosNoTotal);
  }, timeout: const Timeout(Duration(minutes: 5)));
}

class _Resultado<T> {
  final T? valor;
  final Object? erro;
  const _Resultado(this.valor, this.erro);
}

/// Captura o erro em vez de propagar, para o `Future.wait` devolver todas
/// as respostas.
Future<_Resultado<T>> _capturar<T>(Future<T> Function() acao) async {
  try {
    return _Resultado(await acao(), null);
  } catch (e) {
    return _Resultado(null, e);
  }
}
