import 'dart:convert';

import 'package:postgres/postgres.dart' as pg;
import 'package:shared/erros/codigo_erro.dart';
import 'package:shelf/shelf.dart';

import '../../shared/autorizacao/identidade.dart';
import '../erros/tradutor_erro_banco.dart';

/// Ultima barreira de erros: nenhuma excecao crua vai para o cliente.
Middleware errorHandler() =>
    (innerHandler) => (request) async {
      try {
        return await innerHandler(request);
      } on AcessoNegado {
        return _erro(403, CodigoErro.acessoNegado, 'Acesso negado.');
      } on pg.ServerException catch (erro) {
        final codigo = traduzirErroBanco(erro);
        if (codigo == null) {
          return _erro(
            500,
            CodigoErro.erroInterno,
            'Erro interno do servidor.',
          );
        }
        final status = switch (erro.code) {
          '23505' || 'GF001' || 'GF002' => 409,
          _ => 400,
        };
        return _erro(status, codigo, 'Operacao rejeitada.');
      } catch (_) {
        return _erro(500, CodigoErro.erroInterno, 'Erro interno do servidor.');
      }
    };

Response _erro(int status, CodigoErro codigo, String mensagem) => Response(
  status,
  body: jsonEncode({'codigo': codigo.valor, 'mensagem': mensagem}),
  headers: {'Content-Type': 'application/json; charset=utf-8'},
);
