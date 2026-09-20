import 'dart:convert';

import 'package:postgres/postgres.dart' as pg;
import 'package:shared/dtos/professor_serializer.dart';
import 'package:shared/erros/codigo_erro.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../shared/erros/tradutor_erro_banco.dart';
import 'professor_exception.dart';
import 'professor_service.dart';

class ProfessorController {
  final ProfessorService _service;

  ProfessorController(this._service);

  Router get router {
    final router = Router();
    router.post('/professor', _createProfessor);
    return router;
  }

  Future<Response> _createProfessor(Request request) async {
    final Map<String, dynamic> payload;
    try {
      payload =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return _erroDeForma('JSON invalido.');
    }

    final cpf = _texto(payload['cpf']);
    final senha = _texto(payload['senha']);
    final nome = _texto(payload['nome']);
    final telefone = _texto(payload['telefone']);
    final email = _texto(payload['email']);

    for (final obrigatorio in {
      'cpf': cpf,
      'senha': senha,
      'nome': nome,
      'telefone': telefone,
      'email': email,
    }.entries) {
      if (obrigatorio.value == null) {
        return _erroDeForma('Campo "${obrigatorio.key}" e obrigatorio.');
      }
    }

    if (nome!.trim().isEmpty || nome.trim().length > 150) {
      return _erroDeForma('Campo "nome" deve ter de 1 a 150 caracteres.');
    }
    if (telefone!.trim().isEmpty || telefone.trim().length > 20) {
      return _erroDeForma('Campo "telefone" deve ter ate 20 caracteres.');
    }
    if (senha!.length < 8 || senha.length > 12) {
      return _erroDeForma('Campo "senha" deve ter de 8 a 12 caracteres.');
    }

    try {
      final professor = await _service.criar(
        cpf: cpf!,
        senha: senha,
        nome: nome,
        telefone: telefone,
        email: email!,
        idAdminCriador: null,
        idEndereco: _inteiro(payload['id_endereco']),
      );

      return _json(
        201,
        professorToPublicJson(
          idProfessor: professor.idProfessor,
          nome: professor.nome,
          email: professor.email,
          telefone: professor.telefone,
        ),
      );
    } on ProfessorValidationException catch (e) {
      return _envelope(400, e.codigo, campo: e.campo);
    } on ProfessorConflictException catch (e) {
      return _envelope(409, e.codigo, campo: e.campo);
    } on pg.ServerException catch (e, stackTrace) {
      final codigo = traduzirErroBanco(e);
      if (codigo == null) {
        return _erroInterno(e, stackTrace);
      }
      return _envelope(
        e.code == '23505' ? 409 : 400,
        codigo,
        campo: _campoDe(codigo),
      );
    } catch (e, stackTrace) {
      return _erroInterno(e, stackTrace);
    }
  }

  Response _json(int status, Map<String, dynamic> corpo) => Response(
    status,
    body: jsonEncode(corpo),
    headers: {'Content-Type': 'application/json'},
  );

  Response _envelope(int status, CodigoErro codigo, {String? campo}) =>
      _json(status, {
        'codigo': codigo.valor,
        'mensagem': _mensagemDeApoio(codigo),
        'campo': ?campo,
      });

  Response _erroDeForma(String mensagem) => _json(400, {'erro': mensagem});

  Response _erroInterno(Object erro, StackTrace stackTrace) {
    // ignore: avoid_print
    print('Erro ao criar professor: $erro');
    // ignore: avoid_print
    print(stackTrace);
    return _json(500, {'erro': 'Erro interno ao criar professor.'});
  }

  String _mensagemDeApoio(CodigoErro codigo) => switch (codigo) {
    CodigoErro.cpfInvalido => 'CPF em formato invalido.',
    CodigoErro.emailInvalido => 'E-mail em formato invalido.',
    CodigoErro.cpfEmUso => 'CPF ja cadastrado.',
    CodigoErro.emailEmUso => 'E-mail ja cadastrado.',
    _ => 'Cadastro rejeitado.',
  };

  String? _campoDe(CodigoErro codigo) => switch (codigo) {
    CodigoErro.cpfEmUso || CodigoErro.cpfInvalido => 'cpf',
    CodigoErro.emailEmUso || CodigoErro.emailInvalido => 'email',
    _ => null,
  };

  String? _texto(Object? valor) {
    if (valor is! String) return null;
    return valor.trim().isEmpty ? null : valor;
  }

  int? _inteiro(Object? valor) => switch (valor) {
    final int i => i,
    final String s => int.tryParse(s),
    _ => null,
  };
}