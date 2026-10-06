import 'dart:convert';

import 'package:postgres/postgres.dart' as pg;
import 'package:shared/dtos/professor_serializer.dart';
import 'package:shared/erros/codigo_erro.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../database/database.dart' show ProfessorData;
import '../../../shared/erros/professor_exception.dart';
import '../../../shared/erros/tradutor_erro_banco.dart';
import 'professor_service.dart';

/// Forma da requisição e montagem do DTO — nada além disso.
///
/// Sem regra de negócio: o que este arquivo decide é se o corpo tem a forma
/// esperada e qual status HTTP corresponde à exceção que subiu.
class ProfessorController {
  final ProfessorService _service;

  ProfessorController(this._service);

  Router get router {
    final router = Router();
    router.post('/professor', _criar);
    router.get('/professor/<id>', _buscarPorId);
    router.patch('/professor/<id>', _atualizar);
    router.delete('/professor/<id>', _deletar);
    return router;
  }

  // ---------------------------------------------------------------- handlers

  Future<Response> _criar(Request request) async {
    final payload = await _lerCorpo(request);
    if (payload == null) return _erroDeForma('JSON inválido.');

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
        return _erroDeForma('Campo "${obrigatorio.key}" é obrigatório.');
      }
    }

    if (nome!.trim().length > 150) {
      return _erroDeForma('Campo "nome" deve ter de 1 a 150 caracteres.');
    }
    if (telefone!.trim().length > 20) {
      return _erroDeForma('Campo "telefone" deve ter até 20 caracteres.');
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
      );
      return _json(201, _paraJson(professor));
    } on ProfessorException catch (e) {
      return _tratarProfessor(e);
    } on pg.ServerException catch (e, st) {
      return _tratarBanco(e, st);
    } catch (e, st) {
      return _erroInterno(e, st);
    }
  }

  Future<Response> _buscarPorId(Request request, String id) async {
    final idProfessor = int.tryParse(id);
    if (idProfessor == null) return _erroDeForma('Id inválido.');

    try {
      final professor = await _service.buscarPorId(idProfessor);
      return _json(200, _paraJson(professor));
    } on ProfessorException catch (e) {
      return _tratarProfessor(e);
    } on pg.ServerException catch (e, st) {
      return _tratarBanco(e, st);
    } catch (e, st) {
      return _erroInterno(e, st);
    }
  }

  Future<Response> _atualizar(Request request, String id) async {
    final idProfessor = int.tryParse(id);
    if (idProfessor == null) return _erroDeForma('Id inválido.');

    final payload = await _lerCorpo(request);
    if (payload == null) return _erroDeForma('JSON inválido.');

    final erroDeForma = _validarFormaAtualizacao(payload);
    if (erroDeForma != null) return _erroDeForma(erroDeForma);

    try {
      final professor = await _service.atualizar(
        idProfessor: idProfessor,
        nome: _texto(payload['nome']),
        email: _texto(payload['email']),
        telefone: _texto(payload['telefone']),
        senha: _texto(payload['senha']),
        status: payload['status'] as bool?,
      );
      return _json(200, _paraJson(professor));
    } on ProfessorException catch (e) {
      return _tratarProfessor(e);
    } on pg.ServerException catch (e, st) {
      return _tratarBanco(e, st);
    } catch (e, st) {
      return _erroInterno(e, st);
    }
  }

  Future<Response> _deletar(Request request, String id) async {
    final idProfessor = int.tryParse(id);
    if (idProfessor == null) return _erroDeForma('Id inválido.');

    try {
      await _service.deletar(idProfessor);
      return Response(204);
    } on ProfessorException catch (e) {
      return _tratarProfessor(e);
    } on pg.ServerException catch (e, st) {
      return _tratarBanco(e, st);
    } catch (e, st) {
      return _erroInterno(e, st);
    }
  }

  // ------------------------------------------------------------------ forma

  Future<Map<String, dynamic>?> _lerCorpo(Request request) async {
    try {
      final corpo = jsonDecode(await request.readAsString());
      return corpo is Map<String, dynamic> ? corpo : null;
    } catch (_) {
      return null;
    }
  }

  /// No PATCH todo campo é opcional, mas o que vier precisa ter a forma certa.
  String? _validarFormaAtualizacao(Map<String, dynamic> p) {
    if (p.containsKey('nome')) {
      final nome = _texto(p['nome']);
      if (nome == null || nome.trim().length > 150) {
        return 'Campo "nome" deve ter de 1 a 150 caracteres.';
      }
    }
    if (p.containsKey('telefone')) {
      final telefone = _texto(p['telefone']);
      if (telefone == null || telefone.trim().length > 20) {
        return 'Campo "telefone" deve ter de 1 a 20 caracteres.';
      }
    }
    if (p.containsKey('email') && _texto(p['email']) == null) {
      return 'Campo "email" deve ser um texto não vazio.';
    }
    if (p.containsKey('senha')) {
      final senha = _texto(p['senha']);
      if (senha == null || senha.length < 8 || senha.length > 12) {
        return 'Campo "senha" deve ter de 8 a 12 caracteres.';
      }
    }
    if (p.containsKey('status') && p['status'] is! bool) {
      return 'Campo "status" deve ser verdadeiro ou falso.';
    }
    return null;
  }

  String? _texto(Object? valor) {
    if (valor is! String) return null;
    return valor.trim().isEmpty ? null : valor;
  }

  Map<String, dynamic> _paraJson(ProfessorData p) => professorToPublicJson(
    idProfessor: p.idProfessor,
    nome: p.nome,
    email: p.email,
    telefone: p.telefone,
    status: p.status,
  );

  // ------------------------------------------------------------------ erros

  Response _tratarProfessor(ProfessorException e) => switch (e) {
    ProfessorValidationException() => _envelope(400, e.codigo, campo: e.campo),
    ProfessorConflictException() => _envelope(409, e.codigo, campo: e.campo),
    ProfessorNotFoundException() => _envelope(404, e.codigo),
  };

  Response _tratarBanco(pg.ServerException e, StackTrace st) {
    final codigo = traduzirErroBanco(e);
    if (codigo == null) return _erroInterno(e, st);

    final status = switch (e.code) {
      '23505' || '23503' => 409, // unicidade ou FK com RESTRICT
      _ => 400,
    };
    return _envelope(status, codigo, campo: _campoDe(codigo));
  }

  Response _erroInterno(Object erro, StackTrace st) {
    // ignore: avoid_print
    print('Erro em professor: $erro');
    // ignore: avoid_print
    print(st);
    return _json(500, {'erro': 'Erro interno.'});
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

  String _mensagemDeApoio(CodigoErro codigo) => switch (codigo) {
    CodigoErro.cpfInvalido => 'CPF em formato inválido.',
    CodigoErro.emailInvalido => 'E-mail em formato inválido.',
    CodigoErro.cpfEmUso => 'CPF já cadastrado.',
    CodigoErro.emailEmUso => 'E-mail já cadastrado.',
    CodigoErro.professorEmUso =>
      'Professor possui vínculos, cronogramas, aulas ou treinos.',
    CodigoErro.professorNaoEncontrado => 'Professor não encontrado.',
    _ => 'Requisição rejeitada.',
  };

  String? _campoDe(CodigoErro codigo) => switch (codigo) {
    CodigoErro.cpfEmUso || CodigoErro.cpfInvalido => 'cpf',
    CodigoErro.emailEmUso || CodigoErro.emailInvalido => 'email',
    _ => null,
  };
}