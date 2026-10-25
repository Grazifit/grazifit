import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/material.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/botao_primario.dart';
import '../../../core/design_system/components/campo_texto.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/utils/formatadores.dart';
import '../../../core/utils/validadores.dart';
import '../widgets/endereco_opcional.dart';

@immutable
class DadosCadastroProfessor {
  const DadosCadastroProfessor({
    this.id,
    required this.nome,
    required this.cpf,
    required this.email,
    required this.telefone,
  });

  final String? id;
  final String nome;
  final String cpf;
  final String email;
  final String telefone;
}

typedef SalvarCadastroProfessor =
    Future<void> Function(DadosCadastroProfessor dados);

class CadastroProfessorScreen extends StatefulWidget {
  const CadastroProfessorScreen({
    super.key,
    this.dadosIniciais,
    this.modoEdicao = false,
    this.onSalvar,
  });

  final DadosCadastroProfessor? dadosIniciais;
  final bool modoEdicao;
  final SalvarCadastroProfessor? onSalvar;

  @override
  State<CadastroProfessorScreen> createState() =>
      _CadastroProfessorScreenState();
}

class _CadastroProfessorScreenState extends State<CadastroProfessorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _cpfController;
  late final TextEditingController _emailController;
  late final TextEditingController _telefoneController;

  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final dados = widget.dadosIniciais;
    _nomeController =
        TextEditingController(text: dados?.nome ?? 'Marina Alves');
    _cpfController =
        TextEditingController(text: dados?.cpf ?? '000.000.000-01');
    _emailController = TextEditingController(
      text: dados?.email ?? 'marina.alves@exemplo.com',
    );
    _telefoneController = TextEditingController(
      text: dados?.telefone ?? '(45) 90000-0001',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FundoTela(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBarInterna(
          context,
          widget.modoEdicao ? 'Editar professor' : 'Cadastro de professor',
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                CampoTexto(
                  label: 'Nome completo',
                  controller: _nomeController,
                  helper: 'Como os alunos verão',
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
                  label: 'Telefone',
                  controller: _telefoneController,
                  helper: 'Obrigatório',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [TelefoneInputFormatter()],
                  validator: Validadores.telefone,
                ),
                const SizedBox(height: 28),
                const EnderecoOpcional(),
                const SizedBox(height: 20),
                const Text(
                  "Sem campos profissionais: 'professor' não tem CREF nem "
                  'especialidade (D17).',
                  style: TextStyle(
                    color: Color(0xFF78827F),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
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

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final onSalvar = widget.onSalvar;
    if (onSalvar == null) {
      _mostrarAviso('Cadastro preenchido localmente.');
      return;
    }

    setState(() => _salvando = true);
    try {
      await onSalvar(
        DadosCadastroProfessor(
          id: widget.dadosIniciais?.id,
          nome: _nomeController.text.trim(),
          cpf: _cpfController.text.trim(),
          email: _emailController.text.trim(),
          telefone: _telefoneController.text.trim(),
        ),
      );
      if (mounted) _mostrarAviso('Cadastro salvo.');
    } catch (_) {
      if (mounted) _mostrarAviso('Não foi possível salvar o cadastro.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _mostrarAviso(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }
}
