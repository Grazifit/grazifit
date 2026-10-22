import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'package:grazifit_backend/config/config.dart';
import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/auth/auth_controller.dart';
import 'package:grazifit_backend/features/auth/auth_repository.dart';
import 'package:grazifit_backend/features/auth/auth_service.dart';
import 'package:grazifit_backend/features/auth/criptografia.dart';
import 'package:grazifit_backend/features/auth/token_service.dart';
import 'package:grazifit_backend/features/pessoas/admin/admin_controller.dart';
import 'package:grazifit_backend/features/pessoas/admin/admin_repository.dart';
import 'package:grazifit_backend/features/pessoas/admin/admin_service.dart';
import 'package:grazifit_backend/features/pessoas/aluno/aluno_controller.dart';
import 'package:grazifit_backend/features/pessoas/aluno/aluno_repository.dart';
import 'package:grazifit_backend/features/pessoas/aluno/aluno_service.dart';
import 'package:grazifit_backend/shared/middleware/error_handler.dart';
import 'package:grazifit_backend/shared/middleware/identidade_middleware.dart';
import 'package:grazifit_backend/shared/middleware/registro_requisicoes.dart';
import 'package:grazifit_backend/features/pessoas/professor/professor_controller.dart';
import 'package:grazifit_backend/features/pessoas/professor/professor_repository.dart';
import 'package:grazifit_backend/features/pessoas/professor/professor_service.dart';
import 'package:grazifit_backend/shared/middleware/cors_middleware.dart';

void main() async {
  final config = Config.doAmbiente();
  final senhaHasher = SenhaHasher(pepperBase64: config.senhaPepper);
  configurarCriptografia(senhaHasher);
  final tokens = TokenService(chaveBase64: config.tokenSigningKey);
  final db = GraziDatabase.fromUrl(config.databaseUrl);

  final authRepository = AuthRepository(db);
  final authService = AuthService(authRepository, senhaHasher, tokens);
  final authController = AuthController(authService);

  final adminRepository = AdminRepository(db);
  final adminService = AdminService(adminRepository, senhaHasher);
  final adminController = AdminController(adminService);

  final alunoRepository = AlunoRepository(db);
  final alunoService = AlunoService(
    alunoRepository,
    hash: senhaHasher.gerarHash,
  );
  final alunoController = AlunoController(alunoService);

  final professorRepository = ProfessorRepository(db);
  final professorService = ProfessorService(professorRepository, senhaHasher);
  final professorController = ProfessorController(professorService);

  final rootRouter = Router()
    ..get('/health', (Request _) => _health(db))
    ..mount('/', authController.router.call)
    ..mount('/', adminController.router.call)
    ..mount('/', alunoController.router.call)
    ..mount('/', professorController.router.call);

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsMiddleware(config.corsOrigin))
      .addMiddleware(registroRequisicoes())
      .addMiddleware(errorHandler())
      .addMiddleware(identidadeMiddleware(tokens, authRepository))
      .addHandler(rootRouter.call);

  final server = await io.serve(handler, config.host, config.port);
  print('Servidor rodando em http://${server.address.host}:${server.port}');
}

/// `GET /health`: rota de infraestrutura, consumida pelo healthcheck do
/// compose e nao pelo app.
///
/// Corpo minimo e fixo: nao revela versao, causa da falha nem detalhe da
/// conexao. Sem autenticacao porque nao expoe dado nenhum.
Future<Response> _health(GraziDatabase db) async {
  final disponivel = await _bancoDisponivel(db);

  return Response(
    disponivel ? 200 : 503,
    body: jsonEncode({'status': disponivel ? 'ok' : 'indisponivel'}),
    headers: {'Content-Type': 'application/json'},
  );
}

/// `SELECT 1` com prazo curto. Qualquer falha conta como indisponivel; o
/// erro nao e registrado nem devolvido porque pode trazer host e usuario
/// da conexao.
Future<bool> _bancoDisponivel(GraziDatabase db) async {
  try {
    await db.customSelect('SELECT 1').get().timeout(const Duration(seconds: 2));
    return true;
  } catch (_) {
    return false;
  }
}
