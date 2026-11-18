import 'package:flutter/material.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/botao_primario.dart';
import '../../../core/design_system/components/campo_texto.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/design_system/tokens/cores_provisorias.dart';
import '../state/novo_exercicio_admin_form_state.dart';

/// Formulário de cadastro de exercício da área Admin.
/// O salvamento é fornecido por callback e não é conectado à API nesta etapa.
class NovoExercicioAdminScreen extends StatefulWidget {
  const NovoExercicioAdminScreen({
    super.key,
    this.dificuldadeInicial = 'intermediario',
    this.salvando = false,
    this.onSalvar,
  });

  final String dificuldadeInicial;
  final bool salvando;
  final ValueChanged<NovoExercicioAdminInput>? onSalvar;

  @override
  State<NovoExercicioAdminScreen> createState() =>
      _NovoExercicioAdminScreenState();
}

class _NovoExercicioAdminScreenState extends State<NovoExercicioAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _instrucoesController = TextEditingController();
  final _descricaoController = TextEditingController();

  late String _dificuldade = widget.dificuldadeInicial;

  static const _dificuldades = [
    ('iniciante', 'Iniciante'),
    ('intermediario', 'Intermediário'),
    ('avancado', 'Avançado'),
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _instrucoesController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final callback = widget.onSalvar;
    if (callback == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('O cadastro aguarda a integração dos dados.'),
          ),
        );
      return;
    }

    callback(
      NovoExercicioAdminInput(
        nome: _nomeController.text.trim(),
        instrucoes: _instrucoesController.text.trim(),
        descricao: _descricaoController.text.trim().isEmpty
            ? null
            : _descricaoController.text.trim(),
        dificuldade: _dificuldade,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FundoTela(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: appBarInterna(context, 'Novo exercício'),
            body: SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    CampoTexto(
                      label: 'Nome',
                      controller: _nomeController,
                      helper: 'Único no sistema',
                      textCapitalization: TextCapitalization.sentences,
                      validator: _validarObrigatorio,
                    ),
                    const SizedBox(height: 20),
                    CampoTexto(
                      label: 'Instruções',
                      controller: _instrucoesController,
                      helper: 'Obrigatório — nenhum exercício existe sem instruções',
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      minLines: 1,
                      validator: _validarObrigatorio,
                    ),
                    const SizedBox(height: 20),
                    CampoTexto(
                      label: 'Descrição',
                      controller: _descricaoController,
                      helper: 'Opcional',
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      minLines: 1,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Dificuldade',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64706D),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final dificuldade in _dificuldades)
                          _OpcaoDificuldade(
                            rotulo: dificuldade.$2,
                            selecionada: _dificuldade == dificuldade.$1,
                            onSelecionar: () => setState(
                              () => _dificuldade = dificuldade.$1,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: BarraAcaoInferior(
              texto: 'Salvar exercício',
              onPressed: widget.salvando ? null : _salvar,
            ),
          ),
        ),
      ),
    );
  }

  String? _validarObrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }
}

class _OpcaoDificuldade extends StatelessWidget {
  const _OpcaoDificuldade({
    required this.rotulo,
    required this.selecionada,
    required this.onSelecionar,
  });

  final String rotulo;
  final bool selecionada;
  final VoidCallback onSelecionar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selecionada,
      label: rotulo,
      child: Material(
        color: selecionada ? corInstitucional : corSuperficieSuave,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          onTap: onSelecionar,
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Text(
              rotulo,
              style: TextStyle(
                color: selecionada ? Colors.white : const Color(0xFF33413F),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
