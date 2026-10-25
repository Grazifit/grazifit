// app/lib/features/pessoas/screens/cadastro_professor_screen.dart
//
// PROTÓTIPO VISUAL — sem integração com backend.
// Construído fora da ordem de fases do projeto (DTO → Repository → Service →
// Controller → data/ → state/ → screens/), a pedido explícito do usuário,
// só para visualizar a tela fiel ao mockup antes da Sprint 2.
//
// Decisões aplicadas (confirmadas pelo usuário):
// - Sem campos profissionais (CREF/especialidade) — nota do mockup (D17)
//   prevalece sobre o texto de RF-05, que ficou desatualizado.
// - Endereço é sub-form opcional de professor, não feature própria (D18).
//
// O que NÃO foi inventado, de propósito:
// - Os campos internos do sub-form de Endereço (ver EnderecoOpcional).
// - Tokens exatos de cor/tipografia: usa core/design_system/tokens/
//   cores_provisorias.dart até os tokens reais existirem.
// - Mensagens de erro de CPF/e-mail duplicado: isso é contrato de backend
//   (CPF_EM_USO, EMAIL_EM_USO, CPF_INVALIDO, EMAIL_INVALIDO — arquitetura
//   §7). Aqui há só checagem de formato para UX (core/utils/validadores.dart).

import 'package:flutter/material.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/botao_primario.dart';
import '../../../core/design_system/components/campo_texto.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/utils/formatadores.dart';
import '../../../core/utils/validadores.dart';
import '../widgets/endereco_opcional.dart';

class CadastroProfessorScreen extends StatefulWidget {
  const CadastroProfessorScreen({super.key});

  @override
  State<CadastroProfessorScreen> createState() =>
      _CadastroProfessorScreenState();
}

class _CadastroProfessorScreenState extends State<CadastroProfessorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _telefoneController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  // Protótipo visual: só valida formato local, não salva nada.
  // Persistência real nasce em data/ + state/ na fatia vertical de `pessoas`,
  // depois de `auth` (F-01), conforme o guia de desenvolvimento.
  void _salvar() {
    _formKey.currentState?.validate();
  }

  @override
  Widget build(BuildContext context) {
    return FundoTela(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBarInterna(context, 'Cadastro de professor'),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                CampoTexto(
                  label: 'Nome completo',
                  controller: _nomeController,
                  hint: 'Marina Alves',
                  helper: 'Como os alunos verão',
                  textCapitalization: TextCapitalization.words,
                  validator: Validadores.nome,
                ),
                const SizedBox(height: 20),
                CampoTexto(
                  label: 'CPF',
                  controller: _cpfController,
                  hint: '000.000.000-01',
                  helper: '11 dígitos',
                  keyboardType: TextInputType.number,
                  inputFormatters: [CpfInputFormatter()],
                  validator: Validadores.cpf,
                ),
                const SizedBox(height: 20),
                CampoTexto(
                  label: 'E-mail',
                  controller: _emailController,
                  hint: 'marina.alves@exemplo.com',
                  helper: 'Será a credencial de acesso',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validadores.email,
                ),
                const SizedBox(height: 20),
                CampoSenha(
                  controller: _senhaController,
                  validator: Validadores.senha,
                ),
                const SizedBox(height: 20),
                CampoTexto(
                  label: 'Telefone',
                  controller: _telefoneController,
                  hint: '(45) 90000-0001',
                  helper: 'Obrigatório',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [TelefoneInputFormatter()],
                  validator: Validadores.telefone,
                ),
                const SizedBox(height: 20),
                const EnderecoOpcional(
                  // Nota de escopo do mockup (D17): professor não tem campos
                  // profissionais (CREF/especialidade).
                  nota: "Sem campos profissionais: 'professor' não tem CREF "
                      'nem especialidade (D17).',
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BarraAcaoInferior(
          texto: 'Salvar cadastro',
          onPressed: _salvar,
        ),
      ),
    );
  }
}