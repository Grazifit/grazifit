import 'package:grazifit_backend/features/avaliacoes/avaliacao_exception.dart';
import 'package:grazifit_backend/features/avaliacoes/avaliacao_repository.dart';
import 'package:grazifit_backend/features/avaliacoes/avaliacao_service.dart';
import 'package:grazifit_backend/shared/autorizacao/identidade.dart';
import 'package:test/test.dart';

// Qualquer acesso ao banco neste teste falha: entradas rejeitadas nao devem gravar.
class _RepositorySemAcesso implements AvaliacaoRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Banco nao deveria ser acessado');
}

void main() {
  final service = AvaliacaoService(_RepositorySemAcesso());
  const aluno = Identidade(id: 1, papel: Papel.aluno);
  test('rejeita medidas nao finitas, limites e precisao antes de gravar', () {
    for (final peso in [
      double.nan,
      double.infinity,
      -1.0,
      0.0,
      500.0,
      70.001,
    ]) {
      expect(
        () => service.salvarHoje(aluno, 1, peso: peso, altura: 1.75),
        throwsA(isA<AvaliacaoException>()),
      );
    }
    for (final altura in [double.nan, double.infinity, -1.0, 0.0, 3.0, 1.751]) {
      expect(
        () => service.salvarHoje(aluno, 1, peso: 70, altura: altura),
        throwsA(isA<AvaliacaoException>()),
      );
    }
  });
  test('permissoes sao exigidas pelo service sem depender do controller', () {
    for (final identidade in [
      aluno,
      const Identidade(id: 1, papel: Papel.professor),
    ]) {
      expect(
        () => service.salvarHoje(identidade, 2, peso: 70, altura: 1.75),
        throwsA(isA<AcessoNegado>()),
      );
      expect(() => service.atual(identidade, 2), throwsA(isA<AcessoNegado>()));
      expect(() => service.listar(identidade, 2), throwsA(isA<AcessoNegado>()));
    }
  });
  test('paginacao e observacao invalidas nao acessam banco', () {
    expect(
      () => service.listar(aluno, 1, limit: 0),
      throwsA(isA<AvaliacaoException>()),
    );
    expect(
      () => service.listar(aluno, 1, limit: 101),
      throwsA(isA<AvaliacaoException>()),
    );
    expect(
      () => service.listar(aluno, 1, offset: -1),
      throwsA(isA<AvaliacaoException>()),
    );
    expect(
      () => service.salvarHoje(
        aluno,
        1,
        peso: 70,
        altura: 1.75,
        observacao: 'x' * 2001,
      ),
      throwsA(isA<AvaliacaoException>()),
    );
  });
}
