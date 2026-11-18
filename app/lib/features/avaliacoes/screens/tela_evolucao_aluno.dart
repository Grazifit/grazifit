import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/avaliacao_repository.dart';

import '../../../core/theme/app_colors.dart';
import '../../treinos/screens/tela_treino_aluno.dart';
import '../../pessoas/screens/tela_perfil_aluno.dart';
import 'avaliacao_fisica_screen.dart';

/// Tela de evolução do aluno: peso e IMC atuais, gráfico mensal
/// e botão para registrar uma nova medida.
class TelaEvolucaoAluno extends ConsumerStatefulWidget {
  const TelaEvolucaoAluno({super.key});

  @override
  ConsumerState<TelaEvolucaoAluno> createState() => _TelaEvolucaoAlunoState();
}

class _TelaEvolucaoAlunoState extends ConsumerState<TelaEvolucaoAluno> {
  static const Color kGreen = AppColors.verde;
  static const Color kBackground = AppColors.fundo;
  static const Color kImc = Color(0xFF2E3A8C);

  int _navSelecionado = 2;
  String _fmt(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

  Future<void> _registrarMedida() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AvaliacaoFisicaScreen()),
    );
    if (mounted) ref.invalidate(historicoAvaliacoesProvider);
  }

  void _selecionarNav(int index) {
    if (index == 0) {
      // Agenda: volta para a tela anterior.
      Navigator.of(context).pop();
    } else if (index == 1) {
      // Treinos: troca esta tela pela de treinos.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TelaTreinosAluno()),
      );
    } else if (index == 3) {
      // Perfil: troca esta tela pela de perfil.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TelaPerfilAluno()),
      );
    } else {
      setState(() => _navSelecionado = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final historico = ref.watch(historicoAvaliacoesProvider);
    final medidas = historico.asData?.value ?? <MedidaAvaliacao>[];
    final pesos = medidas.map((m) => m.peso).toList();
    final imcs = medidas.map((m) => m.imc).toList();
    final meses = medidas.map((m) => m.rotulo).toList();
    final pesoAtual = pesos.isEmpty ? null : pesos.last;
    final imcAtual = imcs.isEmpty ? null : imcs.last;

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            const Text(
              'Evolução',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildIndicador(
                    'Peso',
                    pesoAtual == null ? '--' : '${_fmt(pesoAtual)} kg',
                    kGreen,
                  ),
                ),
                Expanded(
                  child: _buildIndicador(
                    'IMC',
                    imcAtual == null ? '--' : _fmt(imcAtual),
                    kImc,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 200,
              child: historico.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : historico.hasError
                  ? Center(
                      child: TextButton(
                        onPressed: () =>
                            ref.invalidate(historicoAvaliacoesProvider),
                        child: Text(mensagemAvaliacao(historico.error!)),
                      ),
                    )
                  : medidas.length < 2
                  ? const Center(
                      child: Text(
                        'Registre ao menos duas medidas para ver o gráfico.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    )
                  : CustomPaint(
                      size: Size.infinite,
                      painter: _GraficoEvolucaoPainter(
                        meses: meses,
                        pesos: pesos,
                        imcs: imcs,
                        corPeso: kGreen,
                        corImc: kImc,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegenda('Peso (kg)', kGreen, tracejado: false),
                const SizedBox(width: 24),
                _buildLegenda('IMC', kImc, tracejado: true),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 46,
              child: OutlinedButton(
                onPressed: _registrarMedida,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kGreen,
                  side: const BorderSide(color: kGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Registrar medida',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavInferior(),
    );
  }

  Widget _buildIndicador(String rotulo, String valor, Color cor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
      ],
    );
  }

  Widget _buildLegenda(String texto, Color cor, {required bool tracejado}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(24, 8),
          painter: _AmostraLinhaPainter(cor: cor, tracejado: tracejado),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(fontSize: 11.5, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildNavInferior() {
    final itens = [
      (Icons.calendar_today, 'Agenda'),
      (Icons.fitness_center, 'Treinos'),
      (Icons.trending_up, 'Evolução'),
      (Icons.person, 'Perfil'),
    ];
    return Container(
      color: kGreen,
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(itens.length, (index) {
            final selecionado = _navSelecionado == index;
            final item = itens[index];
            final cor = selecionado ? Colors.white : Colors.white54;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _selecionarNav(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 3,
                      width: 28,
                      decoration: BoxDecoration(
                        color: selecionado ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(item.$1, size: 22, color: cor),
                    const SizedBox(height: 4),
                    Text(item.$2, style: TextStyle(fontSize: 11, color: cor)),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Gráfico de linhas com duas séries (peso e IMC) sobre os meses.
///
/// Não há eixo Y: cada série é normalizada na sua própria faixa vertical
/// (peso em cima, IMC embaixo), então o gráfico mostra a tendência de cada
/// uma. Os valores exatos aparecem nos indicadores acima.
class _GraficoEvolucaoPainter extends CustomPainter {
  final List<String> meses;
  final List<double> pesos;
  final List<double> imcs;
  final Color corPeso;
  final Color corImc;

  _GraficoEvolucaoPainter({
    required this.meses,
    required this.pesos,
    required this.imcs,
    required this.corPeso,
    required this.corImc,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const alturaRotulos = 24.0;
    const margemX = 22.0;
    final alturaPlot = size.height - alturaRotulos;
    final n = pesos.length;
    if (n < 2 || alturaPlot <= 0) return;

    double xDe(int i) => margemX + i * (size.width - 2 * margemX) / (n - 1);

    List<Offset> pontos(List<double> v, double topo, double base) {
      final minV = v.reduce((a, b) => a < b ? a : b);
      final maxV = v.reduce((a, b) => a > b ? a : b);
      return List.generate(n, (i) {
        final t = maxV == minV ? 0.5 : (v[i] - minV) / (maxV - minV);
        return Offset(xDe(i), base - t * (base - topo));
      });
    }

    final pontosPeso = pontos(pesos, alturaPlot * 0.08, alturaPlot * 0.50);
    final pontosImc = pontos(imcs, alturaPlot * 0.50, alturaPlot * 0.92);

    _desenharLinha(canvas, pontosPeso, corPeso, tracejado: false);
    _desenharLinha(canvas, pontosImc, corImc, tracejado: true);

    final fundoMarcador = Paint()..color = Colors.white;
    for (final p in pontosPeso) {
      canvas.drawCircle(p, 4, fundoMarcador);
      canvas.drawCircle(
        p,
        4,
        Paint()
          ..color = corPeso
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    for (final p in pontosImc) {
      final r = Rect.fromCenter(center: p, width: 8, height: 8);
      canvas.drawRect(r, fundoMarcador);
      canvas.drawRect(
        r,
        Paint()
          ..color = corImc
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    for (int i = 0; i < n; i++) {
      final intervalo = (n / 5).ceil();
      if (i != n - 1 && i % intervalo != 0) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: meses[i],
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(xDe(i) - tp.width / 2, alturaPlot + 8));
    }
  }

  void _desenharLinha(
    Canvas canvas,
    List<Offset> pontos,
    Color cor, {
    required bool tracejado,
  }) {
    final path = Path()..moveTo(pontos.first.dx, pontos.first.dy);
    for (final p in pontos.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final paint = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;

    if (!tracejado) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final PathMetric m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        final fim = (d + 6).clamp(0, m.length).toDouble();
        canvas.drawPath(m.extractPath(d, fim), paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GraficoEvolucaoPainter old) =>
      old.pesos != pesos ||
      old.imcs != imcs ||
      old.meses != meses ||
      old.corPeso != corPeso ||
      old.corImc != corImc;
}

/// Amostra da linha (cheia ou tracejada) usada na legenda.
class _AmostraLinhaPainter extends CustomPainter {
  final Color cor;
  final bool tracejado;

  _AmostraLinhaPainter({required this.cor, required this.tracejado});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cor
      ..strokeWidth = 2;
    final y = size.height / 2;
    if (!tracejado) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }
    for (double x = 0; x < size.width; x += 7) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + 4).clamp(0, size.width).toDouble(), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmostraLinhaPainter old) =>
      old.cor != cor || old.tracejado != tracejado;
}
