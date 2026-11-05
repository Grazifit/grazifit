@Timeout(Duration(minutes: 2))
library;

import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/pessoas/professor/professor_repository.dart';
import 'package:test/test.dart';

void main() {
  late GraziDatabase db;
  late ProfessorRepository repository;

  const emailUm = 'crud.professor.1@exemplo.test';
  const emailDois = 'crud.professor.2@exemplo.test';

  setUpAll(() async {
    db = GraziDatabase.doAmbiente();
    repository = ProfessorRepository(db);
    await db.customSelect('SELECT 1').getSingle();
    await db.customStatement(
      "DELETE FROM professor WHERE email IN ('$emailUm', '$emailDois')",
    );
  });

  tearDownAll(() async {
    await db.customStatement(
      "DELETE FROM professor WHERE email IN ('$emailUm', '$emailDois')",
    );
    await db.close();
  });

  test('create, read, update e delete persistem no PostgreSQL', () async {
    final criado = await repository.create(
      cpf: '52998224725',
      senhaHash: 'hash-integracao',
      nome: 'Professor Integracao',
      telefone: '11999998888',
      email: emailUm,
    );
    expect(criado.idProfessor, greaterThan(0));
    expect(await repository.cpfEmUso('52998224725'), isTrue);
    expect(await repository.emailEmUso(emailUm), isTrue);

    final encontrado = await repository.buscarPorId(criado.idProfessor);
    expect(encontrado?.nome, 'Professor Integracao');

    final atualizado = await repository.atualizar(
      idProfessor: criado.idProfessor,
      nome: 'Professor Atualizado',
      email: emailDois,
      status: false,
    );
    expect(atualizado?.nome, 'Professor Atualizado');
    expect(atualizado?.email, emailDois);
    expect(atualizado?.status, isFalse);
    expect(
      await repository.emailEmUso(
        emailDois,
        ignorarIdProfessor: criado.idProfessor,
      ),
      isFalse,
    );

    expect(await repository.deletar(criado.idProfessor), isTrue);
    expect(await repository.buscarPorId(criado.idProfessor), isNull);
    expect(await repository.deletar(criado.idProfessor), isFalse);
    expect(
      await repository.atualizar(idProfessor: criado.idProfessor, nome: 'X'),
      isNull,
    );
  });
}
