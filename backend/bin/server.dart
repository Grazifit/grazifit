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
  final alunoService = AlunoService(alunoRepository);
  final alunoController = AlunoController(alunoService);

  final rootRouter = Router()
    ..mount('/', authController.router.call)
    ..mount('/', adminController.router.call)
    ..mount('/', alunoController.router.call);

  final handler = const Pipeline()
      .addMiddleware(registroRequisicoes())
      .addMiddleware(errorHandler())
      .addMiddleware(identidadeMiddleware(tokens, authRepository))
      .addHandler(rootRouter.call);

  final server = await io.serve(handler, config.host, config.port);
  print('Servidor rodando em http://${server.address.host}:${server.port}');
}
