import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/material.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/botao_primario.dart';
import '../../../core/design_system/components/campo_texto.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/design_system/tokens/cores_provisorias.dart';
import '../../../core/utils/formatadores.dart';
import '../../../core/utils/validadores.dart';
import '../widgets/endereco_opcional.dart';

@immutable
class DadosCadastroAluno {
  const DadosCadastroAluno({
    this.id,
    required this.nome,
    required this.cpf,
    required this.email,
    required this.nascimento,
  });

  final String? id;
  final String nome;
  final String cpf;
  final String email;
  final String nascimento;
}

typedef SalvarCadastroAluno = Future<void> Function(DadosCadastroAluno dados);
typedef RedefinirSenhaAluno = Future<void> Function(DadosCadastroAluno aluno);

class CriarCadastroAlunoScreen extends StatefulWidget {
  const CriarCadastroAlunoScreen({
    super.key,
    this.dadosIniciais,
    this.modoEdicao = false,
    this.onSalvar,
    this.onAbrirAvaliacao,
    this.onRedefinirSenha,
  });

  final DadosCadastroAluno? dadosIniciais;
  final bool modoEdicao;
  final SalvarCadastroAluno? onSalvar;
  final VoidCallback? onAbrirAvaliacao;
  final RedefinirSenhaAluno? onRedefinirSenha;

  @override
  State<CriarCadastroAlunoScreen> createState() =>
      _CriarCadastroAlunoScreenState();
}

class _CriarCadastroAlunoScreenState extends State<CriarCadastroAlunoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _cpfController;
  late final TextEditingController _emailController;
  late final TextEditingController _nascimentoController;

  bool _senhaRedefinida = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final dados = widget.dadosIniciais;
    _nomeController =
        TextEditingController(text: dados?.nome ?? 'Ana Beatriz Ramos');
    _cpfController =
        TextEditingController(text: dados?.cpf ?? '000.000.000-00');
    _emailController = TextEditingController(
      text: dados?.email ?? 'ana.ramos@exemplo.com',
    );
    _nascimentoController =
        TextEditingController(text: dados?.nascimento ?? '14/07/1996');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _nascimentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FundoTela(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBarInterna(
          context,
          widget.modoEdicao ? 'Editar aluno' : 'Cadastro de aluno',
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (_senhaRedefinida) _bannerSenhaRedefinida(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      CampoTexto(
                        label: 'Nome completo',
                        controller: _nomeController,
                        helper: 'Como aparece no app',
                        textCapitalization: TextCapitalization.words,
                        validator: Validadores.nome,
                      ),
                      const SizedBox(height: 20),
                      CampoTexto(
                        label: 'CPF',
                        controller: _cpfController,
                        helper: '11 dígitos',
                        keyboardType: TextInputType.number,
                        inputFormatters: [CpfInputFormatter()],
                        validator: Validadores.cpf,
                      ),
                      const SizedBox(height: 20),
                      CampoTexto(
                        label: 'E-mail',
                        controller: _emailController,
                        helper: 'Será a credencial de acesso',
                        keyboardType: TextInputType.emailAddress,
                        validator: Validadores.email,
                      ),
                      const SizedBox(height: 20),
                      CampoTexto(
                        label: 'Nascimento',
                        controller: _nascimentoController,
                        helper: 'Anterior a hoje',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: [DataInputFormatter()],
                        validator: Validadores.nascimento,
                      ),
                      const SizedBox(height: 24),
                      const EnderecoOpcional(),
                      const SizedBox(height: 16),
                      const Text(
                        'Informações de saúde são preenchidas pelo próprio '
                        'aluno no primeiro acesso.',
                        style: TextStyle(
                          color: Color(0xFF78827F),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _acoesDoAluno(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          color: const Color(0xFFE7E9E8),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 15, 16, 16),
            child: BotaoPrimario(
              texto: _salvando
                  ? 'Salvando...'
                  : widget.modoEdicao
                      ? 'Salvar alterações'
                      : 'Salvar cadastro',
              onPressed: _salvando ? null : _salvar,
            ),
          ),
        ),
      ),
    );
  }

  Widget _bannerSenhaRedefinida() {
    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF176B3A),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        children: [
          Icon(Icons.check, color: Colors.white, size: 22),
          SizedBox(width: 14),
          Text(
            'Senha redefinida',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _acoesDoAluno() {
    return Material(
      color: Colors.white,
      child: Column(
        children: [
          _AcaoCadastroAluno(
            titulo: 'Avaliação física',
            onTap: widget.onAbrirAvaliacao ?? _avisarAvaliacaoPendente,
          ),
          const Divider(height: 1, color: Color(0xFFD4DEDB)),
          _AcaoCadastroAluno(
            titulo: 'Redefinir senha',
            onTap: _confirmarRedefinicaoSenha,
          ),
        ],
      ),
    );
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _salvando = true);
    try {
      final dados = _dadosAtuais();
      if (widget.onSalvar == null) {
        _mostrarAviso('Cadastro preenchido localmente.');
      } else {
        await widget.onSalvar!(dados);
        if (mounted) _mostrarAviso('Cadastro salvo.');
      }
    } catch (_) {
      if (mounted) _mostrarAviso('Não foi possível salvar o cadastro.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _confirmarRedefinicaoSenha() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Redefinir a senha?'),
        content: Text(
          'A senha atual de ${_nomeController.text.trim()} deixa de valer. '
          'Este app não tem recuperação por e-mail — a nova senha é '
          'combinada na academia.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: corInstitucional,
            ),
            onPressed: () => Navigator.of(contextoDialogo).pop(true),
            child: const Text('Redefinir'),
          ),
        ],
      ),
    );

    if (confirmou != true || !mounted) return;

    try {
      final onRedefinirSenha = widget.onRedefinirSenha;
      if (onRedefinirSenha != null) {
        await onRedefinirSenha(_dadosAtuais());
      }
      if (mounted) setState(() => _senhaRedefinida = true);
    } catch (_) {
      if (mounted) _mostrarAviso('Não foi possível redefinir a senha.');
    }
  }

  void _avisarAvaliacaoPendente() {
    _mostrarAviso('A avaliação física aguarda integração.');
  }

  DadosCadastroAluno _dadosAtuais() => DadosCadastroAluno(
        id: widget.dadosIniciais?.id,
        nome: _nomeController.text.trim(),
        cpf: _cpfController.text.trim(),
        email: _emailController.text.trim(),
        nascimento: _nascimentoController.text.trim(),
      );

  void _mostrarAviso(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }
}

class _AcaoCadastroAluno extends StatelessWidget {
  const _AcaoCadastroAluno({required this.titulo, required this.onTap});

  final String titulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 71,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: Color(0xFF33413F),
                    fontSize: 14,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Text(
                  'Abrir',
                  style: TextStyle(
                    color: corInstitucional,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Container com borda tracejada disponível para os demais formulários.
class DashedBorderContainer extends StatelessWidget {
  const DashedBorderContainer({
    super.key,
    required this.child,
    this.color = Colors.blue,
    this.strokeWidth = 1.5,
    this.dashLength = 5,
    this.gap = 4,
    this.radius = 8,
  });

  final Widget child;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gap;
  final double radius;

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
  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gap,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gap;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final bounds = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(bounds, Radius.circular(radius)));

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end =
            (distance + dashLength).clamp(0.0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}
