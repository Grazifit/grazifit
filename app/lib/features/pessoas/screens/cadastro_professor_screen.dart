// app/lib/features/pessoas/screens/cadastro_professor_screen.dart
//
// Integrada ao backend: POST /professor (data/professor_repository.dart,
// state/cadastro_professor_notifier.dart). Só valida a forma; regra de
// negócio e unicidade são do backend, e o texto do erro vem do código (D64).
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/erros/codigo_erro.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/botao_primario.dart';
import '../../../core/design_system/components/campo_texto.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatadores.dart';
import '../../../core/utils/validadores.dart';
import '../data/professor_repository.dart';
import '../state/cadastro_professor_notifier.dart';
import '../widgets/endereco_opcional.dart';

class CadastroProfessorScreen extends ConsumerStatefulWidget {
  const CadastroProfessorScreen({super.key});

  @override
  ConsumerState<CadastroProfessorScreen> createState() =>
      _CadastroProfessorScreenState();
}

class _CadastroProfessorScreenState
    extends ConsumerState<CadastroProfessorScreen> {
  // Erros devolvidos pelo backend, exibidos no campo correspondente.
  // O texto vem do código (D64), nunca da mensagem do servidor.
  String? _erroCpf;
  String? _erroEmail;

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

  Future<void> _salvar() async {
    setState(() {
      _erroCpf = null;
      _erroEmail = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref.read(cadastroProfessorProvider.notifier).salvar(
          nome: _nomeController.text,
          cpf: _cpfController.text.replaceAll(RegExp(r'\D'), ''),
          email: _emailController.text,
          senha: _senhaController.text,
          telefone: _telefoneController.text,
        );
  }

  void _aoMudarEstado(
    AsyncValue<Professor?>? anterior,
    AsyncValue<Professor?> atual,
  ) {
    final professor = atual.valueOrNull;
    if (professor != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Professor cadastrado.')),
      );
      Navigator.of(context).maybePop();
      return;
    }

    final erro = atual.error;
    if (erro is! ApiException) return;

    switch (erro.codigoErro) {
      case CodigoErro.cpfEmUso:
        setState(() => _erroCpf = 'CPF já cadastrado');
      case CodigoErro.cpfInvalido:
        setState(() => _erroCpf = 'CPF inválido');
      case CodigoErro.emailEmUso:
        setState(() => _erroEmail = 'E-mail já cadastrado');
      case CodigoErro.emailInvalido:
        setState(() => _erroEmail = 'E-mail inválido');
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_textoDoErro(erro))),
        );
        return;
    }
    _formKey.currentState?.validate();
  }

  String _textoDoErro(ApiException erro) {
    if (erro.semResposta) {
      return 'Sem conexão com o servidor. Tente novamente.';
    }
    return switch (erro.codigoErro) {
      CodigoErro.tokenInvalido => 'Sessão expirada. Entre novamente.',
      CodigoErro.acessoNegado =>
        'Você não tem permissão para cadastrar professores.',
      CodigoErro.campoInvalido ||
      CodigoErro.campoObrigatorio =>
        'Confira os dados informados.',
      _ when erro.status == 400 => 'Confira os dados informados.',
      _ => 'Não foi possível salvar. Tente novamente.',
    };
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cadastroProfessorProvider, _aoMudarEstado);
    final enviando = ref.watch(cadastroProfessorProvider).isLoading;

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
                  validator: (v) => Validadores.cpf(v) ?? _erroCpf,
                ),
                const SizedBox(height: 20),
                CampoTexto(
                  label: 'E-mail',
                  controller: _emailController,
                  hint: 'marina.alves@exemplo.com',
                  helper: 'Será a credencial de acesso',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => Validadores.email(v) ?? _erroEmail,
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
          onPressed: enviando ? null : _salvar,
        ),
      ),
    );
  }
}
