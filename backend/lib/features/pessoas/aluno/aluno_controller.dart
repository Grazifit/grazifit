import 'dart:convert';

import 'package:postgres/postgres.dart' as pg;
import 'package:shared/dtos/aluno_serializer.dart';
import 'package:shared/erros/codigo_erro.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../shared/erros/tradutor_erro_banco.dart';
import 'aluno_exception.dart';
import 'aluno_service.dart';

/// Forma da requisicao e montagem do DTO — nada alem disso.
///
/// Sem regra de negocio e sem decisao de permissao (guia secao 4.4). O que
/// este arquivo decide e apenas: o corpo tem a forma esperada? e que status
/// HTTP corresponde a excecao que subiu?
class AlunoController {
  final AlunoService _service;

  AlunoController(this._service);

  Router get router {
    final router = Router();
    router.post('/aluno', _createAluno);
    return router;
  }

  Future<Response> _createAluno(Request request) async {
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
    final dataNascimentoBruta = _texto(payload['data_nascimento']);

    for (final obrigatorio in {
      'cpf': cpf,
      'senha': senha,
      'nome': nome,
      'telefone': telefone,
      'email': email,
      'data_nascimento': dataNascimentoBruta,
    }.entries) {
      if (obrigatorio.value == null) {
        return _erroDeForma('Campo "${obrigatorio.key}" e obrigatorio.');
      }
    }

    final dataNascimento = _dataCivil(dataNascimentoBruta!);
    if (dataNascimento == null) {
      return _erroDeForma(
        'Campo "data_nascimento" deve ser uma data existente '
        'no formato AAAA-MM-DD.',
      );
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
      final aluno = await _service.criar(
        cpf: cpf!,
        senha: senha,
        nome: nome,
        dataNascimento: dataNascimento,
        telefone: telefone,
        email: email!,
        idAdminCriador: null,
        idEndereco: _inteiro(payload['id_endereco']),
        restricaoMedica: _texto(payload['restricao_medica']),
        observacaoSaude: _texto(payload['observacao_saude']),
      );

      return _json(
        201,
        alunoToPublicJson(
          idAluno: aluno.idAluno,
          nome: aluno.nome,
          email: aluno.email,
          telefone: aluno.telefone,
        ),
      );
    } on AlunoValidationException catch (e) {
      return _envelope(400, e.codigo, campo: e.campo);
    } on AlunoConflictException catch (e) {
      return _envelope(409, e.codigo, campo: e.campo);
    } on pg.ServerException catch (e, stackTrace) {

      final codigo = traduzirErroBanco(e);
      if (codigo == null) {
        return _erroInterno(e, stackTrace);
      }

      // 23505 e conflito de registro; 23514 e dado invalido.
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
    print('Erro ao criar aluno: $erro');
    // ignore: avoid_print
    print(stackTrace);
    return _json(500, {'erro': 'Erro interno ao criar aluno.'});
  }

  String _mensagemDeApoio(CodigoErro codigo) => switch (codigo) {
    CodigoErro.cpfInvalido => 'CPF em formato invalido.',
    CodigoErro.emailInvalido => 'E-mail em formato invalido.',
    CodigoErro.cpfEmUso => 'CPF ja cadastrado.',
    CodigoErro.emailEmUso => 'E-mail ja cadastrado.',
    CodigoErro.dataNascimentoInvalida =>
      'Data de nascimento deve ser anterior a hoje.',
    _ => 'Cadastro rejeitado.',
  };

  String? _campoDe(CodigoErro codigo) => switch (codigo) {
    CodigoErro.cpfEmUso || CodigoErro.cpfInvalido => 'cpf',
    CodigoErro.emailEmUso || CodigoErro.emailInvalido => 'email',
    CodigoErro.dataNascimentoInvalida => 'data_nascimento',
    _ => null,
  };

  static final RegExp _formatoData = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  DateTime? _dataCivil(String bruto) {
    if (!_formatoData.hasMatch(bruto)) return null;

    final data = DateTime.tryParse(bruto);
    if (data == null) return null;

    String dois(int n) => n.toString().padLeft(2, '0');
    final normalizada =
        '${data.year.toString().padLeft(4, '0')}-'
        '${dois(data.month)}-${dois(data.day)}';

    return normalizada == bruto ? data : null;
  }

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
