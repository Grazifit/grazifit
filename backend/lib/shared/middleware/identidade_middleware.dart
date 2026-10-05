import 'dart:convert';

import 'package:shared/erros/codigo_erro.dart';
import 'package:shelf/shelf.dart';

import '../../features/auth/auth_repository.dart';
import '../../features/auth/token_service.dart';
import '../autorizacao/identidade.dart';

const chaveIdentidadeContexto = 'grazifit.identidade';

Identidade? identidadeDaRequisicao(Request request) =>
    request.context[chaveIdentidadeContexto] as Identidade?;

/// Resolve quem chama a API. Permissoes continuam nos services.
Middleware identidadeMiddleware(TokenService tokens, AuthRepository contas) =>
    (innerHandler) => (request) async {
      if (request.method == 'POST' && request.url.path == 'auth/login') {
        return innerHandler(request);
      }

      final cabecalho = request.headers['authorization'];
      final partes = cabecalho?.split(' ');
      final token =
          partes != null &&
              partes.length == 2 &&
              partes[0].toLowerCase() == 'bearer'
          ? partes[1]
          : null;
      final identidade = token == null ? null : tokens.validar(token);
      if (identidade == null || !await contas.contaAtiva(identidade)) {
        return Response(
          401,
          body: jsonEncode({
            'codigo': CodigoErro.tokenInvalido.valor,
            'mensagem': 'Autenticacao necessaria ou token invalido.',
          }),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
        );
      }

      return innerHandler(
        request.change(context: {chaveIdentidadeContexto: identidade}),
      );
    };
