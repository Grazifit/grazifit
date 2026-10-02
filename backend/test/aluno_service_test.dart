import 'package:drift_postgres/drift_postgres.dart' show PgDate;
import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/pessoas/aluno/aluno_exception.dart';
import 'package:grazifit_backend/features/pessoas/aluno/aluno_repository.dart';
import 'package:grazifit_backend/features/pessoas/aluno/aluno_service.dart';
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
  Future<bool> emailEmUso(String email) async => emailJaExiste;

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
}

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
  Future<bool> emailEmUso(String email) async {
    aoConsultar();
    return false;
  }
}

/// CPFs validos pelo digito verificador, para nao esbarrar em `Validacoes`
/// quando o alvo do teste e outra coisa.
const cpfValido = '52998224725';
const outroCpfValido = '11144477735';

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
}
