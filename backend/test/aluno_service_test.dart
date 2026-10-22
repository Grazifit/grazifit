import 'package:drift_postgres/drift_postgres.dart' show PgDate;
import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/shared/erros/aluno_exception.dart';
import 'package:grazifit_backend/features/pessoas/aluno/aluno_repository.dart';
import 'package:grazifit_backend/features/pessoas/aluno/aluno_service.dart';
import 'package:grazifit_backend/shared/autorizacao/identidade.dart';
import 'package:shared/erros/codigo_erro.dart';
import 'package:test/test.dart';

class _RepositorioFalso implements AlunoRepository {
  bool cpfJaExiste;
  bool emailJaExiste;

  /// O que o service passou para `create`, para inspecao depois.
  Map<String, Object?>? recebido;

  _RepositorioFalso({this.cpfJaExiste = false, this.emailJaExiste = false});

  @override
  Future<bool> cpfEmUso(String cpf) async => cpfJaExiste;

  @override
  Future<bool> emailEmUso(String email, {int? excetoIdAluno}) async {
    emailChecadoExceto = excetoIdAluno;
    return emailJaExiste;
  }

  @override
  Future<AlunoData> create({
    required String cpf,
    required String senhaHash,
    required String nome,
    required DateTime dataNascimento,
    required String telefone,
    required String email,
    int? idAdminCriador,
    int? idEndereco,
    String? restricaoMedica,
    String? observacaoSaude,
  }) async {
    recebido = {
      'cpf': cpf,
      'senhaHash': senhaHash,
      'nome': nome,
      'telefone': telefone,
      'email': email,
      'idAdminCriador': idAdminCriador,
      'restricaoMedica': restricaoMedica,
      'observacaoSaude': observacaoSaude,
    };

    return AlunoData(
      idAluno: 1,
      cpf: cpf,
      senhaHash: senhaHash,
      nome: nome,
      dataNascimento: PgDate.fromDateTime(dataNascimento),
      telefone: telefone,
      email: email,
      restricaoMedica: restricaoMedica,
      observacaoSaude: observacaoSaude,
      status: true,
      dataCadastro: PgDate.fromDateTime(DateTime.now()),
    );
  }

  /// Alunos que o banco falso "possui", por id.
  final Map<int, AlunoData> existentes = {};

  /// Quantas vezes a busca por id chegou ao repositorio.
  int buscasPorId = 0;

  @override
  Future<AlunoData?> buscarAlunoPorId(int idAluno) async {
    buscasPorId++;
    return existentes[idAluno];
  }

  @override
  Future<List<AlunoData>> buscarAlunos({
    required int limit,
    required int offset,
  }) async => existentes.values.skip(offset).take(limit).toList();

  @override
  Future<int> countAlunos() async => existentes.length;

  /// O `excetoIdAluno` que o service passou na ultima checagem de e-mail.
  int? emailChecadoExceto;

  /// O que o service passou para `atualizar`, para inspecao depois.
  Map<String, Object?>? atualizacaoRecebida;

  @override
  Future<AlunoData?> atualizar(
    int idAluno, {
    String? nome,
    String? telefone,
    String? email,
  }) async {
    atualizacaoRecebida = {'nome': nome, 'telefone': telefone, 'email': email};
    final atual = existentes[idAluno];
    if (atual == null) return null;
    return existentes[idAluno] = atual.copyWith(
      nome: nome ?? atual.nome,
      telefone: telefone ?? atual.telefone,
      email: email ?? atual.email,
    );
  }

  @override
  Future<bool> alterarStatus(int idAluno, {required bool status}) async {
    final atual = existentes[idAluno];
    if (atual == null) return false;
    existentes[idAluno] = atual.copyWith(status: status);
    return true;
  }

  @override
  Future<bool> excluir(int idAluno) async => existentes.remove(idAluno) != null;
}

AlunoData _alunoExistente(int idAluno) => AlunoData(
  idAluno: idAluno,
  cpf: cpfValido,
  senhaHash: 'hash',
  nome: 'Aluno $idAluno',
  dataNascimento: PgDate.fromDateTime(DateTime(1995, 3, 20)),
  telefone: '11999998888',
  email: 'aluno$idAluno@exemplo.com',
  status: true,
  dataCadastro: PgDate.fromDateTime(DateTime.now()),
);

/// Variante que so registra se alguma consulta de unicidade aconteceu.
class _ContaConsultas extends _RepositorioFalso {
  final void Function() aoConsultar;

  _ContaConsultas(this.aoConsultar);

  @override
  Future<bool> cpfEmUso(String cpf) async {
    aoConsultar();
    return false;
  }

  @override
  Future<bool> emailEmUso(String email, {int? excetoIdAluno}) async {
    aoConsultar();
    return false;
  }
}

/// CPFs validos pelo digito verificador, para nao esbarrar em `Validacoes`
/// quando o alvo do teste e outra coisa.
const cpfValido = '52998224725';
const outroCpfValido = '11144477735';
const identidadeAdmin = Identidade(id: 1, papel: Papel.admin);

Future<AlunoData> _criar(
  AlunoService service, {
  String cpf = cpfValido,
  String senha = 'senhaboa1',
  String nome = 'Fulano de Tal',
  DateTime? dataNascimento,
  String telefone = '11999998888',
  String email = 'fulano@exemplo.com',
  String? restricaoMedica,
  String? observacaoSaude,
}) {
  return service.criar(
    identidade: identidadeAdmin,
    cpf: cpf,
    senha: senha,
    nome: nome,
    dataNascimento: dataNascimento ?? DateTime(1995, 3, 20),
    telefone: telefone,
    email: email,
    restricaoMedica: restricaoMedica,
    observacaoSaude: observacaoSaude,
  );
}

/// Hash falso: preserva o formato de cinco campos de `hashPassword`, sem
/// pagar Argon2 nem depender do `.env`. O que estes testes verificam e que
/// o service **nao entrega a senha em claro** ao repository, nao a forca do
/// algoritmo — essa e responsabilidade de `criptografia.dart` e do seu
/// proprio teste.
String _hashFalso(String senha) => '3:16:1:c2FsdA==:${senha.hashCode}';

/// Casa a excecao pelo **codigo e campo** — nunca pela mensagem, que e
/// justamente o que D64 tira do caminho.
Matcher _recusa<T extends AlunoException>(CodigoErro codigo, String campo) {
  return throwsA(
    isA<T>()
        .having((e) => e.codigo, 'codigo', codigo)
        .having((e) => e.campo, 'campo', campo),
  );
}

void main() {
  group('AlunoService — matriz de autorizacao', () {
    const admin = Identidade(id: 10, papel: Papel.admin);
    const alunoDono = Identidade(id: 7, papel: Papel.aluno);
    const outroAluno = Identidade(id: 8, papel: Papel.aluno);
    const professor = Identidade(id: 9, papel: Papel.professor);

    test('aluno acessa e atualiza somente o proprio cadastro', () async {
      final repo = _RepositorioFalso()..existentes[7] = _alunoExistente(7);
      final service = AlunoService(repo, hash: _hashFalso);

      expect(
        (await service.buscarAlunoPorId(7, identidade: alunoDono)).idAluno,
        7,
      );
      expect(
        (await service.atualizar(
          7,
          identidade: alunoDono,
          nome: 'Proprio',
        )).nome,
        'Proprio',
      );
    });

    for (final identidade in [outroAluno, professor]) {
      test(
        '${identidade.papel.name} recebe acesso negado antes da busca',
        () async {
          final repo = _RepositorioFalso();
          final service = AlunoService(repo, hash: _hashFalso);

          await expectLater(
            () => service.buscarAlunoPorId(0, identidade: identidade),
            throwsA(isA<AcessoNegado>()),
          );
          await expectLater(
            () => service.atualizar(0, identidade: identidade, nome: 'X'),
            throwsA(isA<AcessoNegado>()),
          );
          expect(repo.buscasPorId, 0);
        },
      );
    }

    for (final identidade in [alunoDono, professor]) {
      test(
        '${identidade.papel.name} nao lista, altera status nem exclui',
        () async {
          final repo = _RepositorioFalso()..existentes[7] = _alunoExistente(7);
          final service = AlunoService(repo, hash: _hashFalso);

          await expectLater(
            () => service.buscarAlunos(
              identidade: identidade,
              limit: 20,
              offset: 0,
            ),
            throwsA(isA<AcessoNegado>()),
          );
          await expectLater(
            () =>
                service.alterarStatus(0, identidade: identidade, status: false),
            throwsA(isA<AcessoNegado>()),
          );
          await expectLater(
            () => service.excluir(0, identidade: identidade),
            throwsA(isA<AcessoNegado>()),
          );
          expect(repo.buscasPorId, 0);
          expect(repo.existentes, contains(7));
        },
      );
    }

    test('admin preserva acesso completo', () async {
      final repo = _RepositorioFalso()..existentes[7] = _alunoExistente(7);
      final service = AlunoService(repo, hash: _hashFalso);

      expect((await service.buscarAlunoPorId(7, identidade: admin)).idAluno, 7);
      expect(
        (await service.buscarAlunos(
          identidade: admin,
          limit: 20,
          offset: 0,
        )).total,
        1,
      );
      await service.alterarStatus(7, identidade: admin, status: false);
      await service.excluir(7, identidade: admin);
      expect(repo.existentes, isEmpty);
    });
  });

  test('somente admin pode cadastrar aluno', () async {
    final repo = _RepositorioFalso();
    final service = AlunoService(repo, hash: _hashFalso);

    await expectLater(
      () => service.criar(
        identidade: const Identidade(id: 2, papel: Papel.professor),
        cpf: cpfValido,
        senha: 'senhaboa1',
        nome: 'Fulano de Tal',
        dataNascimento: DateTime(1995, 3, 20),
        telefone: '11999998888',
        email: 'fulano@exemplo.com',
      ),
      throwsA(isA<AcessoNegado>()),
    );
    expect(repo.recebido, isNull);
  });

  group('AlunoService.criar — recusa antes de tocar o banco', () {
    test('CPF com digito verificador errado', () {
      final repo = _RepositorioFalso();

      expect(
        () => _criar(AlunoService(repo, hash: _hashFalso), cpf: '11111111111'),
        _recusa<AlunoValidationException>(CodigoErro.cpfInvalido, 'cpf'),
      );
    });

    test('e-mail fora de formato', () {
      final repo = _RepositorioFalso();

      expect(
        () => _criar(
          AlunoService(repo, hash: _hashFalso),
          email: 'fulano@@exemplo',
        ),
        _recusa<AlunoValidationException>(CodigoErro.emailInvalido, 'email'),
      );
    });

    test('nascer hoje nao passa: o CHECK e estrito, nao inclusivo', () {
      final repo = _RepositorioFalso();

      expect(
        () => _criar(
          AlunoService(repo, hash: _hashFalso),
          dataNascimento: DateTime.now(),
        ),
        _recusa<AlunoValidationException>(
          CodigoErro.dataNascimentoInvalida,
          'data_nascimento',
        ),
      );
    });

    test('data de nascimento no futuro', () {
      final repo = _RepositorioFalso();

      expect(
        () => _criar(
          AlunoService(repo, hash: _hashFalso),
          dataNascimento: DateTime.now().add(const Duration(days: 1)),
        ),
        _recusa<AlunoValidationException>(
          CodigoErro.dataNascimentoInvalida,
          'data_nascimento',
        ),
      );
    });

    test('formato antes da unicidade: nao consulta o banco a toa', () async {
      var consultou = false;
      final repo = _ContaConsultas(() => consultou = true);

      await expectLater(
        () => _criar(AlunoService(repo, hash: _hashFalso), cpf: '11111111111'),
        throwsA(isA<AlunoValidationException>()),
      );
      expect(consultou, isFalse);
    });
  });

  group('AlunoService.criar — conflito', () {
    test('CPF ja cadastrado', () {
      final repo = _RepositorioFalso(cpfJaExiste: true);

      expect(
        () => _criar(AlunoService(repo, hash: _hashFalso)),
        _recusa<AlunoConflictException>(CodigoErro.cpfEmUso, 'cpf'),
      );
    });

    test('e-mail ja cadastrado, inclusive o de um admin', () {
      final repo = _RepositorioFalso(emailJaExiste: true);

      expect(
        () => _criar(AlunoService(repo, hash: _hashFalso)),
        _recusa<AlunoConflictException>(CodigoErro.emailEmUso, 'email'),
      );
    });

    test('nada e gravado quando ha conflito', () async {
      final repo = _RepositorioFalso(emailJaExiste: true);

      await expectLater(
        () => _criar(AlunoService(repo, hash: _hashFalso)),
        throwsA(isA<AlunoConflictException>()),
      );
      expect(repo.recebido, isNull);
    });
  });

  group('AlunoService.criar — normalizacao', () {
    test('CPF mascarado chega ao repository so com digitos', () async {
      final repo = _RepositorioFalso();

      await _criar(AlunoService(repo, hash: _hashFalso), cpf: '529.982.247-25');

      expect(repo.recebido!['cpf'], cpfValido);
    });

    test('e-mail minusculo e sem espaco; nome e telefone aparados', () async {
      final repo = _RepositorioFalso();

      await _criar(
        AlunoService(repo, hash: _hashFalso),
        email: '  Fulano@Exemplo.COM  ',
        nome: '  Fulano de Tal  ',
        telefone: '  11999998888  ',
      );

      expect(repo.recebido!['email'], 'fulano@exemplo.com');
      expect(repo.recebido!['nome'], 'Fulano de Tal');
      expect(repo.recebido!['telefone'], '11999998888');
    });

    test('campo clinico em branco vira ausencia, nao string vazia', () async {
      final repo = _RepositorioFalso();

      await _criar(
        AlunoService(repo, hash: _hashFalso),
        cpf: outroCpfValido,
        restricaoMedica: '   ',
        observacaoSaude: '',
      );

      expect(repo.recebido!['restricaoMedica'], isNull);
      expect(repo.recebido!['observacaoSaude'], isNull);
    });

    test('a senha nunca chega ao repository em claro', () async {
      final repo = _RepositorioFalso();

      await _criar(AlunoService(repo, hash: _hashFalso), senha: 'senhaboa1');

      final hash = repo.recebido!['senhaHash'] as String;
      expect(hash, isNot(contains('senhaboa1')));
      // Formato de `hashPassword`: iteracoes:memoria:lanes:salt:hash
      expect(hash.split(':'), hasLength(5));
    });
  });

  group('AlunoService.buscarAlunos', () {
    test('devolve a pagina pedida e o total da colecao', () async {
      final repo = _RepositorioFalso();
      for (var id = 1; id <= 5; id++) {
        repo.existentes[id] = _alunoExistente(id);
      }

      final pagina = await AlunoService(
        repo,
        hash: _hashFalso,
      ).buscarAlunos(identidade: identidadeAdmin, limit: 2, offset: 2);

      expect(pagina.itens.map((a) => a.idAluno), [3, 4]);
      expect(pagina.total, 5);
    });

    test('offset alem do fim devolve pagina vazia, total intacto', () async {
      final repo = _RepositorioFalso()..existentes[1] = _alunoExistente(1);

      final pagina = await AlunoService(
        repo,
        hash: _hashFalso,
      ).buscarAlunos(identidade: identidadeAdmin, limit: 20, offset: 40);

      expect(pagina.itens, isEmpty);
      expect(pagina.total, 1);
    });
  });

  group('AlunoService.buscarAlunoPorId', () {
    final naoEncontrado = throwsA(
      isA<AlunoNotFoundException>().having(
        (e) => e.codigo,
        'codigo',
        CodigoErro.registroNaoEncontrado,
      ),
    );

    test('devolve o aluno quando ele existe', () async {
      final repo = _RepositorioFalso()..existentes[7] = _alunoExistente(7);

      final aluno = await AlunoService(
        repo,
        hash: _hashFalso,
      ).buscarAlunoPorId(7, identidade: identidadeAdmin);

      expect(aluno.idAluno, 7);
    });

    test('repositorio devolve null -> REGISTRO_NAO_ENCONTRADO', () {
      final repo = _RepositorioFalso();

      expect(
        () => AlunoService(
          repo,
          hash: _hashFalso,
        ).buscarAlunoPorId(99, identidade: identidadeAdmin),
        naoEncontrado,
      );
    });

    for (final idImpossivel in const [0, -1]) {
      test('id $idImpossivel nem chega ao repositorio', () async {
        final repo = _RepositorioFalso();

        await expectLater(
          () => AlunoService(
            repo,
            hash: _hashFalso,
          ).buscarAlunoPorId(idImpossivel, identidade: identidadeAdmin),
          naoEncontrado,
        );
        expect(repo.buscasPorId, 0);
      });
    }
  });

  group('AlunoService.atualizar', () {
    test('altera so o que veio e normaliza o e-mail', () async {
      final repo = _RepositorioFalso()..existentes[1] = _alunoExistente(1);

      final aluno = await AlunoService(
        repo,
        hash: _hashFalso,
      ).atualizar(1, identidade: identidadeAdmin, email: '  Novo@Exemplo.COM ');

      expect(aluno.email, 'novo@exemplo.com');
      expect(aluno.nome, 'Aluno 1', reason: 'nome nao veio, nao muda');
      expect(repo.atualizacaoRecebida, {
        'nome': null,
        'telefone': null,
        'email': 'novo@exemplo.com',
      });
    });

    test('tira os espacos das pontas de nome e telefone', () async {
      final repo = _RepositorioFalso()..existentes[1] = _alunoExistente(1);

      await AlunoService(repo, hash: _hashFalso).atualizar(
        1,
        identidade: identidadeAdmin,
        nome: '  Novo Nome  ',
        telefone: ' 11911112222 ',
      );

      expect(repo.atualizacaoRecebida, {
        'nome': 'Novo Nome',
        'telefone': '11911112222',
        'email': null,
      });
    });

    test('id inexistente e 404 mesmo com e-mail de outra pessoa', () async {
      // Existencia antes da unicidade: senao viria 409 EMAIL_EM_USO.
      final repo = _RepositorioFalso(emailJaExiste: true);

      await expectLater(
        () => AlunoService(repo, hash: _hashFalso).atualizar(
          99,
          identidade: identidadeAdmin,
          email: 'outro@exemplo.com',
        ),
        throwsA(isA<AlunoNotFoundException>()),
      );
    });

    test('checa unicidade do e-mail excluindo o proprio aluno', () async {
      final repo = _RepositorioFalso()..existentes[1] = _alunoExistente(1);

      await AlunoService(
        repo,
        hash: _hashFalso,
      ).atualizar(1, identidade: identidadeAdmin, email: 'aluno1@exemplo.com');

      expect(repo.emailChecadoExceto, 1);
    });

    test('e-mail de outra pessoa -> EMAIL_EM_USO, sem gravar', () async {
      final repo = _RepositorioFalso(emailJaExiste: true)
        ..existentes[1] = _alunoExistente(1);

      await expectLater(
        () => AlunoService(
          repo,
          hash: _hashFalso,
        ).atualizar(1, identidade: identidadeAdmin, email: 'outro@exemplo.com'),
        _recusa<AlunoConflictException>(CodigoErro.emailEmUso, 'email'),
      );
      expect(repo.atualizacaoRecebida, isNull);
    });

    test('e-mail fora do formato -> EMAIL_INVALIDO, sem gravar', () async {
      final repo = _RepositorioFalso()..existentes[1] = _alunoExistente(1);

      await expectLater(
        () => AlunoService(
          repo,
          hash: _hashFalso,
        ).atualizar(1, identidade: identidadeAdmin, email: 'sem-arroba'),
        _recusa<AlunoValidationException>(CodigoErro.emailInvalido, 'email'),
      );
      expect(repo.atualizacaoRecebida, isNull);
    });

    test('aluno inexistente -> REGISTRO_NAO_ENCONTRADO', () {
      expect(
        () => AlunoService(
          _RepositorioFalso(),
          hash: _hashFalso,
        ).atualizar(99, identidade: identidadeAdmin, nome: 'X'),
        throwsA(isA<AlunoNotFoundException>()),
      );
    });
  });

  group('AlunoService.alterarStatus', () {
    test('inativa sem apagar', () async {
      final repo = _RepositorioFalso()..existentes[1] = _alunoExistente(1);

      await AlunoService(
        repo,
        hash: _hashFalso,
      ).alterarStatus(1, identidade: identidadeAdmin, status: false);

      expect(repo.existentes[1]!.status, isFalse);
    });

    test('reativa', () async {
      final repo = _RepositorioFalso()
        ..existentes[1] = _alunoExistente(1).copyWith(status: false);

      await AlunoService(
        repo,
        hash: _hashFalso,
      ).alterarStatus(1, identidade: identidadeAdmin, status: true);

      expect(repo.existentes[1]!.status, isTrue);
    });

    test('aluno inexistente -> REGISTRO_NAO_ENCONTRADO', () {
      expect(
        () => AlunoService(
          _RepositorioFalso(),
          hash: _hashFalso,
        ).alterarStatus(99, identidade: identidadeAdmin, status: false),
        throwsA(isA<AlunoNotFoundException>()),
      );
    });
  });

  group('AlunoService.excluir', () {
    test('remove o aluno', () async {
      final repo = _RepositorioFalso()..existentes[1] = _alunoExistente(1);

      await AlunoService(
        repo,
        hash: _hashFalso,
      ).excluir(1, identidade: identidadeAdmin);

      expect(repo.existentes, isEmpty);
    });

    for (final id in const [99, 0, -1]) {
      test('id $id -> REGISTRO_NAO_ENCONTRADO', () {
        expect(
          () => AlunoService(
            _RepositorioFalso(),
            hash: _hashFalso,
          ).excluir(id, identidade: identidadeAdmin),
          throwsA(isA<AlunoNotFoundException>()),
        );
      });
    }
  });
}
