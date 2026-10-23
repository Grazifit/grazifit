import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../treinos/screens/tela_treino_aluno.dart';
import 'tela_registrar_medida_aluno.dart';

/// Tela de evolução do aluno: peso e IMC atuais, gráfico mensal
/// e botão para registrar uma nova medida.
class TelaEvolucaoAluno extends StatefulWidget {
  const TelaEvolucaoAluno({super.key});

  @override
  State<TelaEvolucaoAluno> createState() => _TelaEvolucaoAlunoState();
}

class _TelaEvolucaoAlunoState extends State<TelaEvolucaoAluno> {
  static const Color kGreen = AppColors.verde;
  static const Color kBackground = AppColors.fundo;
  static const Color kImc = Color(0xFF2E3A8C);

  static const List<String> _mesesAbrev = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];

  int _navSelecionado = 2;

  // Dados de exemplo. Troque pela chamada ao backend.
  // TODO: buscar altura e histórico de medidas do backend.
  final double _alturaM = 1.68;
  final List<_Medida> _medidas = [
    _Medida('mar', 70.0),
    _Medida('abr', 71.0),
    _Medida('mai', 70.6),
    _Medida('jun', 72.0),
    _Medida('jul', 72.5),
  ];

  double _imc(double peso) => peso / (_alturaM * _alturaM);

  String _fmt(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

  Future<void> _registrarMedida() async {
    final peso = await Navigator.of(context).push<double>(
      MaterialPageRoute(
        builder: (_) => TelaRegistrarMedidaAluno(alturaM: _alturaM),
      ),
    );
    if (peso == null || !mounted) return;

    // TODO: enviar a nova medida para o backend.
    final mes = _mesesAbrev[DateTime.now().month - 1];
    setState(() {
      final i = _medidas.indexWhere((m) => m.mes == mes);
      if (i >= 0) {
        _medidas[i] = _Medida(mes, peso);
      } else {
        _medidas.add(_Medida(mes, peso));
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medida registrada.')),
    );
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
    } else {
      setState(() => _navSelecionado = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pesos = _medidas.map((m) => m.peso).toList();
    final imcs = pesos.map(_imc).toList();
    final meses = _medidas.map((m) => m.mes).toList();
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
              child: _medidas.length < 2
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

class _Medida {
  final String mes;
  final double peso;
  const _Medida(this.mes, this.peso);
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