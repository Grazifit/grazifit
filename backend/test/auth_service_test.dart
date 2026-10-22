import 'dart:convert';

import 'package:grazifit_backend/features/auth/auth_repository.dart';
import 'package:grazifit_backend/features/auth/auth_service.dart';
import 'package:grazifit_backend/features/auth/criptografia.dart';
import 'package:grazifit_backend/features/auth/token_service.dart';
import 'package:grazifit_backend/shared/autorizacao/identidade.dart';
import 'package:shared/dtos/auth_dto.dart';
import 'package:test/test.dart';

class _ContasFalsas implements AuthRepository {
  List<ContaAutenticacao> contas = [];
  String? emailConsultado;

  @override
  Future<List<ContaAutenticacao>> buscarPorEmail(String email) async {
    emailConsultado = email;
    return contas;
  }

  @override
  Future<bool> contaAtiva(Identidade identidade) async => true;
}

class _SenhaFalsa implements SenhaHasher {
  @override
  String gerarHash(String senha) => 'hash:$senha';

  @override
  bool verificar({required String senha, required String hashArmazenado}) =>
      hashArmazenado == gerarHash(senha);
}

void main() {
  final chave = base64Encode(List<int>.generate(32, (i) => i));
  final tokens = TokenService(chaveBase64: chave);

  test('aceita hash PHC criado pelo mesmo hasher do admin', () async {
    final pepper = base64Encode(List<int>.generate(32, (i) => i + 10));
    final hasher = SenhaHasher(pepperBase64: pepper);
    final repo = _ContasFalsas()
      ..contas = [
        ContaAutenticacao(
          identidade: const Identidade(id: 1, papel: Papel.admin),
          nome: 'Admin',
          senhaHash: hasher.gerarHash('senhaSegura123'),
          ativa: true,
        ),
      ];
    final service = AuthService(repo, hasher, tokens);

    final resposta = await service.login(
      const LoginRequestDto(
        email: 'admin@exemplo.com',
        senha: 'senhaSegura123',
      ),
    );

    expect(resposta.papel, 'admin');
    expect(tokens.validar(resposta.accessToken)?.id, 1);
  });

  test(
    'login normaliza email e emite identidade do perfil encontrado',
    () async {
      final repo = _ContasFalsas()
        ..contas = [
          const ContaAutenticacao(
            identidade: Identidade(id: 3, papel: Papel.professor),
            nome: 'Professora',
            senhaHash: 'hash:senha12345',
            ativa: true,
          ),
        ];
      final service = AuthService(repo, _SenhaFalsa(), tokens);

      final resposta = await service.login(
        const LoginRequestDto(
          email: '  PROFESSORA@EXEMPLO.COM  ',
          senha: 'senha12345',
        ),
      );

      expect(repo.emailConsultado, 'professora@exemplo.com');
      expect(resposta.papel, 'professor');
      expect(resposta.id, 3);
      expect(resposta.toJson(), isNot(contains('senha_hash')));
      expect(tokens.validar(resposta.accessToken)?.papel, Papel.professor);
    },
  );

  test(
    'mesmo erro para senha errada, conta ausente, inativa ou duplicada',
    () async {
      final repo = _ContasFalsas();
      final service = AuthService(repo, _SenhaFalsa(), tokens);
      const entrada = LoginRequestDto(
        email: 'teste@exemplo.com',
        senha: 'senha',
      );
      const conta = ContaAutenticacao(
        identidade: Identidade(id: 1, papel: Papel.admin),
        nome: 'Admin',
        senhaHash: 'hash:outra',
        ativa: true,
      );

      for (final contas in <List<ContaAutenticacao>>[
        [],
        [conta],
        [
          const ContaAutenticacao(
            identidade: Identidade(id: 1, papel: Papel.aluno),
            nome: 'Aluno',
            senhaHash: 'hash:senha',
            ativa: false,
          ),
        ],
        [conta, conta],
      ]) {
        repo.contas = contas;
        await expectLater(
          () => service.login(entrada),
          throwsA(isA<CredenciaisInvalidas>()),
        );
      }
    },
  );
}
