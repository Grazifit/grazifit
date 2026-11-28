import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class BuscaComDebounce extends TextEditingController {
  BuscaComDebounce() {
    addListener(_agendar);
  }

  final _termo = ValueNotifier('');
  ValueListenable<String> get termo => _termo;
  Timer? _timer;
  String _ultimoTermo = '';

  void _agendar() {
    final consulta = text.trim().toLowerCase();
    if (consulta == _ultimoTermo) return;
    _ultimoTermo = consulta;
    _timer?.cancel();
    if (consulta.isEmpty) {
      _termo.value = '';
    } else if (consulta != _termo.value) {
      _timer = Timer(const Duration(milliseconds: 250), () {
        _termo.value = consulta;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _termo.dispose();
    super.dispose();
  }
}
