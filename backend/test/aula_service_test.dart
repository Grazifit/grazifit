import 'package:drift/drift.dart' show Value;
import 'package:drift_postgres/drift_postgres.dart' show PgDate, PgDateTime;
import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/aulas/aula_repository.dart';
import 'package:grazifit_backend/features/aulas/aula_service.dart';
import 'package:grazifit_backend/shared/autorizacao/identidade.dart';
import 'package:grazifit_backend/shared/erros/aula_exception.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:shared/erros/codigo_erro.dart';
import 'package:test/test.dart';

class _RepositorioFalso implements AulaRepository {
  AulaData? aula;
  Set<int> professoresAtivos = {10, 20};
  int ocupadas = 0;
  bool emTransacao = false;
  Map<String, Object?>? ultimaAtualizacao;

  /// Ordem das chamadas que importam para o cancelamento.
  final List<String> chamadas = [];
  Map<String, Object?>? ultimoCancelamento;

  @override
  Future<AulaData> create({
    required int idAdminCriador,
    required int idProfessor,
    required PgDate data,
    required pg.Time horaInicio,
    required pg.Time horaFim,
    required String tipo,
    required String categoria,
    required int vagasMaxima,
  }) async => aula = AulaData(
    idAula: 1,
    idAdminCriador: idAdminCriador,
    idProfessor: idProfessor,
    data: data,
    horaInicio: horaInicio,
    horaFim: horaFim,
    tipo: tipo,
    categoria: categoria,
    vagasMaxima: vagasMaxima,
    status: true,
  );

  @override
  Future<AulaData?> buscarPorId(int idAula) async =>
      aula?.idAula == idAula ? aula : null;

  @override
  Future<AulaData?> buscarParaAtualizar(int idAula) async {
    expect(emTransacao, isTrue, reason: 'leitura com trava fora da transacao');
    chamadas.add('buscarParaAtualizar');
    return buscarPorId(idAula);
  }

  @override
  Future<T> transacao<T>(Future<T> Function() acao) async {
    emTransacao = true;
    chamadas.add('inicio');
    try {
      return await acao();
    } finally {
      emTransacao = false;
      chamadas.add('fim');
    }
  }

  @override
  Future<AulaData> cancelar(
    int idAula, {
    required DateTime agora,
    int? idAdminCancelou,
    int? idProfessorCancelou,
  }) async {
    expect(emTransacao, isTrue, reason: 'cancelamento fora da transacao');
    chamadas.add('cancelar');
    ultimoCancelamento = {
      'idAula': idAula,
      'agora': agora,
      'idAdminCancelou': idAdminCancelou,
      'idProfessorCancelou': idProfessorCancelou,
    };
    return aula = aula!.copyWith(
      status: false,
      dataCancelamento: Value(PgDateTime(agora)),
      idAdminCancelou: Value(idAdminCancelou),
      idProfessorCancelou: Value(idProfessorCancelou),
    );
  }

  @override
  Future<List<AulaData>> listar({
    required int limit,
    required int offset,
    PgDate? data,
    String? categoria,
    int? idProfessor,
  }) async => [?aula];

  @override
  Future<int> contar({
    PgDate? data,
    String? categoria,
    int? idProfessor,
  }) async => aula == null ? 0 : 1;

  @override
  Future<AulaData?> atualizar(
    int idAula, {
    int? idProfessor,
    PgDate? data,
    pg.Time? horaInicio,
    pg.Time? horaFim,
    String? tipo,
    String? categoria,
    int? vagasMaxima,
  }) async {
    final atual = await buscarPorId(idAula);
    if (atual == null) return null;
    ultimaAtualizacao = {
      'idProfessor': ?idProfessor,
      'data': ?data,
      'horaInicio': ?horaInicio,
      'horaFim': ?horaFim,
      'tipo': ?tipo,
      'categoria': ?categoria,
      'vagasMaxima': ?vagasMaxima,
    };
    return aula = atual.copyWith(
      idProfessor: idProfessor,
      data: data,
      horaInicio: horaInicio,
      horaFim: horaFim,
      tipo: tipo,
      categoria: categoria,
      vagasMaxima: vagasMaxima,
    );
  }

  @override
  Future<int> contarAgendamentosAtivos(int idAula) async => ocupadas;

  /// Ocupacao devolvida por [contarOcupadasPorAula] e os ids pedidos.
  Map<int, int> ocupacao = {};
  List<int>? idsOcupacaoPedidos;

  @override
  Future<Map<int, int>> contarOcupadasPorAula(Iterable<int> idsAulas) async {
    idsOcupacaoPedidos = idsAulas.toList();
    return {
      for (final id in idsAulas)
        if (ocupacao.containsKey(id)) id: ocupacao[id]!,
    };
  }

  List<AgendadoDaAula> agendados = [];
  Map<String, int>? paginaAgendados;

  @override
  Future<List<AgendadoDaAula>> listarAgendados(
    int idAula, {
    required int limit,
    required int offset,
  }) async {
    chamadas.add('listarAgendados');
    paginaAgendados = {'idAula': idAula, 'limit': limit, 'offset': offset};
    return agendados;
  }

  @override
  Future<int> contarAgendados(int idAula) async {
    chamadas.add('contarAgendados');
    return agendados.length + 30;
  }

  @override
  Future<bool> professorAtivoExiste(int idProfessor) async =>
      professoresAtivos.contains(idProfessor);
}

/// Cascata do agendamento: registra na lista de chamadas do repositorio e
/// exige a transacao dele aberta.
class _CascataFalsa implements CancelamentoDeAgendamentos {
  final _RepositorioFalso repo;
  int? idAula;
  DateTime? instante;

  _CascataFalsa(this.repo);

  @override
  Future<int> cancelarEmCascata(int idAula, {required DateTime agora}) async {
    expect(repo.emTransacao, isTrue, reason: 'cascata fora da transacao');
    repo.chamadas.add('cascata');
    this.idAula = idAula;
    instante = agora;
    return 2;
  }
}

const admin = Identidade(id: 1, papel: Papel.admin);
const professor = Identidade(id: 10, papel: Papel.professor);
const outroProfessor = Identidade(id: 20, papel: Papel.professor);
const aluno = Identidade(id: 5, papel: Papel.aluno);

/// "Agora" fixo: 10/06/2026, 12:00.
final agora = DateTime(2026, 6, 10, 12);

AulaData aulaDe({
  int idProfessor = 10,
  DateTime? data,
  Duration horaInicio = const Duration(hours: 18),
  Duration horaFim = const Duration(hours: 19),
  String tipo = 'coletiva',
  int vagas = 10,
  bool status = true,
  int? idCronograma,
}) => AulaData(
  idAula: 1,
  idProfessor: idProfessor,
  idCronograma: idCronograma,
  data: PgDate.fromDateTime(data ?? DateTime(2026, 6, 20)),
  horaInicio: pg.Time.fromMicroseconds(horaInicio.inMicroseconds),
  horaFim: pg.Time.fromMicroseconds(horaFim.inMicroseconds),
  tipo: tipo,
  categoria: 'pilates',
  vagasMaxima: vagas,
  status: status,
);

Matcher invalido(String campo) => isA<AulaValidationException>()
    .having((e) => e.codigo, 'codigo', CodigoErro.campoInvalido)
    .having((e) => e.campo, 'campo', campo);

Matcher conflito(CodigoErro codigo, [String? campo]) =>
    isA<AulaConflictException>()
        .having((e) => e.codigo, 'codigo', codigo)
        .having((e) => e.campo, 'campo', campo);

void main() {
  late _RepositorioFalso repo;
  late _CascataFalsa cascata;
  late AulaService service;

  setUp(() {
    repo = _RepositorioFalso();
    cascata = _CascataFalsa(repo);
    service = AulaService(repo, cascata, agora: () => agora);
  });

  Future<AulaData> criar({
    Identidade identidade = admin,
    int idProfessor = 10,
    DateTime? data,
    Duration horaInicio = const Duration(hours: 7),
    Duration horaFim = const Duration(hours: 8),
    String tipo = 'coletiva',
    String categoria = 'pilates',
    int vagas = 10,
  }) => service.criar(
    identidade: identidade,
    idProfessor: idProfessor,
    data: data ?? DateTime(2026, 6, 20),
    horaInicio: horaInicio,
    horaFim: horaFim,
    tipo: tipo,
    categoria: categoria,
    vagasMaxima: vagas,
  );

  group('criar', () {
    test('admin cria aula avulsa e vira o criador', () async {
      final aula = await criar(tipo: 'individual', vagas: 3);
      expect(aula.idAdminCriador, admin.id);
      expect(aula.idCronograma, isNull);
      expect(aula.horaInicio, pg.Time(7));
    });

    test('professor e aluno nao criam', () async {
      await expectLater(
        criar(identidade: professor),
        throwsA(isA<AcessoNegado>()),
      );
      await expectLater(criar(identidade: aluno), throwsA(isA<AcessoNegado>()));
    });

    test('recusa data anterior a hoje, mesmo no ano de vigencia', () async {
      for (final data in [DateTime(2026, 6, 9), DateTime(2026, 1, 1)]) {
        await expectLater(criar(data: data), throwsA(invalido('data')));
      }
      expect(repo.aula, isNull, reason: 'nada pode ter sido gravado');
    });

    test('hoje: recusa hora de inicio passada ou exatamente agora', () async {
      for (final inicio in [
        const Duration(hours: 7),
        const Duration(hours: 12),
      ]) {
        await expectLater(
          criar(
            data: DateTime(2026, 6, 10),
            horaInicio: inicio,
            horaFim: const Duration(hours: 13),
          ),
          throwsA(invalido('hora_inicio')),
        );
      }
      expect(repo.aula, isNull, reason: 'nada pode ter sido gravado');
    });

    test('hoje: aceita hora de inicio futura', () async {
      final aula = await criar(
        data: DateTime(2026, 6, 10),
        horaInicio: const Duration(hours: 12, minutes: 1),
        horaFim: const Duration(hours: 13),
      );
      expect(aula.data, PgDate(year: 2026, month: 6, day: 10));
    });

    test(
      'logo apos a meia-noite aceita aula hoje com horario futuro',
      () async {
        final aula =
            await AulaService(
              repo,
              cascata,
              agora: () => DateTime(2026, 6, 10, 0, 5),
            ).criar(
              identidade: admin,
              idProfessor: 10,
              data: DateTime(2026, 6, 10),
              horaInicio: const Duration(hours: 7),
              horaFim: const Duration(hours: 8),
              tipo: 'coletiva',
              categoria: 'pilates',
              vagasMaxima: 5,
            );
        expect(aula.data, PgDate(year: 2026, month: 6, day: 10));
      },
    );

    test(
      'recusa data fora do ano de vigencia (anterior, posterior, extrema)',
      () async {
        for (final data in [
          DateTime(2025, 12, 31),
          DateTime(2028, 1, 1),
          DateTime(0, 1, 1),
        ]) {
          await expectLater(criar(data: data), throwsA(invalido('data')));
        }
        expect(repo.aula, isNull, reason: 'nada pode ter sido gravado');
      },
    );

    test(
      'aceita o ano seguinte (grade de janeiro montada em dezembro)',
      () async {
        final aula = await criar(data: DateTime(2027, 12, 31));
        expect(aula.data, PgDate(year: 2027, month: 12, day: 31));
      },
    );

    test('recusa vagas acima do limite do INT do banco', () async {
      await expectLater(
        criar(vagas: 2147483648),
        throwsA(invalido('vagas_maxima')),
      );
      final aula = await criar(vagas: 2147483647);
      expect(aula.vagasMaxima, 2147483647);
    });

    test('aceita os tres tipos', () async {
      for (final tipo in ['coletiva', 'individual', 'experimental']) {
        await criar(tipo: tipo, vagas: 2);
      }
    });

    test('recusa tipo, categoria, horario e vagas invalidos', () async {
      await expectLater(criar(tipo: 'yoga'), throwsA(invalido('tipo')));
      await expectLater(
        criar(categoria: 'yoga'),
        throwsA(invalido('categoria')),
      );
      await expectLater(
        criar(horaFim: const Duration(hours: 7)),
        throwsA(invalido('hora_fim')),
      );
      await expectLater(
        criar(horaInicio: const Duration(hours: 7, seconds: 30)),
        throwsA(invalido('hora_inicio')),
      );
      await expectLater(criar(vagas: 0), throwsA(invalido('vagas_maxima')));
      await expectLater(
        criar(tipo: 'individual', vagas: 4),
        throwsA(invalido('vagas_maxima')),
      );
    });

    test('recusa professor inexistente ou inativo', () async {
      await expectLater(
        criar(idProfessor: 99),
        throwsA(invalido('id_professor')),
      );
    });
  });

  group('ler', () {
    test('os tres perfis leem; id inexistente e 404', () async {
      repo.aula = aulaDe();
      for (final quem in [admin, professor, aluno]) {
        expect((await service.buscarPorId(quem, 1)).idAula, 1);
        expect((await service.listar(quem, limit: 20, offset: 0)).total, 1);
      }
      await expectLater(
        service.buscarPorId(aluno, 2),
        throwsA(isA<AulaNotFoundException>()),
      );
    });

    test('listar recusa categoria fora do schema', () async {
      await expectLater(
        service.listar(admin, limit: 20, offset: 0, categoria: 'yoga'),
        throwsA(invalido('categoria')),
      );
    });
  });

  group('atualizar', () {
    Future<AulaData> atualizar(
      Identidade identidade, {
      int? idProfessor,
      DateTime? data,
      Duration? horaInicio,
      Duration? horaFim,
      String? tipo,
      int? vagas,
    }) => service.atualizar(
      identidade: identidade,
      idAula: 1,
      idProfessor: idProfessor,
      data: data,
      horaInicio: horaInicio,
      horaFim: horaFim,
      tipo: tipo,
      vagasMaxima: vagas,
    );

    test('admin edita qualquer aula, dentro da transacao', () async {
      repo.aula = aulaDe(idProfessor: 20);
      final aula = await atualizar(admin, idProfessor: 10, vagas: 12);
      expect(aula.idProfessor, 10);
      expect(aula.vagasMaxima, 12);
      expect(repo.emTransacao, isFalse);
    });

    test('so envia ao repository o que mudou', () async {
      repo.aula = aulaDe();
      await atualizar(admin, data: DateTime(2026, 6, 20), vagas: 15);
      expect(repo.ultimaAtualizacao, {'vagasMaxima': 15});
    });

    test(
      'aluno nao edita; inexistente e 404; cancelada e AULA_INATIVA',
      () async {
        repo.aula = aulaDe();
        await expectLater(
          atualizar(aluno, vagas: 5),
          throwsA(isA<AcessoNegado>()),
        );

        repo.aula = null;
        await expectLater(
          atualizar(admin, vagas: 5),
          throwsA(isA<AulaNotFoundException>()),
        );

        repo.aula = aulaDe(status: false);
        await expectLater(
          atualizar(admin, vagas: 5),
          throwsA(conflito(CodigoErro.aulaInativa)),
        );
      },
    );

    test('professor edita a propria aula futura', () async {
      repo.aula = aulaDe();
      expect((await atualizar(professor, vagas: 8)).vagasMaxima, 8);
    });

    test('professor nao edita aula de outro', () async {
      repo.aula = aulaDe();
      await expectLater(
        atualizar(outroProfessor, vagas: 8),
        throwsA(isA<AcessoNegado>()),
      );
    });

    test('professor nao edita aula ja realizada', () async {
      // Hoje, terminou as 11:00 — antes do "agora" (12:00).
      repo.aula = aulaDe(
        data: DateTime(2026, 6, 10),
        horaInicio: const Duration(hours: 10),
        horaFim: const Duration(hours: 11),
      );
      await expectLater(
        atualizar(professor, vagas: 8),
        throwsA(isA<AcessoNegado>()),
      );
      expect((await atualizar(admin, vagas: 8)).vagasMaxima, 8);
    });

    test('professor nao troca o professor da aula', () async {
      repo.aula = aulaDe();
      await expectLater(
        atualizar(professor, idProfessor: 20),
        throwsA(isA<AcessoNegado>()),
      );
    });

    test('professor e admin nao movem para data passada', () async {
      for (final quem in [professor, admin]) {
        repo.aula = aulaDe();
        await expectLater(
          atualizar(quem, data: DateTime(2026, 6, 9)),
          throwsA(invalido('data')),
        );
        expect(repo.ultimaAtualizacao, isNull);
      }
    });

    test('admin nao poe inicio ou fim no passado', () async {
      // Aula de hoje, 13:00-14:00; agora sao 12:00.
      repo.aula = aulaDe(
        data: DateTime(2026, 6, 10),
        horaInicio: const Duration(hours: 13),
        horaFim: const Duration(hours: 14),
      );
      await expectLater(
        atualizar(admin, horaInicio: const Duration(hours: 12)),
        throwsA(invalido('hora_inicio')),
      );

      // Em andamento: 11:00-13:00.
      repo.aula = aulaDe(
        data: DateTime(2026, 6, 10),
        horaInicio: const Duration(hours: 11),
        horaFim: const Duration(hours: 13),
      );
      await expectLater(
        atualizar(admin, horaFim: const Duration(hours: 11, minutes: 30)),
        throwsA(invalido('hora_fim')),
      );

      // Trazer para hoje uma aula das 07:00.
      repo.aula = aulaDe(horaInicio: const Duration(hours: 7));
      await expectLater(
        atualizar(admin, data: DateTime(2026, 6, 10)),
        throwsA(invalido('data')),
      );
      expect(repo.ultimaAtualizacao, isNull);
    });

    test('admin altera so as vagas de aula ja realizada', () async {
      repo.aula = aulaDe(data: DateTime(2026, 6, 1));
      expect((await atualizar(admin, vagas: 12)).vagasMaxima, 12);
    });

    test(
      'logo apos a meia-noite, professor e admin trazem para hoje',
      () async {
        final service = AulaService(
          repo,
          cascata,
          agora: () => DateTime(2026, 6, 10, 0, 5),
        );
        for (final quem in [professor, admin]) {
          repo.aula = aulaDe();
          final aula = await service.atualizar(
            identidade: quem,
            idAula: 1,
            data: DateTime(2026, 6, 10),
          );
          expect(aula.data, PgDate(year: 2026, month: 6, day: 10));
        }
      },
    );

    group('regra do ano de vigencia e do horario passado', () {
      test('admin nao leva a aula para outro ano', () async {
        repo.aula = aulaDe();
        await expectLater(
          atualizar(admin, data: DateTime(2028, 1, 5)),
          throwsA(invalido('data')),
        );
        await expectLater(
          atualizar(admin, data: DateTime(2025, 12, 30)),
          throwsA(invalido('data')),
        );
      });

      test('professor nao poe a aula num horario que ja passou hoje', () {
        // Aula de hoje, 13:00-14:00; agora sao 12:00.
        repo.aula = aulaDe(
          data: DateTime(2026, 6, 10),
          horaInicio: const Duration(hours: 13),
          horaFim: const Duration(hours: 14),
        );
        return expectLater(
          atualizar(professor, horaInicio: const Duration(hours: 10)),
          throwsA(invalido('hora_inicio')),
        );
      });

      test('professor pode mover para mais tarde no proprio dia', () async {
        repo.aula = aulaDe(
          data: DateTime(2026, 6, 10),
          horaInicio: const Duration(hours: 13),
          horaFim: const Duration(hours: 14),
        );
        final aula = await atualizar(
          professor,
          horaInicio: const Duration(hours: 15),
          horaFim: const Duration(hours: 16),
        );
        expect(aula.horaInicio, pg.Time(15));
      });

      test('professor nao traz para hoje uma aula cujo horario ja passou', () {
        repo.aula = aulaDe(horaInicio: const Duration(hours: 7));
        return expectLater(
          atualizar(professor, data: DateTime(2026, 6, 10)),
          throwsA(invalido('data')),
        );
      });

      test('professor nao encerra a aula em andamento no passado', () async {
        // Em andamento: 11:00-13:00, agora sao 12:00.
        repo.aula = aulaDe(
          data: DateTime(2026, 6, 10),
          horaInicio: const Duration(hours: 11),
          horaFim: const Duration(hours: 13),
        );
        await expectLater(
          atualizar(professor, horaFim: const Duration(hours: 11, minutes: 30)),
          throwsA(invalido('hora_fim')),
        );
        final aula = await atualizar(
          professor,
          horaFim: const Duration(hours: 14),
        );
        expect(aula.horaFim, pg.Time(14));
      });

      test('admin nao encerra a aula em andamento no passado', () async {
        // Em andamento: 11:00-13:00, agora sao 12:00.
        repo.aula = aulaDe(
          data: DateTime(2026, 6, 10),
          horaInicio: const Duration(hours: 11),
          horaFim: const Duration(hours: 13),
        );
        await expectLater(
          atualizar(admin, horaFim: const Duration(hours: 11, minutes: 30)),
          throwsA(invalido('hora_fim')),
        );
        expect(repo.ultimaAtualizacao, isNull);
        final aula = await atualizar(
          admin,
          horaFim: const Duration(hours: 12, minutes: 30),
        );
        expect(aula.horaFim, pg.Time(12, 30));
      });

      test('data do banco em UTC nao vira o dia anterior', () async {
        // Hoje, 13:00-14:00, com a data lida como meia-noite UTC.
        for (final quem in [professor, admin]) {
          repo.aula = aulaDe(
            data: DateTime.utc(2026, 6, 10),
            horaInicio: const Duration(hours: 13),
            horaFim: const Duration(hours: 14),
          );
          final aula = await atualizar(
            quem,
            horaInicio: const Duration(hours: 12, minutes: 30),
          );
          expect(aula.horaInicio, pg.Time(12, 30));
          expect(repo.ultimaAtualizacao, {'horaInicio': pg.Time(12, 30)});
        }

        // Ontem em UTC: mexer so no fim continua sendo passado.
        repo.aula = aulaDe(data: DateTime.utc(2026, 6, 9));
        await expectLater(
          atualizar(admin, horaFim: const Duration(hours: 20)),
          throwsA(invalido('hora_fim')),
        );
      });

      test('quem nao pode editar recebe 403 antes da regra do ano', () async {
        repo.aula = aulaDe();
        await expectLater(
          atualizar(outroProfessor, data: DateTime(2027, 1, 5)),
          throwsA(isA<AcessoNegado>()),
        );
        await expectLater(
          atualizar(aluno, data: DateTime(0, 1, 1)),
          throwsA(isA<AcessoNegado>()),
        );
      });

      test(
        'quem nao pode editar recebe 403 antes da regra do passado',
        () async {
          repo.aula = aulaDe();
          await expectLater(
            atualizar(outroProfessor, data: DateTime(2026, 6, 9)),
            throwsA(isA<AcessoNegado>()),
          );

          // Propria aula, ja realizada hoje (10:00-11:00).
          repo.aula = aulaDe(
            data: DateTime(2026, 6, 10),
            horaInicio: const Duration(hours: 10),
            horaFim: const Duration(hours: 11),
          );
          await expectLater(
            atualizar(professor, data: DateTime(2026, 6, 9)),
            throwsA(isA<AcessoNegado>()),
          );
          await expectLater(
            atualizar(professor, horaInicio: const Duration(hours: 9)),
            throwsA(isA<AcessoNegado>()),
          );
          expect(repo.ultimaAtualizacao, isNull);
        },
      );

      test('professor dono tambem nao sai do ano de vigencia', () async {
        repo.aula = aulaDe();
        await expectLater(
          atualizar(professor, data: DateTime(2028, 1, 5)),
          throwsA(invalido('data')),
        );
      });

      test('limite de vagas tambem vale na edicao', () async {
        repo.aula = aulaDe();
        await expectLater(
          atualizar(admin, vagas: 2147483648),
          throwsA(invalido('vagas_maxima')),
        );
        expect(
          (await atualizar(admin, vagas: 2147483647)).vagasMaxima,
          2147483647,
        );
      });

      test('exatamente agora conta como passado para o professor', () async {
        repo.aula = aulaDe(
          data: DateTime(2026, 6, 10),
          horaInicio: const Duration(hours: 13),
          horaFim: const Duration(hours: 14),
        );
        await expectLater(
          atualizar(professor, horaInicio: const Duration(hours: 12)),
          throwsA(invalido('hora_inicio')),
        );
      });

      test('virada do ano: o ano de vigencia segue o relogio', () async {
        Future<void> criarCom(DateTime agora, DateTime data) =>
            AulaService(repo, cascata, agora: () => agora).criar(
              identidade: admin,
              idProfessor: 10,
              data: data,
              horaInicio: const Duration(hours: 7),
              horaFim: const Duration(hours: 8),
              tipo: 'coletiva',
              categoria: 'pilates',
              vagasMaxima: 5,
            );

        // Em 31/12 ja se monta janeiro; o ano depois do seguinte, nao.
        await criarCom(DateTime(2026, 12, 31, 23, 59), DateTime(2027, 1, 1));
        await expectLater(
          criarCom(DateTime(2026, 12, 31, 23, 59), DateTime(2028, 1, 1)),
          throwsA(invalido('data')),
        );
        await expectLater(
          criarCom(DateTime(2027, 1, 1), DateTime(2026, 12, 31)),
          throwsA(invalido('data')),
        );
        await criarCom(DateTime(2026, 12, 31, 6), DateTime(2026, 12, 31));
      });

      test('admin pode mover para mais tarde no proprio dia', () async {
        repo.aula = aulaDe(
          data: DateTime(2026, 6, 10),
          horaInicio: const Duration(hours: 13),
          horaFim: const Duration(hours: 14),
        );
        await expectLater(
          atualizar(admin, horaInicio: const Duration(hours: 9)),
          throwsA(invalido('hora_inicio')),
        );
        final aula = await atualizar(
          admin,
          horaInicio: const Duration(hours: 12, minutes: 30),
        );
        expect(aula.horaInicio, pg.Time(12, 30));
      });
    });

    test('valida a combinacao final, nao so o campo enviado', () async {
      repo.aula = aulaDe(vagas: 10);
      await expectLater(
        atualizar(admin, tipo: 'individual'),
        throwsA(invalido('vagas_maxima')),
      );
      await expectLater(
        atualizar(admin, horaFim: const Duration(hours: 17)),
        throwsA(invalido('hora_fim')),
      );
    });

    test('aula de cronograma continua coletiva', () async {
      repo.aula = aulaDe(idCronograma: 3);
      await expectLater(
        atualizar(admin, tipo: 'experimental'),
        throwsA(invalido('tipo')),
      );
    });

    test('novo professor precisa estar ativo', () async {
      repo.aula = aulaDe();
      await expectLater(
        atualizar(admin, idProfessor: 99),
        throwsA(invalido('id_professor')),
      );
    });

    group('com agendamentos ativos', () {
      setUp(() {
        repo.aula = aulaDe(vagas: 10);
        repo.ocupadas = 4;
      });

      test('trava data, hora e professor', () async {
        await expectLater(
          atualizar(admin, data: DateTime(2026, 6, 21)),
          throwsA(conflito(CodigoErro.registroEmUso, 'data')),
        );
        await expectLater(
          atualizar(admin, horaInicio: const Duration(hours: 17)),
          throwsA(conflito(CodigoErro.registroEmUso, 'hora_inicio')),
        );
        await expectLater(
          atualizar(admin, idProfessor: 20),
          throwsA(conflito(CodigoErro.registroEmUso, 'id_professor')),
        );
      });

      test('vagas nao descem abaixo da ocupacao', () async {
        await expectLater(
          atualizar(admin, vagas: 3),
          throwsA(conflito(CodigoErro.registroEmUso, 'vagas_maxima')),
        );
        expect((await atualizar(admin, vagas: 4)).vagasMaxima, 4);
      });

      test('enviar o mesmo valor nao conta como alteracao', () async {
        final aula = await atualizar(
          admin,
          data: DateTime(2026, 6, 20),
          horaInicio: const Duration(hours: 18),
          idProfessor: 10,
        );
        expect(aula.idAula, 1);
      });
    });
  });

  group('cancelar', () {
    Future<AulaData> cancelar(Identidade identidade, {int idAula = 1}) =>
        service.cancelar(identidade: identidade, idAula: idAula);

    final realizadaHoje = (DateTime(2026, 6, 10), 10, 11);

    test('admin cancela: status false, id_admin_cancelou e data', () async {
      repo.aula = aulaDe(idProfessor: 20);
      final aula = await cancelar(admin);

      expect(aula.status, isFalse);
      expect(aula.idAdminCancelou, admin.id);
      expect(aula.idProfessorCancelou, isNull);
      expect(aula.dataCancelamento!.dateTime, agora.toUtc());
      expect(repo.ultimoCancelamento, {
        'idAula': 1,
        'agora': agora.toUtc(),
        'idAdminCancelou': admin.id,
        'idProfessorCancelou': null,
      });
      expect((repo.ultimoCancelamento!['agora'] as DateTime).isUtc, isTrue);
    });

    test(
      'professor cancela a propria aula com id_professor_cancelou',
      () async {
        repo.aula = aulaDe(idProfessor: professor.id);
        final aula = await cancelar(professor);

        expect(aula.status, isFalse);
        expect(aula.idProfessorCancelou, professor.id);
        expect(aula.idAdminCancelou, isNull);
        expect(aula.dataCancelamento!.dateTime, agora.toUtc());
      },
    );

    test('cascata roda na mesma transacao, depois da trava, com o mesmo '
        'instante', () async {
      repo.aula = aulaDe();
      await cancelar(admin);

      expect(repo.chamadas, [
        'inicio',
        'buscarParaAtualizar',
        'cancelar',
        'cascata',
        'fim',
      ]);
      expect(cascata.idAula, 1);
      expect(cascata.instante, repo.ultimoCancelamento!['agora']);
      expect(cascata.instante!.isUtc, isTrue);
    });

    test('depois de cancelada, PATCH recusa com AULA_INATIVA', () async {
      repo.aula = aulaDe();
      await cancelar(admin);
      await expectLater(
        service.atualizar(identidade: admin, idAula: 1, vagasMaxima: 5),
        throwsA(conflito(CodigoErro.aulaInativa)),
      );
    });

    test('professor de outra aula e aluno recebem 403; nada muda', () async {
      repo.aula = aulaDe(idProfessor: professor.id);
      await expectLater(cancelar(outroProfessor), throwsA(isA<AcessoNegado>()));
      await expectLater(cancelar(aluno), throwsA(isA<AcessoNegado>()));
      expect(repo.ultimoCancelamento, isNull);
      expect(repo.chamadas, isNot(contains('cascata')));
      expect(repo.aula!.status, isTrue);
    });

    test('aluno recebe 403 antes do 404, sem abrir transacao', () async {
      repo.aula = null;
      await expectLater(
        cancelar(aluno, idAula: 99),
        throwsA(isA<AcessoNegado>()),
      );
      expect(repo.chamadas, isEmpty);
      expect(repo.ultimoCancelamento, isNull);
    });

    test('aula inexistente e 404', () async {
      repo.aula = aulaDe();
      await expectLater(
        cancelar(admin, idAula: 99),
        throwsA(isA<AulaNotFoundException>()),
      );
      await expectLater(
        cancelar(professor, idAula: 99),
        throwsA(isA<AulaNotFoundException>()),
      );
      expect(repo.ultimoCancelamento, isNull);
    });

    test(
      'aula realizada: 409 AULA_DATA_PASSADA para admin e professor dono',
      () async {
        final (dia, inicio, fim) = realizadaHoje;
        for (final identidade in [admin, professor]) {
          repo.aula = aulaDe(
            data: dia,
            horaInicio: Duration(hours: inicio),
            horaFim: Duration(hours: fim),
          );
          await expectLater(
            cancelar(identidade),
            throwsA(conflito(CodigoErro.aulaDataPassada)),
          );
        }

        // Fim exatamente agora conta como realizada; de ontem tambem.
        repo.aula = aulaDe(
          data: DateTime(2026, 6, 10),
          horaInicio: const Duration(hours: 11),
          horaFim: const Duration(hours: 12),
        );
        await expectLater(
          cancelar(admin),
          throwsA(conflito(CodigoErro.aulaDataPassada)),
        );
        repo.aula = aulaDe(data: DateTime(2026, 6, 9));
        await expectLater(
          cancelar(professor),
          throwsA(conflito(CodigoErro.aulaDataPassada)),
        );

        expect(repo.ultimoCancelamento, isNull);
        expect(repo.chamadas, isNot(contains('cascata')));
        expect(repo.aula!.status, isTrue);
      },
    );

    test('aula em andamento ainda pode ser cancelada', () async {
      repo.aula = aulaDe(
        data: DateTime(2026, 6, 10),
        horaInicio: const Duration(hours: 11),
        horaFim: const Duration(hours: 13),
      );
      expect((await cancelar(professor)).status, isFalse);
    });

    test('403 vem antes do 409 de aula realizada', () async {
      final (dia, inicio, fim) = realizadaHoje;
      repo.aula = aulaDe(
        idProfessor: professor.id,
        data: dia,
        horaInicio: Duration(hours: inicio),
        horaFim: Duration(hours: fim),
      );
      await expectLater(cancelar(outroProfessor), throwsA(isA<AcessoNegado>()));
    });

    test('ja cancelada devolve o estado atual sem gravar nada', () async {
      final antes = aulaDe(status: false).copyWith(
        idProfessorCancelou: const Value(10),
        dataCancelamento: Value(PgDateTime(DateTime.utc(2026, 6, 1, 15))),
      );
      for (final identidade in [admin, professor]) {
        repo.aula = antes;
        repo.chamadas.clear();
        final aula = await cancelar(identidade);
        expect(aula, antes);
        expect(repo.chamadas, ['inicio', 'buscarParaAtualizar', 'fim']);
      }
      expect(repo.ultimoCancelamento, isNull);

      // Ja cancelada e realizada: continua devolvendo o estado, sem 409.
      repo.aula = antes.copyWith(data: PgDate(year: 2026, month: 6, day: 9));
      expect((await cancelar(admin)).status, isFalse);

      // Professor de outra aula recebe 403 mesmo com a aula ja cancelada.
      await expectLater(cancelar(outroProfessor), throwsA(isA<AcessoNegado>()));
    });
  });

  group('listarAgendados', () {
    Future<({List<AgendadoDaAula> itens, int total})> listar(
      Identidade identidade, {
      int idAula = 1,
    }) => service.listarAgendados(identidade, idAula, limit: 5, offset: 10);

    const itens = [
      AgendadoDaAula(
        idAgendamento: 3,
        idAluno: 40,
        nomeAluno: 'Ana',
        status: 'presente',
      ),
      AgendadoDaAula(
        idAgendamento: 1,
        idAluno: 41,
        nomeAluno: 'Bia',
        status: 'agendado',
      ),
    ];

    test('admin ve de qualquer aula; repassa a pagina e o total', () async {
      repo.aula = aulaDe(idProfessor: 20);
      repo.agendados = itens;
      final pagina = await listar(admin);
      expect(pagina.itens, itens);
      expect(pagina.total, 32);
      expect(repo.paginaAgendados, {'idAula': 1, 'limit': 5, 'offset': 10});
    });

    test('professor dono ve os agendados da propria aula', () async {
      repo.aula = aulaDe(idProfessor: professor.id);
      repo.agendados = itens;
      expect((await listar(professor)).itens, itens);
    });

    test('professor de outra aula e aluno recebem 403', () async {
      repo.aula = aulaDe(idProfessor: professor.id);
      await expectLater(listar(outroProfessor), throwsA(isA<AcessoNegado>()));
      await expectLater(listar(aluno), throwsA(isA<AcessoNegado>()));
      expect(repo.chamadas, isNot(contains('listarAgendados')));
      expect(repo.chamadas, isNot(contains('contarAgendados')));
    });

    test('aula inexistente e 404 para admin e professor', () async {
      repo.aula = aulaDe();
      for (final quem in [admin, professor, outroProfessor]) {
        await expectLater(
          listar(quem, idAula: 99),
          throwsA(isA<AulaNotFoundException>()),
        );
      }
      expect(repo.chamadas, isNot(contains('listarAgendados')));
    });

    test('ordem: aluno 403 antes do 404; 404 antes do 403 de outro '
        'professor', () async {
      repo.aula = null;
      await expectLater(
        listar(aluno, idAula: 99),
        throwsA(isA<AcessoNegado>()),
      );
      await expectLater(
        listar(outroProfessor, idAula: 99),
        throwsA(isA<AulaNotFoundException>()),
      );
    });

    test('aula cancelada tambem lista', () async {
      repo.aula = aulaDe(status: false);
      repo.agendados = [itens.first];
      expect((await listar(admin)).itens, [itens.first]);
      expect((await listar(professor)).itens, [itens.first]);
    });
  });

  group('vagasOcupadas', () {
    test('todos os perfis leem; aula sem ocupacao vem com 0', () async {
      repo.ocupacao = {1: 4};
      for (final quem in [admin, professor, aluno]) {
        expect(await service.vagasOcupadas(quem, [1, 2]), {1: 4, 2: 0});
      }
      expect(repo.idsOcupacaoPedidos, [1, 2]);
      expect(await service.vagasOcupadas(admin, []), isEmpty);
    });
  });
}
