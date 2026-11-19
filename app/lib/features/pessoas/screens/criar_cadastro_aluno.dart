import 'package:flutter/material.dart';

/// Função chamada ao salvar o cadastro (ex.: envia os dados ao backend).
/// Deve lançar uma exceção se não for possível salvar.
typedef SalvarCadastroAluno = Future<void> Function({
  required String nome,
  required String cpf,
  required String email,
  required String nascimento,
  required String senha,
});

/// Tela de cadastro de aluno, com destaque nos campos principais
/// e campo de senha com opção de mostrar/ocultar.
class CriarCadastroAlunoScreen extends StatefulWidget {
  /// Chamada ao tocar em "Salvar cadastro". Enquanto não for informada, o botão
  /// só mostra a confirmação na tela, sem enviar nada.
  final SalvarCadastroAluno? onSalvar;

  const CriarCadastroAlunoScreen({super.key, this.onSalvar});

  @override
  State<CriarCadastroAlunoScreen> createState() =>
      _CriarCadastroAlunoScreenState();
}

class _CriarCadastroAlunoScreenState extends State<CriarCadastroAlunoScreen> {
  static const Color kGreen = Color(0xFF1B5E3C);
  static const Color kFieldFill = Color(0xFFF5F5F5);
  static const Color kHint = Color(0xFF9AA0A6);

  final _nomeCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _nascCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();

  bool _enderecoAberto = false;
  bool _senhaVisivel = false;
  bool _salvando = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cpfCtrl.dispose();
    _emailCtrl.dispose();
    _nascCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final onSalvar = widget.onSalvar;
    final messenger = ScaffoldMessenger.of(context);
    if (onSalvar == null) {
      // Sem integração ainda: só confirma na tela.
      messenger.showSnackBar(
        const SnackBar(content: Text('Cadastro salvo!')),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      await onSalvar(
        nome: _nomeCtrl.text.trim(),
        cpf: _cpfCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        nascimento: _nascCtrl.text.trim(),
        senha: _senhaCtrl.text,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Cadastro salvo!')),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar o cadastro. Tente novamente.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCamposDestacados(),
                    const SizedBox(height: 20),
                    _buildEnderecoExpansivel(),
                    const SizedBox(height: 12),
                    _buildAvaliacaoFisica(),
                  ],
                ),
              ),
            ),
            _buildBotaoSalvar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: kGreen),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Text(
            'Cadastro de aluno',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCamposDestacados() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCampo(
            label: 'Nome completo',
            controller: _nomeCtrl,
            hint: 'Como aparece no app',
          ),
          const SizedBox(height: 16),
          _buildCampo(
            label: 'CPF',
            controller: _cpfCtrl,
            hint: '11 dígitos',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildCampo(
            label: 'E-mail',
            controller: _emailCtrl,
            hint: 'Será a credencial de acesso',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildCampo(
            label: 'Nascimento',
            controller: _nascCtrl,
            hint: 'Anterior a hoje',
            keyboardType: TextInputType.datetime,
          ),
          const SizedBox(height: 16),
          _buildCampoSenha(),
        ],
      ),
    );
  }

  Widget _buildCampo({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: kFieldFill,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hint,
          style: const TextStyle(fontSize: 11.5, color: kHint),
        ),
      ],
    );
  }

  Widget _buildCampoSenha() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Senha',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _senhaCtrl,
          obscureText: !_senhaVisivel,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Digite uma senha',
            hintStyle: const TextStyle(color: kHint, fontSize: 14),
            filled: true,
            fillColor: kFieldFill,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                color: kHint,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _senhaVisivel = !_senhaVisivel;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Mínimo de 6 caracteres',
          style: TextStyle(fontSize: 11.5, color: kHint),
        ),
      ],
    );
  }

  Widget _buildEnderecoExpansivel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _enderecoAberto = !_enderecoAberto),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Endereço (opcional)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              AnimatedRotation(
                turns: _enderecoAberto ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down,
                    color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Informações de saúde são preenchidas pelo próprio aluno no primeiro acesso.',
          style: TextStyle(fontSize: 12.5, color: kHint, height: 1.4),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _enderecoAberto
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: [
                      _buildCampoSimples('CEP'),
                      const SizedBox(height: 12),
                      _buildCampoSimples('Rua'),
                      const SizedBox(height: 12),
                      _buildCampoSimples('Cidade'),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildCampoSimples(String label) {
    return TextField(
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: kFieldFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildAvaliacaoFisica() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE0E0E0)),
          bottom: BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Avaliação física',
            style: TextStyle(fontSize: 15, color: Colors.black87),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Abrir',
              style: TextStyle(
                color: kGreen,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoSalvar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: _salvando ? null : _salvar,
          style: ElevatedButton.styleFrom(
            backgroundColor: kGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Salvar cadastro',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

/// Container com borda tracejada (dashed) reutilizável.
class DashedBorderContainer extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gap;
  final double radius;

  const DashedBorderContainer({
    super.key,
    required this.child,
    this.color = Colors.blue,
    this.strokeWidth = 1.5,
    this.dashLength = 5,
    this.gap = 4,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        gap: gap,
        radius: radius,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gap;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gap,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}