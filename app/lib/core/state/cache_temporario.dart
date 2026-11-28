import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Retém o resultado por até 30 segundos a partir do início da consulta.
/// Erros e invalidações não mantêm a entrada em cache.
Future<T> carregarComCacheTemporario<T>(
  Ref ref,
  Future<T> Function() carregar,
) async {
  final cache = ref.keepAlive();
  final timer = Timer(const Duration(seconds: 30), cache.close);
  ref.onDispose(timer.cancel);

  try {
    return await carregar();
  } catch (_) {
    timer.cancel();
    cache.close();
    rethrow;
  }
}
