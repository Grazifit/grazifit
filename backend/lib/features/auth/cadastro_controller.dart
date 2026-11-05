import 'dart:convert';
import 'dart:io';
import 'package:shared/erros/excecao_validacao.dart';
import 'cadastro_service.dart';

class CadastroController {
  final CadastroService _service = CadastroService();

  Future<void> handleCadastro(HttpRequest request) async {
    try {
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      await _service.cadastrar(
        nome: data['nome'] as String,
        email: data['email'] as String,
        cpf: data['cpf'] as String,
        senha: data['senha'] as String,
      );

      request.response
        ..statusCode = HttpStatus.created
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'message': 'Cadastrado com sucesso'}));
    } on ExcecaoValidacao catch (e) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': e.message}));
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': 'Erro interno no servidor'}));
    } finally {
      await request.response.close();
    }
  }
}