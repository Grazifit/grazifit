import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/pessoas/admin/admin_controller.dart';
import 'package:grazifit_backend/features/pessoas/admin/admin_repository.dart';
import 'package:grazifit_backend/features/pessoas/admin/admin_service.dart';
import 'package:grazifit_backend/features/pessoas/aluno/aluno_controller.dart';
import 'package:grazifit_backend/features/pessoas/aluno/aluno_repository.dart';
import 'package:grazifit_backend/features/pessoas/aluno/aluno_service.dart';

void main() async {
  final db = GraziDatabase.doAmbiente();

  final adminRepository = AdminRepository(db);
  final adminService = AdminService(adminRepository);
  final adminController = AdminController(adminService);

  final alunoRepository = AlunoRepository(db);
  final alunoService = AlunoService(alunoRepository);
  final alunoController = AlunoController(alunoService);

  final rootRouter = Router()
    ..mount('/', adminController.router.call)
    ..mount('/', alunoController.router.call);

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(rootRouter.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Servidor rodando em http://${server.address.host}:${server.port}');
}