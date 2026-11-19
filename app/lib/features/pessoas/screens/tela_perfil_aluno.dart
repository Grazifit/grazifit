import 'package:flutter/material.dart';

import '../../../core/data/repositorios.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/screens/login_screen.dart';
import '../../avaliacoes/screens/tela_evolucao_aluno.dart';
import '../../treinos/screens/tela_treino_aluno.dart';
import '../data/perfil_aluno.dart';
import '../data/perfil_repository.dart';
import 'editar_perfil_aluno.dart';

/// Tela de perfil do aluno: cabeçalho com nome e data de entrada,
/// cards com dados de contato/documento, seção expansível de
/// informações de saúde e botão para editar o perfil.
///
/// Os dados vêm de um [PerfilRepository]. Se nenhum for informado, usa o
/// definido em `core/data/repositorios.dart`.
class TelaPerfilAluno extends StatefulWidget {
  final PerfilRepository? repository;

  const TelaPerfilAluno({super.key, this.repository});

  @override
  State<TelaPerfilAluno> createState() => _TelaPerfilAlunoState();
}

class _TelaPerfilAlunoState extends State<TelaPerfilAluno> {
  static const Color kGreen = Color(0xFF1B5E3C);
  static const Color kHeader = Color(0xFF2A327B); // igual ao fundo da logo
  static const String kLogoAsset = 'lib/features/pessoas/widgets/logo_perfil.png';
  static const Color kBackground = Color(0xFFECEBEE);
  static const Color kHint = Color(0xFF9AA0A6);

  bool _saudeAberta = false;
  int _navSelecionado = 3; // Perfil já selecionado

  late final PerfilRepository _repo;
  late Future<PerfilAluno> _future;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? Repositorios.perfil;
    _future = _repo.buscarPerfil();
  }

  void _recarregar() {
    setState(() {
      _future = _repo.buscarPerfil();
    });
  }

  Future<void> _abrirEdicao(PerfilAluno perfil) async {
    // A tela de edição salva pelo repositório e devolve `true` quando deu
    // certo; aí recarregamos para mostrar os dados atualizados.
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditarPerfilAlunoScreen(
          perfil: perfil,
          repository: _repo,
        ),
      ),
    );
    if (salvou == true && mounted) _recarregar();
  }

  Future<void> _sair() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Você precisará entrar novamente para acessar o app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.vermelho),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.sair();
      if (!mounted) return;
      // Remove todas as telas anteriores: o "voltar" não retorna ao app logado.
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível sair. Tente novamente.'),
        ),
      );
    }
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
    } else if (index == 2) {
      // Evolução: troca esta tela pela de evolução.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TelaEvolucaoAluno()),
      );
    } else {
      setState(() => _navSelecionado = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<PerfilAluno>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: kGreen),
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _buildErro();
            }
            return _buildConteudo(snapshot.data!);
          },
        ),
      ),
      bottomNavigationBar: _buildNavInferior(),
    );
  }

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.black45),
            const SizedBox(height: 12),
            const Text(
              'Não foi possível carregar seu perfil.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _recarregar,
              style: OutlinedButton.styleFrom(
                foregroundColor: kGreen,
                side: const BorderSide(color: kGreen),
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudo(PerfilAluno perfil) {
    return Column(
      children: [
        _buildCabecalho(perfil),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCampo(valor: perfil.email, rotulo: 'E-mail'),
                const SizedBox(height: 10),
                _buildCampo(valor: perfil.telefone, rotulo: 'Telefone'),
                const SizedBox(height: 10),
                _buildCampo(valor: perfil.cpf, rotulo: 'CPF'),
                const SizedBox(height: 10),
                _buildCampo(valor: perfil.nascimento, rotulo: 'Nascimento'),
                const SizedBox(height: 18),
                _buildInformacoesSaude(perfil),
                const SizedBox(height: 20),
                _buildBotaoEditar(perfil),
                const SizedBox(height: 12),
                _buildBotaoSair(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCabecalho(PerfilAluno perfil) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: kHeader,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: [
          // Proporção da imagem (427 x 242). O fundo dela é o mesmo azul do
          // cabeçalho, então a logo se mistura sem moldura.
          Image.asset(
            kLogoAsset,
            width: 99,
            height: 56,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perfil.nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aluna desde ${perfil.desde}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampo({required String valor, required String rotulo}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rotulo,
            style: const TextStyle(fontSize: 11.5, color: kHint),
          ),
        ],
      ),
    );
  }

  Widget _buildInformacoesSaude(PerfilAluno perfil) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _saudeAberta = !_saudeAberta),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Informações de saúde',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              AnimatedRotation(
                turns: _saudeAberta ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down,
                    color: Colors.black54),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _saudeAberta
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLinhaSaude(
                        'Restrição médica',
                        perfil.restricaoMedica,
                      ),
                      const SizedBox(height: 10),
                      _buildLinhaSaude(
                        'Observações de saúde',
                        perfil.observacoesSaude,
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Informado pelo aluno no primeiro acesso; se vazio, mostra "Não informado".
  Widget _buildLinhaSaude(String rotulo, String? valor) {
    final texto = valor?.trim() ?? '';
    final informado = texto.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: const TextStyle(fontSize: 11.5, color: kHint)),
        const SizedBox(height: 2),
        Text(
          informado ? texto : 'Não informado',
          style: TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: informado ? Colors.black87 : kHint,
          ),
        ),
      ],
    );
  }

  Widget _buildBotaoEditar(PerfilAluno perfil) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: () => _abrirEdicao(perfil),
        style: OutlinedButton.styleFrom(
          foregroundColor: kGreen,
          side: const BorderSide(color: kGreen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Editar perfil',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildBotaoSair() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _sair,
        icon: const Icon(Icons.logout, size: 18),
        label: const Text(
          'Sair da conta',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.vermelho,
          side: const BorderSide(color: AppColors.vermelho),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(itens.length, (index) {
            final selecionado = _navSelecionado == index;
            final item = itens[index];
            return GestureDetector(
              onTap: () => _selecionarNav(index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.$1,
                    size: 22,
                    color: selecionado ? Colors.white : Colors.white54,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.$2,
                    style: TextStyle(
                      fontSize: 11,
                      color: selecionado ? Colors.white : Colors.white54,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}