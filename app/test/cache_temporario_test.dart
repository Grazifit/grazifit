import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grazifit_app/core/state/cache_temporario.dart';

void main() {
  testWidgets('Reutiliza a consulta e respeita invalidação e expiração', (
    tester,
  ) async {
    var consultas = 0;
    final provider = FutureProvider.autoDispose<int>(
      (ref) => carregarComCacheTemporario(ref, () async => ++consultas),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    Future<int> visitar() async {
      final inscricao = container.listen(provider, (_, _) {});
      try {
        return await container.read(provider.future);
      } finally {
        inscricao.close();
      }
    }

    expect(await visitar(), 1);
    await tester.pump(const Duration(seconds: 10));
    expect(await visitar(), 1);

    container.invalidate(provider);
    expect(await visitar(), 2);

    await tester.pump(const Duration(seconds: 31));
    expect(await visitar(), 3);
    container.dispose();
  });
}
