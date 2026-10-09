// app/lib/features/pessoas/screens/cadastro_professor_screen.dart
//
// PROTÓTIPO VISUAL — sem integração com backend.
// Construído fora da ordem de fases do projeto (DTO → Repository → Service →
// Controller → data/ → state/ → screens/), a pedido explícito do usuário,
// só para visualizar a tela fiel ao mockup antes da Sprint 2.
//
// Decisões aplicadas (confirmadas pelo usuário nesta sessão):
// - Sem campos profissionais (CREF/especialidade) — nota do mockup (D17)
//   prevalece sobre o texto de RF-05, que ficou desatualizado.
// - Endereço é sub-form opcional de professor, não feature própria (D18).
//
// O que NÃO foi inventado, de propósito:
// - Os campos internos do sub-form de Endereço: a tabela `endereco` do
//   schema não veio neste export de specs, então o formulário expandido
//   não é preenchido aqui — ver TODO em _EnderecoOpcional.
// - Tokens exatos de cor/tipografia: `core/design_system/tokens` (48
//   variáveis, 8 estilos de texto) não vieram neste export. A cor do botão
//   usa o verde institucional da paleta de marca (manual-marca), mas o hex
//   exato deve ser substituído pelo token real assim que existir.
// - Mensagens de erro de CPF/e-mail duplicado: isso é contrato de backend
//   (CPF_EM_USO, EMAIL_EM_USO, CPF_INVALIDO, EMAIL_INVALIDO — arquitetura
//   §7). Aqui há só checagem de formato para UX, nunca de regra de negócio.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/components/fundo_tela.dart';

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

  // TODO(specs): usar o token real de cor institucional quando
  // core/design_system/tokens existir. Valor abaixo é aproximado, lido da
  // paleta em manual-marca/logos/palheta de cores.png ("cor institucional").
  static const _corInstitucional = Color(0xFF0F4C3A);

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FundoTela(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        titleSpacing: 12,
        leadingWidth: 48,
        leading: Padding(
          padding: const EdgeInsets.only(left: 28),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Text(
              '<',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: _corInstitucional,
                height: 1,
              ),
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: const Text(
          'Cadastro de professor',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 8, 24, 24),
            children: [
              _CampoTexto(
                label: 'Nome completo',
                controller: _nomeController,
                hint: 'Marina Alves',
                helper: 'Como os alunos verão',
                corFoco: _corInstitucional,
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe o nome completo'
                    : null,
              ),
              const SizedBox(height: 20),
              _CampoTexto(
                label: 'CPF',
                controller: _cpfController,
                hint: '000.000.000-01',
                helper: '11 dígitos',
                corFoco: _corInstitucional,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                  _CpfInputFormatter(),
                ],
                validator: (v) {
                  final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digits.length != 11) return 'CPF deve ter 11 dígitos';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _CampoTexto(
                label: 'E-mail',
                controller: _emailController,
                hint: 'marina.alves@exemplo.com',
                helper: 'Será a credencial de acesso',
                corFoco: _corInstitucional,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final value = (v ?? '').trim();
                  final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!regex.hasMatch(value)) return 'E-mail inválido';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _CampoSenha(
                controller: _senhaController,
                corFoco: _corInstitucional,
                validator: (v) {
                  final value = v ?? '';
                  if (value.length < 8) return 'Mínimo de 8 caracteres';
                  if (!RegExp(r'[A-Z]').hasMatch(value)) {
                    return 'Inclua ao menos 1 letra maiúscula';
                  }
                  if (!RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=/\\\[\];~`]''')
                      .hasMatch(value)) {
                    return 'Inclua ao menos 1 caractere especial';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _CampoTexto(
                label: 'Telefone',
                controller: _telefoneController,
                hint: '(45) 90000-0001',
                helper: 'Obrigatório',
                corFoco: _corInstitucional,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                  _TelefoneInputFormatter(),
                ],
                validator: (v) {
                  final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 10) return 'Telefone obrigatório';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const _EnderecoOpcional(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(28, 0, 24, 16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _corInstitucional,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            // Protótipo visual: só valida formato local, não salva nada.
            // Persistência real nasce em data/ + state/ na fatia vertical
            // de `pessoas`, depois de `auth` (F-01), conforme o guia de
            // desenvolvimento.
            onPressed: () => _formKey.currentState?.validate(),
            child: const Text(
              'Salvar cadastro',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _CampoTexto extends StatelessWidget {
  const _CampoTexto({
    required this.label,
    required this.controller,
    required this.hint,
    required this.corFoco,
    this.helper,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final Color corFoco;
  final String? helper;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          validator: validator,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: corFoco, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper!,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }
}

/// Campo de senha com toggle de mostrar/ocultar e a regra de complexidade
/// pedida: mínimo 8 caracteres, 1 maiúscula, 1 caractere especial.
///
/// NOTA: este campo não aparecia nos prints do mockup vistos até aqui —
/// entrou por instrução explícita do usuário. A regra de complexidade em si
/// não está em nenhum RF/RNF ou em D59 (que só fixa Argon2id + pepper no
/// hash, não a política de senha em texto). Se o Figma real tiver um texto
/// de ajuda diferente do usado abaixo, ajustar para bater exatamente.
class _CampoSenha extends StatefulWidget {
  const _CampoSenha({
    required this.controller,
    required this.corFoco,
    this.validator,
  });

  final TextEditingController controller;
  final Color corFoco;
  final String? Function(String?)? validator;

  @override
  State<_CampoSenha> createState() => _CampoSenhaState();
}

class _CampoSenhaState extends State<_CampoSenha> {
  bool _visivel = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Senha',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: !_visivel,
          validator: widget.validator,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: IconButton(
              icon: Icon(
                _visivel ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade500,
                size: 20,
              ),
              onPressed: () => setState(() => _visivel = !_visivel),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: widget.corFoco, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Mínimo 8 caracteres, 1 maiúscula e 1 caractere especial',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _EnderecoOpcional extends StatefulWidget {
  const _EnderecoOpcional();

  @override
  State<_EnderecoOpcional> createState() => _EnderecoOpcionalState();
}

class _EnderecoOpcionalState extends State<_EnderecoOpcional> {
  bool _aberto = false;

  static const _corInstitucional = Color(0xFF0F4C3A);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _aberto = !_aberto),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Endereço (opcional)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              AnimatedRotation(
                turns: _aberto ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: _corInstitucional,
                ),
              ),
            ],
          ),
        ),
        // Nota de escopo do próprio protótipo (D17) — texto real da tela,
        // não comentário de dev. Confirmado pelo usuário: professor não
        // tem campos profissionais (CREF/especialidade).
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            "Sem campos profissionais: 'professor' não tem CREF nem "
            'especialidade (D17).',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        // TODO(specs): os campos deste sub-form dependem das colunas reais
        // da tabela `endereco` em database/schema/grazi_db_init_schema.sql,
        // que não veio neste export. Não inventar campos (rua, número, CEP
        // etc.) até essa fonte de verdade estar disponível — ver R4 em
        // docs/05-prompts-ia/prompt-fase-1-estrutura.md.
        if (_aberto)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Campos de endereço pendentes: schema real da tabela '
              '"endereco" ainda não disponível nas specs.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
      ],
    );
  }
}

/// Formata dígitos como CPF: 000.000.000-00 (formatação de exibição apenas;
/// a validação de domínio real — dom_cpf — vive no banco, §7 da arquitetura).
class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('-');
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

/// Formata dígitos como telefone: (00) 00000-0000
class _TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 0) buffer.write('(');
      buffer.write(digits[i]);
      if (i == 1) buffer.write(') ');
      if (i == 6 && digits.length > 10) buffer.write('-');
      if (i == 5 && digits.length <= 10) buffer.write('-');
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}