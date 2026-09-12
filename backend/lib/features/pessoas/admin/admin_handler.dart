import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../auth/criptografia.dart';
import '../../auth/validacoes.dart';

import 'admin_repository.dart';
import 'package:shared/erros/admin_exceptions.dart';
import 'package:shared/dtos/admin_serializer.dart';

class AdminHandler {
  final AdminRepository _repository;

  AdminHandler(this._repository);

  Router get router{
    final router = Router();
    router.post('/admin', _createAdmin);
    return router;
  }

  Response _jsonResponse(int status, Map<String, dynamic> body){
    return Response(
      status,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _createAdmin(Request request)async{
    final Map<String, dynamic> payload;
    try {
      final raw = await request.readAsString();
      payload = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return _jsonResponse(400, {'erro': 'JSON inválido.'});
    }

    final cpfRaw = payload['cpf'] as String?;
    final senha = payload['senha'] as String?;
    final nome = payload['nome'] as String?;
    final email = payload['email'] as String?;
    final telefone = payload['telefone'] as String?;

    if (cpfRaw == null || cpfRaw.trim().isEmpty) {
      return _jsonResponse(400, {'erro': 'Campo "cpf" é obrigatório.'});
    }
    if (senha == null || senha.trim().isEmpty) {
      return _jsonResponse(400, {'erro': 'Campo "senha" é obrigatório.'});
    }
    if (nome == null || nome.trim().isEmpty) {
      return _jsonResponse(400, {'erro': 'Campo "nome" é obrigatório.'});
    }
    if (email == null || email.trim().isEmpty) {
      return _jsonResponse(400, {'erro': 'Campo "email" é obrigatório.'});
    }
    if (!Validacoes.cpfValido(cpfRaw)) {
      return _jsonResponse(400, {'erro': 'CPF inválido.'});
    }
    if (!Validacoes.emailValido(email)) {
      return _jsonResponse(400, {'erro': 'E-mail inválido.'});
    }
    if (senha.length < 8) {
      return _jsonResponse(400, {'erro': 'Senha deve ter no mínimo 8 caracteres.'});
    }
    if (senha.length > 12) {
      return _jsonResponse(400, {'erro': 'Senha deve ter no maximo 12 caracteres.'});
    }
    final cpfNormalizado = cpfRaw.replaceAll(RegExp(r'[^0-9]'), '');
    try {
      final senhaHash = hashPassword(senha);

      final admin = await _repository.create(
        cpf: cpfNormalizado,
        senhaHash: senhaHash,
        nome: nome.trim(),
        email: email.trim().toLowerCase(),
        telefone: telefone?.trim(),
      );

      return _jsonResponse(201, adminToPublicJson(admin));
    } on ValidationException catch (e) {
      return _jsonResponse(400, {'erro': e.message});
    } on ConflictException catch (e) {
      return _jsonResponse(409, {'erro': e.message});
    } catch (e, stackTrace) {
      print('Erro ao criar admin: $e');
      print(stackTrace);
      return _jsonResponse(500, {'erro': 'Erro interno ao criar admin.'});
    }
  }
}