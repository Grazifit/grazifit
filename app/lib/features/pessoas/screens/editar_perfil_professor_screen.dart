// app/lib/features/pessoas/screens/editar_perfil_professor_screen.dart
//
// PROTÓTIPO VISUAL — sem integração com backend.
// Integração com o backend: ver docs/handoff-front-professor.md
//
// Editar perfil do professor. Conforme o mockup:
// - Nome e telefone são editáveis.
// - E-mail e CPF aparecem preenchidos, mas só a academia altera
//   ("Alteração pela academia"), então ficam bloqueados.
// - Endereço é o sub-form opcional compartilhado (EnderecoOpcional, D18).
//
// Sem campo de senha: o mockup desta tela não tem.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/botao_primario.dart';
import '../../../core/design_system/components/campo_texto.dart';
import '../../../core/utils/formatadores.dart';
import '../../../core/utils/validadores.dart';
import '../widgets/endereco_opcional.dart';
import '../../../core/network/api_exception.dart';
import '../data/professor_repository.dart';
import '../state/perfil_professor_providers.dart';
import '../../../core/data/repositorios.dart';

class EditarPerfilProfessorScreen extends ConsumerStatefulWidget {
  const EditarPerfilProfessorScreen({super.key, required this.professor});

  /// Dados atuais (a rota recebe por `extra`).
  final Professor professor;

  @override
  ConsumerState<EditarPerfilProfessorScreen> createState() =>
      _EditarPerfilProfessorScreenState();
}

class _EditarPerfilProfessorScreenState
    extends ConsumerState<EditarPerfilProfessorScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _salvando = false;

  late final _nomeController =
      TextEditingController(text: widget.professor.nome);
  late final _telefoneController =
      TextEditingController(text: widget.professor.telefone);
  late final _emailController =
      TextEditingController(text: widget.professor.email);
  late final _cpfController =
      TextEditingController(text: widget.professor.cpf ?? '');

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  // PATCH /professor/<id> aceita nome, email, telefone, senha e status, mas
  // hoje só admin (L1). Aqui só nome e telefone são enviados. Limites do
  // contrato: nome até 150, telefone até 20. Decidir se o telefone vai com
  // máscara ou só dígitos (L5). Erros: escolher o texto pelo "codigo" do
  // envelope, nunca pela mensagem.
  Future<void> _salvar() async {
    if (_salvando || !(_formKey.currentState?.validate() ?? false)) return;
    final mensagem = ScaffoldMessenger.of(context);
    setState(() => _salvando = true);
    try {
      await Repositorios.professores.atualizar(
            widget.professor.idProfessor,
            nome: _nomeController.text,
            telefone: _telefoneController.text,
          );
      ref.invalidate(perfilProfessorProvider);
      if (mounted) Navigator.of(context).pop();
    } on ApiException {
      if (!mounted) return;
      setState(() => _salvando = false);
      // TODO(design): texto por código de erro; o mockup não define.
      mensagem.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar. Tente novamente.'),
        ),
      );
    }
  }

  // TODO(specs): CampoTexto ainda não tem modo somente leitura. Enquanto isso,
  // o campo é desativado por fora. Ideal: variante "bloqueado" no componente
  // (alteração de design system: pede aprovação do time).
  Widget _bloqueado(Widget campo) => Opacity(
        opacity: 0.6,
        child: IgnorePointer(child: ExcludeFocus(child: campo)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: appBarInterna(context, 'Editar perfil'),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                CampoTexto(
                  label: 'Nome',
                  controller: _nomeController,
                  helper: 'Como aparece para os alunos',
                  textCapitalization: TextCapitalization.words,
                  validator: Validadores.nome,
                ),
                const SizedBox(height: 20),
                CampoTexto(
                  label: 'Telefone',
                  controller: _telefoneController,
                  helper: 'Somente números',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [TelefoneInputFormatter()],
                  validator: Validadores.telefone,
                ),
                const SizedBox(height: 20),
                _bloqueado(
                  CampoTexto(
                    label: 'E-mail',
                    controller: _emailController,
                    helper:
                        'É sua credencial de acesso. Alteração pela academia',
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(height: 20),
                _bloqueado(
                  CampoTexto(
                    label: 'CPF',
                    controller: _cpfController,
                    helper: 'Alteração pela academia',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(height: 20),
                const EnderecoOpcional(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BarraAcaoInferior(
          texto: 'Salvar alterações',
          onPressed: _salvando ? null : _salvar,
        ),
      );
  }
}