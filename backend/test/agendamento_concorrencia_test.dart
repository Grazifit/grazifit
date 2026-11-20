@Timeout(Duration(minutes: 10))
library;

import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/agendamentos/agendamento_repository.dart';
import 'package:grazifit_backend/features/agendamentos/agendamento_service.dart';
import 'package:grazifit_backend/shared/autorizacao/identidade.dart';
import 'package:grazifit_backend/shared/erros/agendamento_exception.dart';
import 'package:shared/erros/codigo_erro.dart';
import 'package:test/test.dart';

import 'agendamento_banco_teste.dart';

/// Concorrencia real: cada cliente tem a sua propria
/// conexao Postgres (`GraziDatabase` por cliente), senao o Drift serializa
/// tudo numa conexao e o teste nao exercita o `FOR UPDATE`.
///
/// Requer `DATABASE_URL` apontando para o container de teste.
const _clientes = 50;
const _repeticoes = 20;

double _p95(List<int> micros) {
  final ordenados = [...micros]..sort();
  final indice = (ordenados.length * 0.95).ceil() - 1;
  return ordenados[indice] / 1000.0;
}

void main() {
  const tag = 'conc';

  late GraziDatabase admin;
  late List<GraziDatabase> conexoes;
  late List<AgendamentoService> servicos;
  late List<int> alunos;
  late int idProfessor;

  // Instante injetado: vale so para data_cancelamento. As regras de tempo
  // (data passada, janela, vigencia) leem o relogio do banco; as aulas do
  // teste usam datas relativas (dataRelativaIso).
  final agora = DateTime(2099, 1, 1, 6);

  setUpAll(() async {
    admin = GraziDatabase.doAmbiente();
    await limparDadosDeTeste(admin, tag);
    idProfessor = await inserirProfessor(admin, tag: tag, cpfBase: 700000022);

    alunos = [
      for (var i = 0; i < _clientes; i++)
        await inserirAluno(admin, tag: tag, indice: i, cpfBase: 310000000 + i),
    ];

    conexoes = List.generate(_clientes, (_) => GraziDatabase.doAmbiente());
    servicos = [
      for (final c in conexoes)
        AgendamentoService(AgendamentoRepository(c), agora: () => agora),
    ];
    // Conecta antes de medir: o teste mede o custo em regime, nao o handshake.
    await Future.wait([
      for (final c in conexoes) c.customSelect('SELECT 1').get(),
    ]);
  });

  tearDownAll(() async {
    for (final c in conexoes) {
      await c.close();
    }
    await limparDadosDeTeste(admin, tag);
    await admin.close();
  });

  test(
    'CA-5: 50 clientes na ultima vaga -> 1 reserva, 49 AULA_SEM_VAGAS, zero erro inesperado, repetido $_repeticoes vezes',
    () async {
      final latencias = <int>[];
      var sucessosTotais = 0;

      for (var rep = 0; rep < _repeticoes; rep++) {
        final idAula = await inserirAula(
          admin,
          idProfessor: idProfessor,
          dataIso: await dataRelativaIso(admin, 10 + rep),
          horaInicio: '10:00',
          horaFim: '11:00',
          vagas: 1,
        );

        final resultados = await Future.wait([
          for (var i = 0; i < _clientes; i++)
            _medir(
              latencias,
              () => servicos[i].reservar(
                identidade: Identidade(id: alunos[i], papel: Papel.aluno),
                idAula: idAula,
              ),
            ),
        ]);

        var sucessos = 0;
        var semVagas = 0;
        final inesperados = <Object>[];
        for (final r in resultados) {
          if (r.erro == null) {
            sucessos++;
          } else if (r.erro is AgendamentoConflictException &&
              (r.erro as AgendamentoConflictException).codigo ==
                  CodigoErro.aulaSemVagas) {
            semVagas++;
          } else {
            inesperados.add(r.erro!);
          }
        }

        expect(
          inesperados,
          isEmpty,
          reason: 'repeticao $rep: erro fora do contrato',
        );
        expect(sucessos, 1, reason: 'repeticao $rep: reservas');
        expect(semVagas, _clientes - 1, reason: 'repeticao $rep: SEM_VAGAS');

        final linhas = await contarLinhas(admin, idAula);
        expect(linhas, 1, reason: 'repeticao $rep: duplicata ou perda');
        sucessosTotais += sucessos;
      }

      expect(sucessosTotais, _repeticoes);
      final p95 = _p95(latencias);
      // ignore: avoid_print
      print(
        'POST /agendamentos (servico, $_clientes concorrentes x '
        '$_repeticoes): p95 = ${p95.toStringAsFixed(1)} ms, '
        'max = ${(latencias.reduce((a, b) => a > b ? a : b) / 1000).toStringAsFixed(1)} ms',
      );
      expect(p95, lessThanOrEqualTo(1000), reason: 'RNF-B: p95 do POST');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'RNF-B: $_clientes cancelamentos concorrentes, p95 <= 600 ms, repetido $_repeticoes vezes',
    () async {
      final latencias = <int>[];

      for (var rep = 0; rep < _repeticoes; rep++) {
        final idAula = await inserirAula(
          admin,
          idProfessor: idProfessor,
          dataIso: await dataRelativaIso(admin, 40 + rep),
          horaInicio: '10:00',
          horaFim: '11:00',
          vagas: _clientes,
        );

        final reservas = await Future.wait([
          for (var i = 0; i < _clientes; i++)
            servicos[i].reservar(
              identidade: Identidade(id: alunos[i], papel: Papel.aluno),
              idAula: idAula,
            ),
        ]);

        final cancelamentos = await Future.wait([
          for (var i = 0; i < _clientes; i++)
            _medir(
              latencias,
              () => servicos[i].cancelar(
                identidade: Identidade(id: alunos[i], papel: Papel.aluno),
                idAgendamento: reservas[i].idAgendamento,
              ),
            ),
        ]);

        final erros = cancelamentos.where((r) => r.erro != null).toList();
        expect(erros, isEmpty, reason: 'repeticao $rep: cancelamentos');
        expect(
          cancelamentos.every((r) => r.valor?.status == 'cancelado'),
          isTrue,
          reason: 'repeticao $rep: status',
        );

        final ativas = await admin
            .customSelect(
              'SELECT COUNT(*)::int AS total FROM agendamento '
              "WHERE id_aula = $idAula AND status <> 'cancelado'",
            )
            .getSingle();
        expect(ativas.read<int>('total'), 0, reason: 'repeticao $rep: vagas');
      }

      final p95 = _p95(latencias);
      // ignore: avoid_print
      print(
        'PATCH /agendamentos (servico, $_clientes concorrentes x '
        '$_repeticoes): p95 = ${p95.toStringAsFixed(1)} ms',
      );
      expect(p95, lessThanOrEqualTo(600), reason: 'RNF-B: p95 do cancelamento');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

class _Medida<T> {
  final T? valor;
  final Object? erro;
  const _Medida(this.valor, this.erro);
}

/// Mede a duracao e captura o erro em vez de propagar, para o `Future.wait`
/// sempre devolver todas as respostas.
Future<_Medida<T>> _medir<T>(
  List<int> latencias,
  Future<T> Function() acao,
) async {
  final sw = Stopwatch()..start();
  try {
    final valor = await acao();
    latencias.add(sw.elapsedMicroseconds);
    return _Medida(valor, null);
  } catch (e) {
    latencias.add(sw.elapsedMicroseconds);
    return _Medida(null, e);
  }
}
