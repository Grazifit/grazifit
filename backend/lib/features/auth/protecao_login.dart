import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Limites locais ao processo. Em mais de uma instancia, usar um armazenamento
/// compartilhado e limitar tambem na borda (proxy/API gateway).
class ProtecaoLogin {
  final DateTime Function() _agora;
  final Duration janelaIp;
  final Duration bloqueioInicialIp;
  final Duration janelaConta;
  final int maxTentativasIp;
  final int maxInfracoesIp;
  final int maxTentativasConta;
  final int maxArgon2EmAndamento;
  final int maxIdentificadores;
  final int inicioBackoff;

  final Map<String, _Historico> _ips = {};
  final Map<String, _Historico> _contas = {};
  int _argon2EmAndamento = 0;

  ProtecaoLogin({
    DateTime Function()? agora,
    this.janelaIp = const Duration(minutes: 15),
    this.bloqueioInicialIp = const Duration(minutes: 15),
    this.janelaConta = const Duration(minutes: 15),
    this.maxTentativasIp = 30,
    this.maxInfracoesIp = 7,
    this.maxTentativasConta = 10,
    this.maxArgon2EmAndamento = 2,
    this.maxIdentificadores = 10000,
    this.inicioBackoff = 3,
  }) : _agora = agora ?? DateTime.now {
    if (maxTentativasIp < 1 ||
        maxInfracoesIp < 1 ||
        maxTentativasConta < 1 ||
        maxArgon2EmAndamento < 1 ||
        maxIdentificadores < 1 ||
        inicioBackoff < 1 ||
        janelaIp <= Duration.zero ||
        bloqueioInicialIp <= Duration.zero ||
        janelaConta <= Duration.zero) {
      throw ArgumentError('Limites de login devem ser positivos.');
    }
  }

  /// Conta toda requisicao de login, inclusive JSON invalido e sucesso.
  EsperaLogin? registrarIp(String ip) {
    final agora = _agora();
    final historico = _obter(_ips, ip, agora, janelaIp);
    if (historico == null) return const EsperaLogin(60);

    if (historico.bloqueioPermanenteIp) {
      return const EsperaLogin.permanente();
    }
    final bloqueadoAte = historico.bloqueadoAteIp;
    if (bloqueadoAte != null) {
      if (bloqueadoAte.isAfter(agora)) {
        return EsperaLogin(_segundosAte(bloqueadoAte, agora));
      }
      // A nova infracao exige uma nova rodada completa de tentativas.
      historico.bloqueadoAteIp = null;
      historico.tentativas.clear();
    }

    _removerAntigas(historico.tentativas, agora, janelaIp);
    if (historico.tentativas.length >= maxTentativasIp) {
      historico.infracoesIp++;
      historico.tentativas.clear();
      if (historico.infracoesIp >= maxInfracoesIp) {
        historico.bloqueioPermanenteIp = true;
        return const EsperaLogin.permanente();
      }
      final duracao = Duration(
        microseconds: bloqueioInicialIp.inMicroseconds * historico.infracoesIp,
      );
      historico.bloqueadoAteIp = agora.add(duracao);
      return EsperaLogin(_segundosAte(historico.bloqueadoAteIp!, agora));
    }
    historico.tentativas.add(agora);
    return null;
  }

  /// O mesmo email, existente ou nao, compartilha o limite. Nao guardamos
  /// o email em claro no estado do limitador.
  EsperaLogin? registrarConta(String email) {
    final agora = _agora();
    final historico = _obter(_contas, _chaveConta(email), agora, janelaConta);
    if (historico == null) return const EsperaLogin(60);
    _removerAntigas(historico.tentativas, agora, janelaConta);
    _removerAntigas(historico.falhas, agora, janelaConta);
    final proxima = historico.proximaTentativa;
    if (proxima != null && proxima.isAfter(agora)) {
      return EsperaLogin(_segundosAte(proxima, agora));
    }
    if (historico.tentativas.length >= maxTentativasConta) {
      return EsperaLogin(
        _segundosAte(historico.tentativas.first.add(janelaConta), agora),
      );
    }
    historico.tentativas.add(agora);
    return null;
  }

  void registrarFalha(String email) {
    final agora = _agora();
    final historico = _contas[_chaveConta(email)];
    if (historico == null) return;
    _removerAntigas(historico.falhas, agora, janelaConta);
    historico.falhas.add(agora);
    historico.ultimaAtividade = agora;
    final excesso = historico.falhas.length - inicioBackoff;
    if (excesso >= 0) {
      final segundos = min(60, 1 << min(excesso, 6));
      historico.proximaTentativa = agora.add(Duration(seconds: segundos));
    }
  }

  void registrarSucesso(String email) => _contas.remove(_chaveConta(email));

  /// Sem fila: rejeita imediatamente quando as verificacoes caras estao
  /// ocupadas, impedindo que pedidos pendentes consumam memoria sem limite.
  bool reservarVerificacao() {
    if (_argon2EmAndamento >= maxArgon2EmAndamento) return false;
    _argon2EmAndamento++;
    return true;
  }

  void liberarVerificacao() {
    if (_argon2EmAndamento == 0) {
      throw StateError('Nenhuma verificacao reservada.');
    }
    _argon2EmAndamento--;
  }

  _Historico? _obter(
    Map<String, _Historico> historicos,
    String chave,
    DateTime agora,
    Duration janela,
  ) {
    final existente = historicos[chave];
    if (existente != null) {
      existente.ultimaAtividade = agora;
      return existente;
    }
    if (historicos.length >= maxIdentificadores) {
      historicos.removeWhere(
        (_, estado) =>
            estado.infracoesIp == 0 &&
            !estado.ultimaAtividade.add(janela).isAfter(agora) &&
            !(estado.proximaTentativa?.isAfter(agora) ?? false),
      );
      if (historicos.length >= maxIdentificadores) return null;
    }
    return historicos[chave] = _Historico(agora);
  }

  static String _chaveConta(String email) =>
      sha256.convert(utf8.encode(email.trim().toLowerCase())).toString();

  static void _removerAntigas(
    Queue<DateTime> eventos,
    DateTime agora,
    Duration janela,
  ) {
    final inicio = agora.subtract(janela);
    while (eventos.isNotEmpty && !eventos.first.isAfter(inicio)) {
      eventos.removeFirst();
    }
  }

  static int _segundosAte(DateTime prazo, DateTime agora) =>
      max(1, (prazo.difference(agora).inMilliseconds + 999) ~/ 1000);
}

class EsperaLogin {
  /// Ausente quando o IP esta bloqueado ate o processo reiniciar.
  final int? segundos;
  const EsperaLogin(this.segundos);
  const EsperaLogin.permanente() : segundos = null;
}

class _Historico {
  final Queue<DateTime> tentativas = Queue<DateTime>();
  final Queue<DateTime> falhas = Queue<DateTime>();
  DateTime ultimaAtividade;
  DateTime? proximaTentativa;
  DateTime? bloqueadoAteIp;
  int infracoesIp = 0;
  bool bloqueioPermanenteIp = false;

  _Historico(this.ultimaAtividade);
}
