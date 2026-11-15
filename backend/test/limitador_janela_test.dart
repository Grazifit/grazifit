import 'package:grazifit_backend/shared/limite/limitador_janela.dart';
import 'package:test/test.dart';

/// Relogio controlado pelo teste.
class _Relogio {
  DateTime agora;
  _Relogio(this.agora);
  DateTime call() => agora;
  void avancar(Duration d) => agora = agora.add(d);
}

void main() {
  final inicio = DateTime.utc(2026, 11, 14, 12);

  group('LimitadorJanela (sem banco)', () {
    test('aceita ate o maximo e recusa a seguinte', () {
      final relogio = _Relogio(inicio);
      final limite = LimitadorJanela(
        maximo: 3,
        janela: const Duration(minutes: 1),
        agora: relogio.call,
      );
      expect(limite.registrar('a'), isNull);
      expect(limite.registrar('a'), isNull);
      expect(limite.registrar('a'), isNull);
      expect(limite.registrar('a'), 60);
    });

    test('Retry-After conta a partir da entrada mais antiga da janela', () {
      final relogio = _Relogio(inicio);
      final limite = LimitadorJanela(
        maximo: 2,
        janela: const Duration(minutes: 1),
        agora: relogio.call,
      );
      limite.registrar('a'); // T+0
      relogio.avancar(const Duration(seconds: 20));
      limite.registrar('a'); // T+20
      relogio.avancar(const Duration(seconds: 15)); // T+35
      // Libera em T+60 (entrada de T+0): faltam 25 s.
      expect(limite.registrar('a'), 25);
    });

    test('Retry-After arredonda para cima e nunca e menor que 1', () {
      final relogio = _Relogio(inicio);
      final limite = LimitadorJanela(
        maximo: 1,
        janela: const Duration(minutes: 1),
        agora: relogio.call,
      );
      limite.registrar('a');
      relogio.avancar(const Duration(milliseconds: 59999));
      expect(limite.registrar('a'), 1);
    });

    test('janela desliza: a entrada sai exatamente na borda', () {
      final relogio = _Relogio(inicio);
      final limite = LimitadorJanela(
        maximo: 1,
        janela: const Duration(minutes: 1),
        agora: relogio.call,
      );
      expect(limite.registrar('a'), isNull);
      relogio.avancar(const Duration(seconds: 59));
      expect(limite.registrar('a'), isNotNull);
      relogio.avancar(const Duration(seconds: 1)); // exatos 60 s
      expect(limite.registrar('a'), isNull);
    });

    test('chaves sao independentes', () {
      final relogio = _Relogio(inicio);
      final limite = LimitadorJanela(
        maximo: 1,
        janela: const Duration(minutes: 1),
        agora: relogio.call,
      );
      expect(limite.registrar((1, 5)), isNull);
      expect(limite.registrar((1, 5)), isNotNull);
      expect(limite.registrar((1, 6)), isNull);
    });

    test(
      'esgotado o teto de chaves, chave nova e recusada; a antiga ociosa sai',
      () {
        final relogio = _Relogio(inicio);
        final limite = LimitadorJanela(
          maximo: 1,
          janela: const Duration(minutes: 1),
          maxChaves: 2,
          agora: relogio.call,
        );
        expect(limite.registrar('a'), isNull);
        expect(limite.registrar('b'), isNull);
        // Teto cheio e ambas ativas: chave nova falha fechada.
        expect(limite.registrar('c'), 60);

        relogio.avancar(const Duration(minutes: 1));
        // 'a' e 'b' ociosas saem; 'c' cabe.
        expect(limite.registrar('c'), isNull);
      },
    );

    test('parametros invalidos sao recusados na construcao', () {
      expect(
        () => LimitadorJanela(maximo: 0, janela: const Duration(minutes: 1)),
        throwsArgumentError,
      );
      expect(
        () => LimitadorJanela(maximo: 1, janela: Duration.zero),
        throwsArgumentError,
      );
    });
  });
}
