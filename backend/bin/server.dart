import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import '../lib/database/database.dart';
import '../lib/features/pessoas/admin/admin_handler.dart';
import '../lib/features/pessoas/admin/admin_repository.dart';

void main() async {
  final db = GraziDatabase.doAmbiente();

  final adminRepository = AdminRepository(db);
  final adminHandler = AdminHandler(adminRepository);

  final rootRouter = Router()..mount('/', adminHandler.router.call);

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(rootRouter.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Servidor rodando em http://${server.address.host}:${server.port}');
}