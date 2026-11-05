import 'package:flutter/material.dart';

import '../../avaliacoes/screens/tela_evolucao_aluno.dart';
import '../../treinos/screens/tela_treino_aluno.dart';
import 'editar_perfil_aluno.dart';

/// Tela de perfil do aluno: cabeçalho com nome e data de entrada,
/// cards com dados de contato/documento, seção expansível de
/// informações de saúde e botão para editar o perfil.
class TelaPerfilAluno extends StatefulWidget {
  final String nome;
  final String desde;
  final String email;
  final String telefone;
  final String cpf;
  final String nascimento;

  const TelaPerfilAluno({
    super.key,
    this.nome = 'Ana Beatriz Ramos',
    this.desde = '12/03/2025',
    this.email = 'ana.ramos@exemplo.com',
    this.telefone = '(45) 90000-0000',
    this.cpf = '000.000.000-00',
    this.nascimento = '14/07/1996',
  });

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

  void _abrirEdicao() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditarPerfilAlunoScreen(
          nome: widget.nome,
          cpf: widget.cpf,
          email: widget.email,
          nascimento: widget.nascimento,
        ),
      ),
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
        child: Column(
          children: [
            _buildCabecalho(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCampo(valor: widget.email, rotulo: 'E-mail'),
                    const SizedBox(height: 10),
                    _buildCampo(valor: widget.telefone, rotulo: 'Telefone'),
                    const SizedBox(height: 10),
                    _buildCampo(valor: widget.cpf, rotulo: 'CPF'),
                    const SizedBox(height: 10),
                    _buildCampo(valor: widget.nascimento, rotulo: 'Nascimento'),
                    const SizedBox(height: 18),
                    _buildInformacoesSaude(),
                    const SizedBox(height: 20),
                    _buildBotaoEditar(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavInferior(),
    );
  }

  Widget _buildCabecalho() {
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
                  widget.nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aluna desde ${widget.desde}',
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

  Widget _buildInformacoesSaude() {
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
              ? const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Restrições médicas e observações de saúde informadas pelo aluno no primeiro acesso aparecem aqui.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: kHint,
                      height: 1.4,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildBotaoEditar() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _abrirEdicao,
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