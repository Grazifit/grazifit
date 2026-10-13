import 'dart:math';
import 'package:flutter/material.dart';

class FundoTela extends StatelessWidget {
  const FundoTela({super.key, required this.child});

  final Widget child;

  static const _gradiente = RadialGradient(
    center: Alignment(0.0, -0.85),
    radius: 1.3,
    colors: [
      Color(0xFFF3F3F3),
      Color(0xFFC7C5C4),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: _gradiente,
      ),
      child: CustomPaint(
        painter: _GranulacaoPainter(),
        child: child,
      ),
    );
  }
}

class _GranulacaoPainter extends CustomPainter {
  final Random _random = Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Quantidade de pontos
    final quantidade = (size.width * size.height / 20).round();

    for (int i = 0; i < quantidade; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;

      final claro = _random.nextBool();

      paint.color = claro
          ? Colors.white.withValues(alpha: 0.035)
          : Colors.black.withValues(alpha: 0.025);

      paint.strokeWidth = 0.5;

      canvas.drawCircle(
        Offset(x, y),
        _random.nextDouble() * 0.8,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}