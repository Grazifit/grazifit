import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../shared/autorizacao/identidade.dart';

/// Token de acesso assinado, sem estado no servidor. A chave e separada do
/// pepper de senhas e deve ser igual em todas as instancias da API.
class TokenService {
  static const validade = Duration(hours: 1);
  static const _emissor = 'grazifit';
  static const _audiencia = 'grazifit-api';
  static final _segmentoHeader = _codificarJson(const {
    'alg': 'HS256',
    'typ': 'JWT',
  });
  static final _base64Url = RegExp(r'^[A-Za-z0-9_-]+$');

  final Uint8List _chave;
  final DateTime Function() _agora;

  TokenService({required String chaveBase64, DateTime Function()? agora})
    : _chave = _decodificarChave(chaveBase64),
      _agora = agora ?? DateTime.now;

  String emitir(Identidade identidade) {
    final emitidoEm = _agora().toUtc().millisecondsSinceEpoch ~/ 1000;
    final payload = _codificarJson({
      'iss': _emissor,
      'aud': _audiencia,
      'sub': '${identidade.papel.name}:${identidade.id}',
      'papel': identidade.papel.name,
      'iat': emitidoEm,
      'exp': emitidoEm + validade.inSeconds,
    });
    final conteudo = '$_segmentoHeader.$payload';
    final assinatura = _base64SemPadding(_assinar(conteudo));
    return '$conteudo.$assinatura';
  }

  Identidade? validar(String token) {
    if (token.length > 4096) return null;
    final partes = token.split('.');
    if (partes.length != 3 || partes.any((p) => !_base64Url.hasMatch(p))) {
      return null;
    }

    final assinaturaRecebida = _decodificarBase64Url(partes[2]);
    if (assinaturaRecebida == null ||
        !_mesmosBytes(
          _assinar('${partes[0]}.${partes[1]}'),
          assinaturaRecebida,
        )) {
      return null;
    }

    final header = _decodificarJson(partes[0]);
    final payload = _decodificarJson(partes[1]);
    if (header == null ||
        payload == null ||
        header['alg'] != 'HS256' ||
        header['typ'] != 'JWT' ||
        payload['iss'] != _emissor ||
        payload['aud'] != _audiencia) {
      return null;
    }

    final papelBruto = payload['papel'];
    final sub = payload['sub'];
    final emitidoEm = payload['iat'];
    final expiraEm = payload['exp'];
    if (papelBruto is! String ||
        sub is! String ||
        emitidoEm is! int ||
        expiraEm is! int) {
      return null;
    }

    final agora = _agora().toUtc().millisecondsSinceEpoch ~/ 1000;
    if (emitidoEm > agora + 60 ||
        expiraEm <= agora ||
        expiraEm <= emitidoEm ||
        expiraEm - emitidoEm > validade.inSeconds) {
      return null;
    }

    final partesSub = sub.split(':');
    if (partesSub.length != 2 || partesSub[0] != papelBruto) return null;
    final id = int.tryParse(partesSub[1]);
    if (id == null || id <= 0) return null;
    for (final papel in Papel.values) {
      if (papel.name == papelBruto) return Identidade(id: id, papel: papel);
    }
    return null;
  }

  List<int> _assinar(String conteudo) =>
      Hmac(sha256, _chave).convert(utf8.encode(conteudo)).bytes;

  static Uint8List _decodificarChave(String valor) {
    final List<int> chave;
    try {
      chave = base64Decode(valor);
    } on FormatException {
      throw StateError('TOKEN_SIGNING_KEY deve ser Base64 valido.');
    }
    if (chave.length < 32) {
      throw StateError('TOKEN_SIGNING_KEY deve ter pelo menos 32 bytes.');
    }
    return Uint8List.fromList(chave);
  }

  static String _codificarJson(Map<String, Object> valor) =>
      _base64SemPadding(utf8.encode(jsonEncode(valor)));

  static String _base64SemPadding(List<int> valor) =>
      base64Url.encode(valor).replaceAll('=', '');

  static List<int>? _decodificarBase64Url(String valor) {
    try {
      return base64Url.decode('$valor${'=' * ((4 - valor.length % 4) % 4)}');
    } on FormatException {
      return null;
    }
  }

  static Map<String, dynamic>? _decodificarJson(String valor) {
    final bytes = _decodificarBase64Url(valor);
    if (bytes == null) return null;
    try {
      final json = jsonDecode(utf8.decode(bytes));
      return json is Map<String, dynamic> ? json : null;
    } on FormatException {
      return null;
    }
  }

  static bool _mesmosBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diferenca = 0;
    for (var i = 0; i < a.length; i++) {
      diferenca |= a[i] ^ b[i];
    }
    return diferenca == 0;
  }
}
