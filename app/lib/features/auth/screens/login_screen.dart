import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/auth_controller.dart';
import '../state/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.iniciarComErro = false});

  /// Abre diretamente o estado de credenciais inválidas para inspeção visual.
  final bool iniciarComErro;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _verde = Color(0xFF005B50);
  static const _borda = Color(0xFFBDCECA);
  static const _vermelho = Color(0xFFF21D1D);
  static const _fonte = 'Barlow';

  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  late bool _credenciaisInvalidas;

  @override
  void initState() {
    super.initState();
    _credenciaisInvalidas = widget.iniciarComErro;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _limparErro() {
    if (_credenciaisInvalidas) {
      setState(() => _credenciaisInvalidas = false);
    }
  }

  Future<void> _entrar() async {
    _limparErro();

    final sessao = await ref
        .read(authControllerProvider.notifier)
        .login(_emailController.text, _senhaController.text);

    if (!mounted) return;

    if (sessao == null) {
      final credenciaisInvalidas =
          ref.read(authControllerProvider).status ==
          AuthStatus.credenciaisInvalidas;
      if (_credenciaisInvalidas != credenciaisInvalidas) {
        setState(() => _credenciaisInvalidas = credenciaisInvalidas);
      }
      return;
    }

    // Sucesso: o guard de rotas (core/routing) leva para a tela do papel.
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Theme(
      data: tema.copyWith(
        textTheme: tema.textTheme.apply(fontFamily: _fonte),
        primaryTextTheme: tema.primaryTextTheme.apply(fontFamily: _fonte),
      ),
      child: _tela(context),
    );
  }

  Widget _tela(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _FundoLogin(),
                IgnorePointer(child: CustomPaint(painter: _GranulacaoPainter())),
              ],
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final larguraCartao = math
                    .min(264.0, math.max(0.0, constraints.maxWidth - 48))
                    .toDouble();

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/marca.png',
                            width: 198,
                            height: 176,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                          const SizedBox(height: 30),
                          _cartaoLogin(larguraCartao),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartaoLogin(double largura) {
    return Container(
      width: largura,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _campo(
            rotulo: 'E-mail',
            controller: _emailController,
            tipoTeclado: TextInputType.emailAddress,
          ),
          const SizedBox(height: 35),
          _campo(
            rotulo: 'Senha',
            controller: _senhaController,
            ocultarTexto: true,
            destacarErro: _credenciaisInvalidas,
          ),
          SizedBox(
            height: 33,
            child: _credenciaisInvalidas
                ? const Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'E-mail ou senha inválidos',
                        style: TextStyle(
                          color: _vermelho,
                          fontSize: 12,
                          height: 1.1,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _entrar,
              style: ElevatedButton.styleFrom(
                backgroundColor: _verde,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Entrar',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: Center(
              child: TextButton(
                // A recuperação de senha está fora do escopo F-01.
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: _verde,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Esqueci minha senha',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campo({
    required String rotulo,
    required TextEditingController controller,
    TextInputType? tipoTeclado,
    bool ocultarTexto = false,
    bool destacarErro = false,
  }) {
    final corBorda = destacarErro ? _vermelho : _borda;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(
            color: Color(0xFF34423F),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            keyboardType: tipoTeclado,
            obscureText: ocultarTexto,
            autocorrect: false,
            enableSuggestions: !ocultarTexto,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.2,
              color: Color(0xFF2D3836),
            ),
            onChanged: (_) => _limparErro(),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              // O TextField afrouxa a altura imposta pelo SizedBox; a altura de 48
              // vem daqui: linha de 14 x 1,2 = 16,8 + 2 x 15,6 de respiro.
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 15.6,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: corBorda),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: corBorda),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: _verde, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Fundo em malha de cores amostradas do Figma (3 colunas x 21 linhas),
/// interpoladas por vértice. Substitui os degradês aproximados anteriores.
class _FundoLogin extends StatelessWidget {
  const _FundoLogin();

  static const _esquerda = [
    Color(0xFF47437A), Color(0xFF4B4579), Color(0xFF5A4875),
    Color(0xFF7A516B), Color(0xFFA15D5F), Color(0xFFC06757),
    Color(0xFFCF6A53), Color(0xFFD46C51), Color(0xFFD66D51),
    Color(0xFFD76F4E), Color(0xFFD7704A), Color(0xFFD17246),
    Color(0xFFC17344), Color(0xFFA57447), Color(0xFF7F734A),
    Color(0xFF5C714E), Color(0xFF437052), Color(0xFF377054),
    Color(0xFF357054), Color(0xFF3B7053), Color(0xFF477051),
  ];

  static const _centro = [
    Color(0xFFCA9C6A), Color(0xFFC7986A), Color(0xFFBD8967),
    Color(0xFFB27C64), Color(0xFFC27A5A), Color(0xFFCF7752),
    Color(0xFFD6764F), Color(0xFFD97A4F), Color(0xFFDB7E51),
    Color(0xFFDD8250), Color(0xFFDD834E), Color(0xFFDA844C),
    Color(0xFFD0824A), Color(0xFFB97E4A), Color(0xFF95784B),
    Color(0xFF6E714F), Color(0xFF506D54), Color(0xFF416C57),
    Color(0xFF3B6B58), Color(0xFF2F6B58), Color(0xFF346C57),
  ];

  static const _direita = [
    Color(0xFFF0B664), Color(0xFFF0B664), Color(0xFFEEB161),
    Color(0xFFEAA75D), Color(0xFFE39756), Color(0xFFDE884E),
    Color(0xFFDD824C), Color(0xFFDF884E), Color(0xFFE18F51),
    Color(0xFFE49553), Color(0xFFE49653), Color(0xFFE49653),
    Color(0xFFDF9250), Color(0xFFCD894E), Color(0xFFAB7D4D),
    Color(0xFF817150), Color(0xFF5D6B56), Color(0xFF4B695A),
    Color(0xFF42675C), Color(0xFF43675C), Color(0xFF46675A),
  ];

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(
      child: CustomPaint(
        painter: _MalhaPainter(_esquerda, _centro, _direita),
      ),
    );
  }
}

class _MalhaPainter extends CustomPainter {
  const _MalhaPainter(this.esquerda, this.centro, this.direita);

  final List<Color> esquerda;
  final List<Color> centro;
  final List<Color> direita;

  @override
  void paint(Canvas canvas, Size size) {
    final colunas = [esquerda, centro, direita];
    final linhas = esquerda.length;
    final posicoes = <Offset>[];
    final cores = <Color>[];
    for (var r = 0; r < linhas; r++) {
      final y = size.height * r / (linhas - 1);
      for (var c = 0; c < 3; c++) {
        posicoes.add(Offset(size.width * c / 2, y));
        cores.add(colunas[c][r]);
      }
    }
    final indices = <int>[];
    for (var r = 0; r < linhas - 1; r++) {
      for (var c = 0; c < 2; c++) {
        final a = r * 3 + c;
        final b = a + 1;
        final d = a + 3;
        final e = d + 1;
        indices.addAll([a, b, d, b, e, d]);
      }
    }
    final vertices = ui.Vertices(
      ui.VertexMode.triangles,
      posicoes,
      colors: cores,
      indices: indices,
    );
    canvas.drawVertices(vertices, BlendMode.dst, Paint());
    vertices.dispose();
  }

  @override
  bool shouldRepaint(covariant _MalhaPainter oldDelegate) => false;
}

class _GranulacaoPainter extends CustomPainter {
  _GranulacaoPainter() : _aleatorio = math.Random(42);

  final math.Random _aleatorio;

  @override
  void paint(Canvas canvas, Size size) {
    final tinta = Paint();
    final quantidade = (size.width * size.height / 40).round();

    for (var i = 0; i < quantidade; i++) {
      final claro = _aleatorio.nextBool();
      tinta.color = claro
          ? Colors.white.withValues(alpha: 0.025)
          : Colors.black.withValues(alpha: 0.02);
      canvas.drawCircle(
        Offset(
          _aleatorio.nextDouble() * size.width,
          _aleatorio.nextDouble() * size.height,
        ),
        _aleatorio.nextDouble() * 0.65,
        tinta,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GranulacaoPainter oldDelegate) => false;
}
