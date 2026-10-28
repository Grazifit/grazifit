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

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/botao_primario.dart';
import '../../../core/design_system/components/campo_texto.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/utils/formatadores.dart';
import '../../../core/utils/validadores.dart';
import '../widgets/endereco_opcional.dart';

class EditarPerfilProfessorScreen extends StatefulWidget {
  const EditarPerfilProfessorScreen({
    super.key,
    this.nome = 'Marina Alves',
    this.telefone = '(45) 90000-0001',
    this.email = 'marina.alves@exemplo.com',
    this.cpf = '000.000.000-01',
  });

  // Valores padrão = dados fictícios do mockup.
  final String nome;
  final String telefone;
  final String email;
  final String cpf;

  @override
  State<EditarPerfilProfessorScreen> createState() =>
      _EditarPerfilProfessorScreenState();
}

class _EditarPerfilProfessorScreenState
    extends State<EditarPerfilProfessorScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _nomeController = TextEditingController(text: widget.nome);
  late final _telefoneController =
      TextEditingController(text: widget.telefone);
  late final _emailController = TextEditingController(text: widget.email);
  late final _cpfController = TextEditingController(text: widget.cpf);

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  // TODO(backend): PATCH /professor/<id> aceita nome, email, telefone,
  // senha e status, mas hoje só admin (L1). Aqui só nome e telefone são
  // enviados. Limites do contrato: nome até 150, telefone até 20.
  // Decidir se o telefone vai com máscara ou só dígitos (L5).
  // Erros: tela escolhe o texto pelo "codigo" do envelope, nunca pela
  // mensagem. Após salvar, o Perfil precisa refletir os dados novos.
  // Protótipo visual: só valida formato local, não salva nada.
  void _salvar() {
    _formKey.currentState?.validate();
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
    return FundoTela(
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
          onPressed: _salvar,
        ),
      ),
    );
  }
}