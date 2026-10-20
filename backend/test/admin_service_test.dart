import 'dart:convert';

import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/auth/criptografia.dart';
import 'package:grazifit_backend/features/pessoas/admin/admin_repository.dart';
import 'package:grazifit_backend/features/pessoas/admin/admin_service.dart';
import 'package:grazifit_backend/shared/autorizacao/identidade.dart';
import 'package:test/test.dart';

class _AdminRepositoryFalso implements AdminRepository {
  AdminData? registro;

  @override
  Future<AdminData> create({
    required String cpf,
    required String nome,
    required String email,
    required String senhaHash,
    String? telefone,
  }) async {
    return registro = AdminData(
      idAdmin: 1,
      cpf: cpf,
      senhaHash: senhaHash,
      nome: nome,
      email: email,
      telefone: telefone,
    );
  }

  @override
  Future<AdminData?> buscarPorId(int idAdmin) async => registro;

  @override
  Future<AdminData> atualizar({
    required int idAdmin,
    String? nome,
    String? email,
    String? telefone,
    String? senhaHash,
  }) async {
    final anterior = registro!;
    return registro = AdminData(
      idAdmin: anterior.idAdmin,
      cpf: anterior.cpf,
      senhaHash: senhaHash ?? anterior.senhaHash,
      nome: nome ?? anterior.nome,
      email: email ?? anterior.email,
      telefone: telefone ?? anterior.telefone,
    );
  }

  @override
  Future<void> deletar(int idAdmin) async {}
}

void main() {
  const admin = Identidade(id: 1, papel: Papel.admin);
  const aluno = Identidade(id: 2, papel: Papel.aluno);
  test('criacao e troca de senha do admin usam o mesmo hasher PHC', () async {
    final pepper = base64Encode(List<int>.generate(32, (i) => i));
    final hasher = SenhaHasher(pepperBase64: pepper);
    final repository = _AdminRepositoryFalso();
    final service = AdminService(repository, hasher);

    final criado = await service.criar(
      identidade: admin,
      cpf: '52998224725',
      senha: 'senhaInicial123',
      nome: 'Admin Teste',
      email: 'admin@exemplo.com',
    );

    expect(criado.senhaHash, startsWith(r'$argon2id$v=19$m=65536,t=3,p=4$'));
    expect(
      hasher.verificar(
        senha: 'senhaInicial123',
        hashArmazenado: criado.senhaHash,
      ),
      isTrue,
    );

    final atualizado = await service.atualizar(
      identidade: admin,
      idAdmin: criado.idAdmin,
      senha: 'senhaNova123',
    );

    expect(atualizado.senhaHash, isNot(criado.senhaHash));
    expect(
      hasher.verificar(
        senha: 'senhaNova123',
        hashArmazenado: atualizado.senhaHash,
      ),
      isTrue,
    );
  });

  test('aluno nao cria administrador', () async {
    final pepper = base64Encode(List<int>.generate(32, (i) => i));
    final repository = _AdminRepositoryFalso();
    final service = AdminService(repository, SenhaHasher(pepperBase64: pepper));

    await expectLater(
      () => service.criar(
        identidade: aluno,
        cpf: '52998224725',
        senha: 'senhaInicial123',
        nome: 'Admin Teste',
        email: 'admin@exemplo.com',
      ),
      throwsA(isA<AcessoNegado>()),
    );
    expect(repository.registro, isNull);
  });
}
