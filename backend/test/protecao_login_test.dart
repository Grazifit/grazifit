import 'package:grazifit_backend/features/auth/protecao_login.dart';
import 'package:test/test.dart';

void main() {
  late DateTime agora;

  setUp(() => agora = DateTime.utc(2026, 1, 1));

  test('IP usa janela deslizante de 15 minutos', () {
    final protecao = ProtecaoLogin(agora: () => agora, maxTentativasIp: 2);

    expect(protecao.registrarIp('192.0.2.1'), isNull);
    expect(protecao.registrarIp('192.0.2.1'), isNull);
    expect(protecao.registrarIp('192.0.2.1')?.segundos, 900);
    expect(protecao.registrarIp('192.0.2.2'), isNull);

    agora = agora.add(const Duration(minutes: 15));
    expect(protecao.registrarIp('192.0.2.1'), isNull);
  });

  test('tentativa fora da janela nao provoca infracao', () {
    final protecao = ProtecaoLogin(agora: () => agora, maxTentativasIp: 2);
    const ip = '192.0.2.20';

    expect(protecao.registrarIp(ip), isNull);
    agora = agora.add(const Duration(minutes: 14));
    expect(protecao.registrarIp(ip), isNull);
    agora = agora.add(const Duration(minutes: 2));
    expect(protecao.registrarIp(ip), isNull);
    expect(protecao.registrarIp(ip)?.segundos, 900);
  });

  test('cada nova infracao aumenta 15 minutos; a setima e permanente', () {
    final protecao = ProtecaoLogin(agora: () => agora, maxTentativasIp: 2);
    const ip = '192.0.2.10';

    for (var infracao = 1; infracao <= 7; infracao++) {
      expect(protecao.registrarIp(ip), isNull);
      expect(protecao.registrarIp(ip), isNull);
      final bloqueio = protecao.registrarIp(ip);
      if (infracao == 7) {
        expect(bloqueio?.segundos, isNull);
        agora = agora.add(const Duration(days: 365));
        expect(protecao.registrarIp(ip)?.segundos, isNull);
      } else {
        expect(bloqueio?.segundos, infracao * 900);
        // Tentativas durante o bloqueio nao contam como outra infracao.
        expect(protecao.registrarIp(ip)?.segundos, infracao * 900);
        agora = agora.add(Duration(minutes: infracao * 15));
      }
    }

    // O estado e local: um novo processo recomeca sem bloqueio.
    final novoProcesso = ProtecaoLogin(agora: () => agora);
    expect(novoProcesso.registrarIp(ip), isNull);
  });

  test('estagio anterior permanece mesmo apos inatividade longa', () {
    final protecao = ProtecaoLogin(
      agora: () => agora,
      maxTentativasIp: 1,
      maxIdentificadores: 1,
    );
    const ip = '192.0.2.10';
    expect(protecao.registrarIp(ip), isNull);
    expect(protecao.registrarIp(ip)?.segundos, 900);

    agora = agora.add(const Duration(days: 2));
    expect(protecao.registrarIp('192.0.2.11')?.segundos, 60);
    expect(protecao.registrarIp(ip), isNull);
    expect(protecao.registrarIp(ip)?.segundos, 1800);
  });

  test('conta tem backoff progressivo e limite na janela', () {
    final protecao = ProtecaoLogin(
      agora: () => agora,
      maxTentativasConta: 3,
      inicioBackoff: 2,
    );

    expect(protecao.registrarConta('ADMIN@Exemplo.com'), isNull);
    protecao.registrarFalha('admin@exemplo.com');
    expect(protecao.registrarConta('admin@exemplo.com'), isNull);
    protecao.registrarFalha('admin@exemplo.com');
    expect(protecao.registrarConta(' admin@exemplo.com ')?.segundos, 1);

    agora = agora.add(const Duration(seconds: 1));
    expect(protecao.registrarConta('admin@exemplo.com'), isNull);
    protecao.registrarFalha('admin@exemplo.com');
    expect(protecao.registrarConta('admin@exemplo.com')?.segundos, 2);

    agora = agora.add(const Duration(seconds: 2));
    expect(protecao.registrarConta('admin@exemplo.com')?.segundos, 897);

    agora = agora.add(const Duration(minutes: 15));
    expect(protecao.registrarConta('admin@exemplo.com'), isNull);
  });

  test('sucesso limpa falhas da conta sem limpar limite de IP', () {
    final protecao = ProtecaoLogin(
      agora: () => agora,
      maxTentativasIp: 2,
      maxTentativasConta: 2,
      inicioBackoff: 1,
    );

    expect(protecao.registrarIp('192.0.2.1'), isNull);
    expect(protecao.registrarConta('admin@exemplo.com'), isNull);
    protecao.registrarFalha('admin@exemplo.com');
    protecao.registrarSucesso('admin@exemplo.com');
    expect(protecao.registrarConta('admin@exemplo.com'), isNull);
    expect(protecao.registrarIp('192.0.2.1'), isNull);
    expect(protecao.registrarIp('192.0.2.1'), isNotNull);
  });

  test('limite global nao cria fila e libera slot', () {
    final protecao = ProtecaoLogin(maxArgon2EmAndamento: 1);
    expect(protecao.reservarVerificacao(), isTrue);
    expect(protecao.reservarVerificacao(), isFalse);
    protecao.liberarVerificacao();
    expect(protecao.reservarVerificacao(), isTrue);
    protecao.liberarVerificacao();
  });

  test(
    'identificadores demais falham fechado em vez de crescer sem limite',
    () {
      final protecao = ProtecaoLogin(agora: () => agora, maxIdentificadores: 1);
      expect(protecao.registrarIp('192.0.2.1'), isNull);
      expect(protecao.registrarIp('192.0.2.2')?.segundos, 60);
      agora = agora.add(const Duration(minutes: 16));
      expect(protecao.registrarIp('192.0.2.2'), isNull);
    },
  );
}
