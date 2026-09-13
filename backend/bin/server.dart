import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/pessoas/admin/admin_handler.dart';
import 'package:grazifit_backend/features/pessoas/admin/admin_repository.dart';
import 'package:grazifit_backend/features/pessoas/aluno/aluno_controller.dart';
import 'package:grazifit_backend/features/pessoas/aluno/aluno_repository.dart';
import 'package:grazifit_backend/features/pessoas/aluno/aluno_service.dart';

void main() async {
  final db = GraziDatabase.doAmbiente();

  final adminRepository = AdminRepository(db);
  final adminHandler = AdminHandler(adminRepository);

  // controller -> service -> repository. O controller nunca recebe o
  // repository direto: pular o service e proibicao explicita (guia 4.4).
  final alunoRepository = AlunoRepository(db);
  final alunoService = AlunoService(alunoRepository);
  final alunoController = AlunoController(alunoService);

  // Montagem provisoria. A arvore de rotas das 10 features e de
  // `lib/router.dart` (Fase 3), que ainda nao existe.
  final rootRouter = Router()
    ..mount('/', adminHandler.router.call)
    ..mount('/', alunoController.router.call);

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(rootRouter.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Servidor rodando em http://${server.address.host}:${server.port}');
}
