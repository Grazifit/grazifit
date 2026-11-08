import 'package:drift_postgres/drift_postgres.dart' show PgDate;
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
    return buscarPorId(idAula);
  }

  @override
  Future<T> transacao<T>(Future<T> Function() acao) async {
    emTransacao = true;
    try {
      return await acao();
    } finally {
      emTransacao = false;
    }
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

  @override
  Future<bool> professorAtivoExiste(int idProfessor) async =>
      professoresAtivos.contains(idProfessor);
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
  late AulaService service;

  setUp(() {
    repo = _RepositorioFalso();
    service = AulaService(repo, agora: () => agora);
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

    test('admin pode criar em data passada do ano de vigencia', () async {
      final aula = await criar(data: DateTime(2026, 1, 1));
      expect(aula.data, PgDate(year: 2026, month: 1, day: 1));
    });

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

    test('professor nao move para data passada; admin pode', () async {
      repo.aula = aulaDe();
      await expectLater(
        atualizar(professor, data: DateTime(2026, 6, 9)),
        throwsA(invalido('data')),
      );
      final aula = await atualizar(admin, data: DateTime(2026, 6, 9));
      expect(aula.data, PgDate(year: 2026, month: 6, day: 9));
    });

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
            AulaService(repo, agora: () => agora).criar(
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
        await criarCom(DateTime(2026, 12, 31, 23, 59), DateTime(2026, 12, 31));
      });

      test('admin pode ajustar horario passado no ano de vigencia', () async {
        repo.aula = aulaDe(
          data: DateTime(2026, 6, 10),
          horaInicio: const Duration(hours: 13),
          horaFim: const Duration(hours: 14),
        );
        final aula = await atualizar(
          admin,
          horaInicio: const Duration(hours: 9),
        );
        expect(aula.horaInicio, pg.Time(9));
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
}
