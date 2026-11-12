import 'package:flutter/material.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/botao_primario.dart';
import '../../../core/design_system/components/campo_texto.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../data/cronogramas_admin_data.dart';

/// Formulário de cronograma do Admin, sem persistência ou chamada de serviço.
class FormCronogramaAdminScreen extends StatefulWidget {
  const FormCronogramaAdminScreen({
    super.key,
    this.professores = const [],
    this.onSalvar,
  });

  final List<ProfessorCronogramaOpcao> professores;
  final ValueChanged<NovoCronogramaAdmin>? onSalvar;

  @override
  State<FormCronogramaAdminScreen> createState() =>
      _FormCronogramaAdminScreenState();
}

class _FormCronogramaAdminScreenState extends State<FormCronogramaAdminScreen> {
  static const _verde = Color(0xFF005B50);
  static const _texto = Color(0xFF33413F);
  static const _dias = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
  static const _nomesDias = [
    'Domingo',
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
  ];

  final _formKey = GlobalKey<FormState>();
  final _vagasController = TextEditingController();
  final Set<int> _diasSelecionados = {};
  CategoriaCronogramaAdmin? _categoria;
  int? _professorId;
  DateTime? _dataInicio;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFim;
  String? _erroData;
  String? _erroHorario;

  @override
  void dispose() {
    _vagasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FundoTela(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBarInterna(context, 'Novo cronograma'),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _dropdownCategoria(),
                const SizedBox(height: 20),
                _dropdownProfessor(),
                const SizedBox(height: 20),
                _campoDataInicio(),
                const SizedBox(height: 20),
                _campoHorario(),
                const SizedBox(height: 20),
                CampoTexto(
                  label: 'Vagas por aula',
                  controller: _vagasController,
                  keyboardType: TextInputType.number,
                  validator: (valor) => valor == null || valor.trim().isEmpty
                      ? 'Informe as vagas por aula'
                      : int.tryParse(valor.trim()) == null
                      ? 'Informe um número inteiro'
                      : null,
                ),
                const SizedBox(height: 20),
                _seletorDias(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BarraAcaoInferior(
          texto: 'Salvar cronograma',
          onPressed: _salvar,
        ),
      ),
    );
  }

  Widget _dropdownCategoria() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<CategoriaCronogramaAdmin>(
          value: _categoria,
          decoration: const InputDecoration(
            labelText: 'Categoria',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
          ),
          items: [
            for (final categoria in CategoriaCronogramaAdmin.values)
              DropdownMenuItem(value: categoria, child: Text(categoria.rotulo)),
          ],
          onChanged: (valor) => setState(() => _categoria = valor),
          validator: (valor) => valor == null ? 'Selecione a categoria' : null,
        ),
        const SizedBox(height: 6),
        const Text(
          'Uma das seis categorias',
          style: TextStyle(fontSize: 12, color: Color(0xFF78827F)),
        ),
      ],
    );
  }

  Widget _dropdownProfessor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          value: _professorId,
          decoration: const InputDecoration(
            labelText: 'Professor',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
          ),
          hint: Text(
            widget.professores.isEmpty
                ? 'Aguardando lista de professores'
                : 'Selecionar professor',
          ),
          items: [
            for (final professor in widget.professores)
              DropdownMenuItem(
                value: professor.id,
                child: Text(professor.nome),
              ),
          ],
          onChanged: widget.professores.isEmpty
              ? null
              : (valor) => setState(() => _professorId = valor),
          validator: (valor) => valor == null ? 'Selecione o professor' : null,
        ),
      ],
    );
  }

  Widget _campoDataInicio() {
    final dataFormatada = _dataInicio == null
        ? null
        : '${_dataInicio!.day.toString().padLeft(2, '0')}/'
              '${_dataInicio!.month.toString().padLeft(2, '0')}/'
              '${_dataInicio!.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data de início',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _CampoSelecionavel(
          texto: dataFormatada ?? 'Selecionar data',
          selecionado: dataFormatada != null,
          icone: Icons.calendar_today_outlined,
          erro: _erroData,
          onTap: _selecionarData,
        ),
      ],
    );
  }

  Widget _campoHorario() {
    final inicio = _horaInicio?.format(context);
    final fim = _horaFim?.format(context);
    final intervalo = inicio == null || fim == null ? null : '$inicio – $fim';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Horário',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _CampoSelecionavel(
          texto: intervalo ?? 'Selecionar início e fim',
          selecionado: intervalo != null,
          icone: Icons.access_time,
          erro: _erroHorario,
          onTap: _selecionarHorario,
        ),
      ],
    );
  }

  Widget _seletorDias() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dias da semana',
          style: TextStyle(fontSize: 14, color: Color(0xFF78827F)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (var dia = 0; dia < _dias.length; dia++) ...[
              Expanded(
                child: Semantics(
                  label: _nomesDias[dia],
                  button: true,
                  selected: _diasSelecionados.contains(dia),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() {
                      if (!_diasSelecionados.add(dia)) {
                        _diasSelecionados.remove(dia);
                      }
                    }),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _diasSelecionados.contains(dia)
                              ? _verde
                              : Colors.white,
                          border: Border.all(color: const Color(0xFFBECBC8)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _dias[dia],
                          style: TextStyle(
                            color: _diasSelecionados.contains(dia)
                                ? Colors.white
                                : _texto,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _selecionarData() async {
    final hoje = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _dataInicio ?? hoje,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (escolhida == null || !mounted) return;
    setState(() {
      _dataInicio = escolhida;
      _erroData = null;
    });
  }

  Future<void> _selecionarHorario() async {
    final inicio = await showTimePicker(
      context: context,
      initialTime: _horaInicio ?? const TimeOfDay(hour: 7, minute: 0),
      helpText: 'Horário de início',
    );
    if (inicio == null || !mounted) return;
    final fim = await showTimePicker(
      context: context,
      initialTime: _horaFim ?? const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Horário de fim',
    );
    if (fim == null || !mounted) return;
    setState(() {
      _horaInicio = inicio;
      _horaFim = fim;
      _erroHorario = null;
    });
  }

  void _salvar() {
    final formularioValido = _formKey.currentState?.validate() ?? false;
    setState(() {
      _erroData = _dataInicio == null ? 'Selecione a data de início' : null;
      _erroHorario = _horaInicio == null || _horaFim == null
          ? 'Selecione o horário de início e fim'
          : null;
    });
    if (!formularioValido ||
        _dataInicio == null ||
        _horaInicio == null ||
        _horaFim == null ||
        _categoria == null ||
        _professorId == null) {
      return;
    }

    final callback = widget.onSalvar;
    if (callback == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formulário pronto para receber a integração.'),
        ),
      );
      return;
    }

    callback(
      NovoCronogramaAdmin(
        professorId: _professorId!,
        categoria: _categoria!,
        dataInicio: _dataInicio!,
        horaInicio: _formatarHora(_horaInicio!),
        horaFim: _formatarHora(_horaFim!),
        vagasMaxima: int.parse(_vagasController.text.trim()),
        diasSemana: (_diasSelecionados.toList()..sort()),
      ),
    );
  }

  String _formatarHora(TimeOfDay hora) =>
      '${hora.hour.toString().padLeft(2, '0')}:'
      '${hora.minute.toString().padLeft(2, '0')}';
}

class _CampoSelecionavel extends StatelessWidget {
  const _CampoSelecionavel({
    required this.texto,
    required this.selecionado,
    required this.icone,
    required this.onTap,
    this.erro,
  });

  final String texto;
  final bool selecionado;
  final IconData icone;
  final VoidCallback onTap;
  final String? erro;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onTap,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFBECBC8)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      texto,
                      style: TextStyle(
                        color: selecionado
                            ? const Color(0xFF33413F)
                            : const Color(0xFF78827F),
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(icone, size: 18, color: const Color(0xFF005B50)),
                ],
              ),
            ),
          ),
        ),
        if (erro != null) ...[
          const SizedBox(height: 6),
          Text(
            erro!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
