import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../database/database.dart';
import 'admin_service.dart';
import 'package:grazifit_backend/shared/erros/admin_exceptions.dart';
import 'package:shared/dtos/admin_serializer.dart';

class AdminController {
  final AdminService _service;

  AdminController(this._service);

  Router get router {
    final router = Router();
    router.post('/admin', _criar);
    router.get('/admin/<id>', _buscarPorId);
    router.patch('/admin/<id>', _atualizar);
    router.delete('/admin/<id>', _deletar);
    return router;
  }

  Response _jsonResponse(int status, Map<String, dynamic> body) {
    return Response(
      status,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
  }

Map<String, dynamic> _paraJson(AdminData admin) {
  return adminToPublicJson(
    idAdmin: admin.idAdmin,
    nome: admin.nome,
    email: admin.email,
    telefone: admin.telefone,
  );
}

  Future<Response> _criar(Request request) async {
    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return _jsonResponse(400, {'erro': 'JSON inválido.'});
    }

    final cpf = payload['cpf'] as String?;
    final senha = payload['senha'] as String?;
    final nome = payload['nome'] as String?;
    final email = payload['email'] as String?;
    final telefone = payload['telefone'] as String?;

    if (cpf == null || senha == null || nome == null || email == null) {
      return _jsonResponse(400, {'erro': 'Campos obrigatórios ausentes.'});
    }

    try {
      final admin = await _service.criar(
        cpf: cpf,
        senha: senha,
        nome: nome,
        email: email,
        telefone: telefone,
      );
      return _jsonResponse(201, _paraJson(admin));
    } on ValidationException catch (e) {
      return _jsonResponse(400, {'erro': e.message});
    } on ConflictException catch (e) {
      return _jsonResponse(409, {'erro': e.message});
    } catch (e) {
      return _jsonResponse(500, {'erro': 'Erro interno ao criar admin.'});
    }
  }

  Future<Response> _buscarPorId(Request request, String id) async {
    final idAdmin = int.tryParse(id);
    if (idAdmin == null) {
      return _jsonResponse(400, {'erro': 'Id inválido.'});
    }

    try {
      final admin = await _service.buscarPorId(idAdmin);
      return _jsonResponse(200, _paraJson(admin));
    } on NotFoundException catch (e) {
      return _jsonResponse(404, {'erro': e.message});
    } catch (e) {
      return _jsonResponse(500, {'erro': 'Erro interno ao buscar admin.'});
    }
  }

  Future<Response> _atualizar(Request request, String id) async {
    final idAdmin = int.tryParse(id);
    if (idAdmin == null) {
      return _jsonResponse(400, {'erro': 'Id inválido.'});
    }

    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return _jsonResponse(400, {'erro': 'JSON inválido.'});
    }

    try {
      final admin = await _service.atualizar(
        idAdmin: idAdmin,
        nome: payload['nome'] as String?,
        email: payload['email'] as String?,
        telefone: payload['telefone'] as String?,
        senha: payload['senha'] as String?,
      );
      return _jsonResponse(200, _paraJson(admin));
    } on ValidationException catch (e) {
      return _jsonResponse(400, {'erro': e.message});
    } on ConflictException catch (e) {
      return _jsonResponse(409, {'erro': e.message});
    } on NotFoundException catch (e) {
      return _jsonResponse(404, {'erro': e.message});
    } catch (e) {
      return _jsonResponse(500, {'erro': 'Erro interno ao atualizar admin.'});
    }
  }

  Future<Response> _deletar(Request request, String id) async {
    final idAdmin = int.tryParse(id);
    if (idAdmin == null) {
      return _jsonResponse(400, {'erro': 'Id inválido.'});
    }

    try {
      await _service.deletar(idAdmin);
      return Response(204);
    } on NotFoundException catch (e) {
      return _jsonResponse(404, {'erro': e.message});
    } catch (e) {
      return _jsonResponse(500, {'erro': 'Erro interno ao remover admin.'});
    }
  }
}