import 'dart:math' as math;

import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.iniciarComErro = false});

  /// Abre diretamente o estado de credenciais inválidas para inspeção visual.
  final bool iniciarComErro;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _verde = Color(0xFF005B50);
  static const _borda = Color(0xFFBDCECA);
  static const _vermelho = Color(0xFFF21D1D);

  final _emailController = TextEditingController(text: 'ana.ramos@exemplo.com');
  final _senhaController = TextEditingController(text: '12345678');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _FundoLogin(),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _GranulacaoPainter()),
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
                          fontSize: 11,
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
              // Protótipo visual: sem chamada HTTP, demonstra o estado do mockup.
              onPressed: () => setState(() => _credenciaisInvalidas = true),
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
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
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
            style: const TextStyle(fontSize: 13, color: Color(0xFF2D3836)),
            onChanged: (_) => _limparErro(),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 11),
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

class _FundoLogin extends StatelessWidget {
  const _FundoLogin();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF1A65E), Color(0xFFE96D4E), Color(0xFF075D50)],
              stops: [0, 0.48, 1],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-1, -0.9),
              radius: 1.3,
              colors: [Color(0xFF554980), Color(0xB78D5C79), Color(0x00554A7E)],
              stops: [0, 0.52, 1],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(1, -1),
              radius: 1.1,
              colors: [Color(0xFFFFBB52), Color(0xCFF38B4D), Color(0x00F38B4D)],
              stops: [0, 0.48, 1],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.95, 0.72),
              radius: 0.9,
              colors: [Color(0xFF4D865D), Color(0xC43C8062), Color(0x003C8062)],
              stops: [0, 0.52, 1],
            ),
          ),
        ),
      ],
    );
  }
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
