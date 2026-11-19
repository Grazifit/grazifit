import 'package:flutter/material.dart';

<<<<<<< HEAD
/// Cadastro administrativo de aluno, incluindo a ação para redefinir senha.
class CriarCadastroAlunoScreen extends StatefulWidget {
  const CriarCadastroAlunoScreen({
    super.key,
    this.nomeInicial,
    this.cpfInicial,
    this.emailInicial,
    this.nascimentoInicial,
    this.senhaRedefinida = false,
    this.onRedefinirSenha,
    this.onSalvarCadastro,
    this.onAbrirAvaliacao,
  });

  final String? nomeInicial;
  final String? cpfInicial;
  final String? emailInicial;
  final String? nascimentoInicial;
  final bool senhaRedefinida;
  final Future<void> Function()? onRedefinirSenha;
  final VoidCallback? onSalvarCadastro;
  final VoidCallback? onAbrirAvaliacao;
=======
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
>>>>>>> origin/dev

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
<<<<<<< HEAD

  bool _enderecoAberto = false;
  bool _senhaRedefinida = false;
  bool _redefinindoSenha = false;

  @override
  void initState() {
    super.initState();
    _nomeCtrl.text = widget.nomeInicial ?? '';
    _cpfCtrl.text = widget.cpfInicial ?? '';
    _emailCtrl.text = widget.emailInicial ?? '';
    _nascCtrl.text = widget.nascimentoInicial ?? '';
    _senhaRedefinida = widget.senhaRedefinida;
  }

  @override
  void didUpdateWidget(covariant CriarCadastroAlunoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nomeInicial != widget.nomeInicial) {
      _nomeCtrl.text = widget.nomeInicial ?? '';
    }
    if (oldWidget.cpfInicial != widget.cpfInicial) {
      _cpfCtrl.text = widget.cpfInicial ?? '';
    }
    if (oldWidget.emailInicial != widget.emailInicial) {
      _emailCtrl.text = widget.emailInicial ?? '';
    }
    if (oldWidget.nascimentoInicial != widget.nascimentoInicial) {
      _nascCtrl.text = widget.nascimentoInicial ?? '';
    }
    if (oldWidget.senhaRedefinida != widget.senhaRedefinida) {
      _senhaRedefinida = widget.senhaRedefinida;
    }
  }
=======
  final _senhaCtrl = TextEditingController();

  bool _enderecoAberto = false;
  bool _senhaVisivel = false;
  bool _salvando = false;
>>>>>>> origin/dev

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cpfCtrl.dispose();
    _emailCtrl.dispose();
    _nascCtrl.dispose();
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Scaffold(
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
                        if (_senhaRedefinida) ...[
                          _buildBannerSenhaRedefinida(),
                          const SizedBox(height: 20),
                        ],
                        _buildCamposDestacados(),
                        const SizedBox(height: 20),
                        _buildEnderecoExpansivel(),
                        const SizedBox(height: 12),
                        _buildAvaliacaoFisica(),
                        _buildRedefinirSenha(),
                      ],
                    ),
                  ),
                ),
                _buildBotaoSalvar(context),
              ],
            ),
          ),
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
          'Informações de saúde são preenchidas pelo próprio aluno '
          'no primeiro acesso.',
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
            onPressed: _abrirAvaliacao,
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

  Widget _buildRedefinirSenha() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Redefinir senha',
            style: TextStyle(fontSize: 15, color: Colors.black87),
          ),
          TextButton(
            onPressed: _redefinindoSenha ? null : _confirmarRedefinicaoSenha,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: _redefinindoSenha
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
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

  Widget _buildBannerSenhaRedefinida() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kGreen,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        children: [
          Icon(Icons.check, color: Colors.white, size: 22),
          SizedBox(width: 14),
          Text(
            'Senha redefinida',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarRedefinicaoSenha() async {
    final nome = _nomeCtrl.text.trim();
    final complementoNome = nome.isEmpty ? ' do aluno' : ' de $nome';
    final confirmou = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar confirmação',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Redefinir a senha?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'A senha atual$complementoNome deixa de valer. Este app '
                      'não tem recuperação por e-mail — a nova senha é '
                      'combinada na academia.',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: Color(0xFF374141),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text(
                            'Voltar',
                            style: TextStyle(color: kGreen),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: kGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Redefinir'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
            child: child,
          ),
        );
      },
    );

    if (confirmou != true || !mounted) return;

    final redefinirSenha = widget.onRedefinirSenha;
    if (redefinirSenha == null) {
      _mostrarMensagem('Redefinição aguardando integração.');
      return;
    }

    setState(() => _redefinindoSenha = true);
    try {
      await redefinirSenha();
      if (!mounted) return;
      setState(() => _senhaRedefinida = true);
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem(
        'Não foi possível redefinir a senha. Tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _redefinindoSenha = false);
    }
  }

  void _abrirAvaliacao() {
    final abrirAvaliacao = widget.onAbrirAvaliacao;
    if (abrirAvaliacao == null) {
      _mostrarMensagem('Avaliação física aguardando integração.');
      return;
    }
    abrirAvaliacao();
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
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
<<<<<<< HEAD
          onPressed: widget.onSalvarCadastro ??
              () => _mostrarMensagem('Cadastro aguardando integração.'),
=======
          onPressed: _salvando ? null : _salvar,
>>>>>>> origin/dev
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
