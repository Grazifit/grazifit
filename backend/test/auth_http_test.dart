import 'dart:async';
import 'dart:convert';

import 'package:grazifit_backend/features/auth/auth_controller.dart';
import 'package:grazifit_backend/features/auth/auth_repository.dart';
import 'package:grazifit_backend/features/auth/auth_service.dart';
import 'package:grazifit_backend/features/auth/criptografia.dart';
import 'package:grazifit_backend/features/auth/protecao_login.dart';
import 'package:grazifit_backend/features/auth/token_service.dart';
import 'package:grazifit_backend/shared/autorizacao/identidade.dart';
import 'package:grazifit_backend/shared/middleware/identidade_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

class _Repo implements AuthRepository {
  bool ativa = true;

  @override
  Future<List<ContaAutenticacao>> buscarPorEmail(String email) async => [
    const ContaAutenticacao(
      identidade: Identidade(id: 1, papel: Papel.admin),
      nome: 'Admin',
      senhaHash: 'hash:correta',
      ativa: true,
    ),
  ];

  @override
  Future<bool> contaAtiva(Identidade identidade) async => ativa;
}

class _Hasher implements SenhaHasher {
  @override
  String gerarHash(String senha) => 'hash:$senha';

  @override
  bool verificar({required String senha, required String hashArmazenado}) =>
      hashArmazenado == gerarHash(senha);
}

class _RepoLenta extends _Repo {
  final liberacao = Completer<void>();

  @override
  Future<List<ContaAutenticacao>> buscarPorEmail(String email) async {
    await liberacao.future;
    return super.buscarPorEmail(email);
  }
}

void main() {
  final repo = _Repo();
  final tokens = TokenService(
    chaveBase64: base64Encode(List<int>.generate(32, (i) => i)),
  );
  final auth = AuthController(AuthService(repo, _Hasher(), tokens));
  final router = Router()
    ..mount('/', auth.router.call)
    ..get('/protegida', (Request request) {
      final identidade = identidadeDaRequisicao(request)!;
      return Response.ok('${identidade.papel.name}:${identidade.id}');
    });
  final handler = const Pipeline()
      .addMiddleware(identidadeMiddleware(tokens, repo))
      .addHandler(router.call);

  test('login emite token que identifica a chamada protegida', () async {
    final login = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/auth/login'),
        body: jsonEncode({'email': 'admin@exemplo.com', 'senha': 'correta'}),
      ),
    );
    expect(login.statusCode, 200);
    final json = jsonDecode(await login.readAsString()) as Map<String, dynamic>;
    expect(json['token_type'], 'Bearer');
    expect(json['expires_in'], 3600);
    expect((json['usuario'] as Map<String, dynamic>)['papel'], 'admin');

    final protegida = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/protegida'),
        headers: {'Authorization': 'Bearer ${json['access_token']}'},
      ),
    );
    expect(protegida.statusCode, 200);
    expect(await protegida.readAsString(), 'admin:1');

    repo.ativa = false;
    final desativada = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/protegida'),
        headers: {'Authorization': 'Bearer ${json['access_token']}'},
      ),
    );
    expect(desativada.statusCode, 401);
  });

  test('login errado e rota sem token retornam envelope', () async {
    repo.ativa = true;
    final login = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/auth/login'),
        body: jsonEncode({'email': 'admin@exemplo.com', 'senha': 'errada'}),
      ),
    );
    expect(login.statusCode, 401);
    final erroLogin =
        jsonDecode(await login.readAsString()) as Map<String, dynamic>;
    expect(erroLogin['codigo'], 'CREDENCIAIS_INVALIDAS');

    final protegida = await handler(
      Request('GET', Uri.parse('http://localhost/protegida')),
    );
    expect(protegida.statusCode, 401);
    final erroToken =
        jsonDecode(await protegida.readAsString()) as Map<String, dynamic>;
    expect(erroToken['codigo'], 'TOKEN_INVALIDO');
  });

  test(
    'login retorna 429 e Retry-After sem confiar em X-Forwarded-For',
    () async {
      final protecao = ProtecaoLogin(
        maxTentativasIp: 2,
        maxTentativasConta: 20,
        inicioBackoff: 20,
      );
      final controller = AuthController(
        AuthService(_Repo(), _Hasher(), tokens),
        protecao: protecao,
      );
      final protegido = controller.router.call;

      Future<Response> tentar(String ipFalso) => protegido(
        Request(
          'POST',
          Uri.parse('http://localhost/auth/login'),
          headers: {'X-Forwarded-For': ipFalso},
          body: jsonEncode({'email': 'admin@exemplo.com', 'senha': 'errada'}),
        ),
      );

      expect((await tentar('192.0.2.1')).statusCode, 401);
      expect((await tentar('192.0.2.2')).statusCode, 401);
      final limitada = await tentar('192.0.2.3');
      expect(limitada.statusCode, 429);
      expect(limitada.headers['retry-after'], '900');
      final erro =
          jsonDecode(await limitada.readAsString()) as Map<String, dynamic>;
      expect(erro['codigo'], 'MUITAS_TENTATIVAS');
    },
  );

  test('saturacao global rejeita sem iniciar segunda verificacao', () async {
    final repoLenta = _RepoLenta();
    final controller = AuthController(
      AuthService(repoLenta, _Hasher(), tokens),
      protecao: ProtecaoLogin(maxArgon2EmAndamento: 1),
    );
    Future<Response> tentar() => controller.router.call(
      Request(
        'POST',
        Uri.parse('http://localhost/auth/login'),
        body: jsonEncode({'email': 'admin@exemplo.com', 'senha': 'correta'}),
      ),
    );

    final primeira = tentar();
    final segunda = await tentar();
    expect(segunda.statusCode, 429);
    expect(segunda.headers['retry-after'], '1');
    repoLenta.liberacao.complete();
    expect((await primeira).statusCode, 200);
  });

  test('bloqueio permanente nao anuncia Retry-After', () async {
    final controller = AuthController(
      AuthService(_Repo(), _Hasher(), tokens),
      protecao: ProtecaoLogin(maxTentativasIp: 1, maxInfracoesIp: 1),
    );
    Future<Response> tentar() => controller.router.call(
      Request(
        'POST',
        Uri.parse('http://localhost/auth/login'),
        body: jsonEncode({'email': 'admin@exemplo.com', 'senha': 'errada'}),
      ),
    );

    expect((await tentar()).statusCode, 401);
    final bloqueada = await tentar();
    expect(bloqueada.statusCode, 429);
    expect(bloqueada.headers.containsKey('retry-after'), isFalse);
    expect((await tentar()).statusCode, 429);
  });
}
