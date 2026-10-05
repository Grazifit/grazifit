import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shared/dtos/auth_dto.dart';
import 'package:shared/erros/codigo_erro.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth_service.dart';
import 'protecao_login.dart';

class AuthController {
  final AuthService _service;
  final ProtecaoLogin _protecao;

  AuthController(this._service, {ProtecaoLogin? protecao})
    : _protecao = protecao ?? ProtecaoLogin();

  Router get router => Router()..post('/auth/login', _login);

  Future<Response> _login(Request request) async {
    // Nunca confiar em X-Forwarded-For enviado diretamente pelo cliente.
    final conexao = request.context['shelf.io.connection_info'];
    final ip = conexao is HttpConnectionInfo
        ? conexao.remoteAddress.address
        : 'desconhecido';
    final limiteIp = _protecao.registrarIp(ip);
    if (limiteIp != null) return _limite(limiteIp);

    final LoginRequestDto entrada;
    try {
      final json = jsonDecode(await _lerJsonLimitado(request));
      if (json is! Map<String, dynamic>) throw const FormatException();
      entrada = LoginRequestDto.fromJson(json);
    } on FormatException {
      return _erro(
        400,
        CodigoErro.requisicaoInvalida,
        'Informe email e senha validos.',
      );
    }

    final limiteConta = _protecao.registrarConta(entrada.email);
    if (limiteConta != null) return _limite(limiteConta);
    if (!_protecao.reservarVerificacao()) {
      return _limite(const EsperaLogin(1));
    }

    try {
      final resposta = await _service.login(entrada);
      _protecao.registrarSucesso(entrada.email);
      return Response.ok(
        jsonEncode(resposta.toJson()),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Cache-Control': 'no-store',
        },
      );
    } on CredenciaisInvalidas {
      _protecao.registrarFalha(entrada.email);
      return _erro(
        401,
        CodigoErro.credenciaisInvalidas,
        'Email ou senha incorretos.',
      );
    } finally {
      _protecao.liberarVerificacao();
    }
  }

  Response _limite(EsperaLogin espera) => Response(
    429,
    body: jsonEncode({
      'codigo': CodigoErro.muitasTentativas.valor,
      'mensagem': 'Muitas tentativas. Tente novamente mais tarde.',
    }),
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
      if (espera.segundos case final segundos?) 'Retry-After': '$segundos',
    },
  );

  Response _erro(int status, CodigoErro codigo, String mensagem) => Response(
    status,
    body: jsonEncode({'codigo': codigo.valor, 'mensagem': mensagem}),
    headers: {'Content-Type': 'application/json; charset=utf-8'},
  );

  Future<String> _lerJsonLimitado(Request request) async {
    const limite = 4096;
    final bytes = BytesBuilder();
    await for (final bloco in request.read()) {
      if (bytes.length + bloco.length > limite) throw const FormatException();
      bytes.add(bloco);
    }
    return utf8.decode(bytes.takeBytes());
  }
}
