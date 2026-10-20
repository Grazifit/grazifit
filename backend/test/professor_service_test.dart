import 'dart:convert';

import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/auth/criptografia.dart';
import 'package:grazifit_backend/features/pessoas/professor/professor_repository.dart';
import 'package:grazifit_backend/features/pessoas/professor/professor_service.dart';
import 'package:grazifit_backend/shared/erros/professor_exception.dart';
import 'package:grazifit_backend/shared/autorizacao/identidade.dart';
import 'package:shared/erros/codigo_erro.dart';
import 'package:test/test.dart';

class _RepositorioFalso implements ProfessorRepository {
  ProfessorData? registro;
  bool cpfOcupado = false;
  bool emailOcupado = false;
  String? emailConsultado;
  int? idIgnorado;

  @override
  Future<ProfessorData> create({
    required String cpf,
    required String senhaHash,
    required String nome,
    required String telefone,
    required String email,
    int? idAdminCriador,
  }) async => registro = ProfessorData(
    idProfessor: 1,
    idAdminCriador: idAdminCriador,
    cpf: cpf,
    senhaHash: senhaHash,
    nome: nome,
    telefone: telefone,
    email: email,
    status: true,
  );

  @override
  Future<ProfessorData?> buscarPorId(int idProfessor) async =>
      registro?.idProfessor == idProfessor ? registro : null;

  @override
  Future<ProfessorData?> atualizar({
    required int idProfessor,
    String? nome,
    String? email,
    String? telefone,
    String? senhaHash,
    bool? status,
  }) async {
    final anterior = await buscarPorId(idProfessor);
    if (anterior == null) return null;
    return registro = ProfessorData(
      idProfessor: anterior.idProfessor,
      idAdminCriador: anterior.idAdminCriador,
      cpf: anterior.cpf,
      senhaHash: senhaHash ?? anterior.senhaHash,
      nome: nome ?? anterior.nome,
      telefone: telefone ?? anterior.telefone,
      email: email ?? anterior.email,
      status: status ?? anterior.status,
    );
  }

  @override
  Future<bool> deletar(int idProfessor) async {
    if (registro?.idProfessor != idProfessor) return false;
    registro = null;
    return true;
  }

  @override
  Future<bool> cpfEmUso(String cpf) async => cpfOcupado;

  @override
  Future<bool> emailEmUso(String email, {int? ignorarIdProfessor}) async {
    emailConsultado = email;
    idIgnorado = ignorarIdProfessor;
    return emailOcupado;
  }
}

void main() {
  const admin = Identidade(id: 7, papel: Papel.admin);
  const aluno = Identidade(id: 8, papel: Papel.aluno);
  late _RepositorioFalso repository;
  late SenhaHasher hasher;
  late ProfessorService service;

  setUp(() {
    repository = _RepositorioFalso();
    hasher = SenhaHasher(
      pepperBase64: base64Encode(List<int>.generate(32, (i) => i)),
    );
    service = ProfessorService(repository, hasher);
  });

  test('criar normaliza dados e gera hash verificavel', () async {
    final professor = await service.criar(
      identidade: admin,
      cpf: '529.982.247-25',
      senha: 'senha123',
      nome: '  Professora Teste  ',
      telefone: ' 11999998888 ',
      email: ' PROFESSORA@EXEMPLO.COM ',
    );

    expect(professor.cpf, '52998224725');
    expect(professor.nome, 'Professora Teste');
    expect(professor.telefone, '11999998888');
    expect(professor.email, 'professora@exemplo.com');
    expect(professor.idAdminCriador, 7);
    expect(
      hasher.verificar(senha: 'senha123', hashArmazenado: professor.senhaHash),
      isTrue,
    );
  });

  test('criar rejeita CPF, email e conflitos antes de inserir', () async {
    Future<void> criar({
      String cpf = '52998224725',
      String email = 'p@exemplo.com',
    }) => service.criar(
      identidade: admin,
      cpf: cpf,
      senha: 'senha123',
      nome: 'Professora',
      telefone: '11999998888',
      email: email,
    );

    await expectLater(
      () => criar(cpf: '11111111111'),
      throwsA(
        isA<ProfessorValidationException>().having(
          (e) => e.codigo,
          'codigo',
          CodigoErro.cpfInvalido,
        ),
      ),
    );
    await expectLater(
      () => criar(email: 'invalido'),
      throwsA(isA<ProfessorValidationException>()),
    );

    repository.cpfOcupado = true;
    await expectLater(criar, throwsA(isA<ProfessorConflictException>()));
    repository.cpfOcupado = false;
    repository.emailOcupado = true;
    await expectLater(criar, throwsA(isA<ProfessorConflictException>()));
    expect(repository.registro, isNull);
  });

  test('buscar, atualizar e deletar cobrem sucesso e id inexistente', () async {
    final criado = await service.criar(
      identidade: admin,
      cpf: '52998224725',
      senha: 'senha123',
      nome: 'Professor',
      telefone: '11999998888',
      email: 'professor@exemplo.com',
    );

    expect(
      (await service.buscarPorId(admin, criado.idProfessor)).nome,
      'Professor',
    );
    final atualizado = await service.atualizar(
      identidade: admin,
      idProfessor: criado.idProfessor,
      nome: '  Professor Atualizado ',
      email: ' NOVO@EXEMPLO.COM ',
      senha: 'novaSenha',
      status: false,
    );
    expect(atualizado.nome, 'Professor Atualizado');
    expect(atualizado.email, 'novo@exemplo.com');
    expect(atualizado.status, isFalse);
    expect(repository.idIgnorado, criado.idProfessor);
    expect(
      hasher.verificar(
        senha: 'novaSenha',
        hashArmazenado: atualizado.senhaHash,
      ),
      isTrue,
    );

    await service.deletar(admin, criado.idProfessor);
    await expectLater(
      () => service.buscarPorId(admin, criado.idProfessor),
      throwsA(isA<ProfessorNotFoundException>()),
    );
    await expectLater(
      () => service.atualizar(
        identidade: admin,
        idProfessor: criado.idProfessor,
        nome: 'Ninguem',
      ),
      throwsA(isA<ProfessorNotFoundException>()),
    );
    await expectLater(
      () => service.deletar(admin, criado.idProfessor),
      throwsA(isA<ProfessorNotFoundException>()),
    );
  });

  test('somente administrador pode executar o CRUD', () async {
    await expectLater(
      () => service.criar(
        identidade: aluno,
        cpf: '52998224725',
        senha: 'senha123',
        nome: 'Professor',
        telefone: '11999998888',
        email: 'professor@exemplo.com',
      ),
      throwsA(isA<AcessoNegado>()),
    );
    await expectLater(
      () => service.buscarPorId(aluno, 1),
      throwsA(isA<AcessoNegado>()),
    );
  });
}
