import 'dart:collection';

/// Limite de requisicoes por chave (ex.: usuario autenticado) em janela
/// deslizante. Guarda o instante de cada requisicao aceita.
///
/// Estado local ao processo, como `ProtecaoLogin`. Com mais de uma instancia
/// do backend, usar armazenamento compartilhado e limitar tambem na borda.
class LimitadorJanela {
  final int maximo;
  final Duration janela;

  /// Teto de chaves em memoria. Esgotado, chaves novas sao recusadas (falha
  /// fechada), como em `ProtecaoLogin`.
  final int maxChaves;

  final DateTime Function() _agora;
  final Map<Object, Queue<DateTime>> _eventos = {};

  LimitadorJanela({
    required this.maximo,
    required this.janela,
    this.maxChaves = 10000,
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now {
    if (maximo < 1 || maxChaves < 1 || janela <= Duration.zero) {
      throw ArgumentError('Limites devem ser positivos.');
    }
  }

  /// `null` quando a requisicao cabe no limite e fica contada. Senao, devolve
  /// os segundos ate a proxima vaga (sempre >= 1), para o `Retry-After`.
  int? registrar(Object chave) {
    final agora = _agora();
    final inicio = agora.subtract(janela);

    var eventos = _eventos[chave];
    if (eventos == null) {
      if (_eventos.length >= maxChaves) {
        _eventos.removeWhere((_, e) => e.isEmpty || !e.last.isAfter(inicio));
        if (_eventos.length >= maxChaves) return _segundos(janela);
      }
      eventos = _eventos[chave] = Queue<DateTime>();
    }

    while (eventos.isNotEmpty && !eventos.first.isAfter(inicio)) {
      eventos.removeFirst();
    }
    if (eventos.length >= maximo) {
      return _segundosAte(eventos.first.add(janela), agora);
    }
    eventos.add(agora);
    return null;
  }

  static int _segundosAte(DateTime prazo, DateTime agora) =>
      _segundos(prazo.difference(agora));

  static int _segundos(Duration duracao) {
    final ms = duracao.inMilliseconds;
    final inteiro = (ms + 999) ~/ 1000;
    return inteiro < 1 ? 1 : inteiro;
  }
}
