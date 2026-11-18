import 'package:flutter/material.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/botao_primario.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/design_system/components/texto_apoio.dart';
import '../data/aula_avulsa_admin_data.dart';

enum EstadoProfessoresAulaAvulsa { carregando, vazio, erro, semConexao, dados }

/// Formulário Admin para criar uma aula sem cronograma (D13).
/// Dados e ações são recebidos por construtor, sem chamada de rede.
class AulaAvulsaAdminScreen extends StatefulWidget {
  const AulaAvulsaAdminScreen({
    super.key,
    this.professores = const [],
    this.estadoProfessores = EstadoProfessoresAulaAvulsa.vazio,
    this.onTentarNovamente,
    this.onSalvar,
  });

  final List<ProfessorAulaAvulsaOpcao> professores;
  final EstadoProfessoresAulaAvulsa estadoProfessores;
  final VoidCallback? onTentarNovamente;
  final ValueChanged<NovaAulaAvulsaAdmin>? onSalvar;

  @override
  State<AulaAvulsaAdminScreen> createState() => _AulaAvulsaAdminScreenState();
}

class _AulaAvulsaAdminScreenState extends State<AulaAvulsaAdminScreen> {
  static const _verde = Color(0xFF005B50);
  static const _laranja = Color(0xFFE97542);
  static const _cinza = Color(0xFF78827F);

  final _formKey = GlobalKey<FormState>();
  DateTime? _data;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFim;
  int? _professorId;
  TipoAulaAvulsaAdmin? _tipo;
  int _vagas = 0;
  String? _erroData;
  String? _erroHorario;
  String? _erroVagas;

  @override
  Widget build(BuildContext context) {
    return FundoTela(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBarInterna(context, 'Nova aula avulsa'),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const TextoApoio(
                  'Aula avulsa é o único caminho para o tipo personal (D13).',
                ),
                const SizedBox(height: 20),
                _campoData(),
                const SizedBox(height: 20),
                _campoHorario(),
                const SizedBox(height: 20),
                _campoProfessor(),
                const SizedBox(height: 20),
                _campoTipo(),
                const SizedBox(height: 20),
                _campoVagas(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BarraAcaoInferior(
          texto: 'Criar aula',
          onPressed: _salvar,
        ),
      ),
    );
  }

  Widget _campoData() {
    final texto = _data == null
        ? 'Selecionar data'
        : '${_data!.day.toString().padLeft(2, '0')}/'
              '${_data!.month.toString().padLeft(2, '0')}/'
              '${_data!.year}';
    return _CampoSelecao(
      titulo: 'Data',
      valor: texto,
      erro: _erroData,
      onTap: _selecionarData,
    );
  }

  Widget _campoHorario() {
    final inicio = _horaInicio?.format(context);
    final fim = _horaFim?.format(context);
    final texto = inicio == null || fim == null
        ? 'Selecionar horário'
        : '$inicio – $fim';
    return _CampoSelecao(
      titulo: 'Horário',
      valor: texto,
      helper: 'Fim depois do início',
      erro: _erroHorario,
      onTap: _selecionarHorario,
    );
  }

  Widget _campoProfessor() {
    final habilitado =
        widget.estadoProfessores == EstadoProfessoresAulaAvulsa.dados &&
        widget.professores.isNotEmpty;
    final textoEstado = switch (widget.estadoProfessores) {
      EstadoProfessoresAulaAvulsa.carregando => 'Carregando professores',
      EstadoProfessoresAulaAvulsa.vazio => 'Aguardando lista de professores',
      EstadoProfessoresAulaAvulsa.erro =>
        'Não foi possível carregar professores',
      EstadoProfessoresAulaAvulsa.semConexao => 'Sem conexão',
      EstadoProfessoresAulaAvulsa.dados => 'Selecionar professor',
    };
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
          hint: Text(textoEstado),
          items: [
            for (final professor in widget.professores)
              DropdownMenuItem(
                value: professor.id,
                child: Text(professor.nome),
              ),
          ],
          onChanged: habilitado
              ? (valor) => setState(() => _professorId = valor)
              : null,
          validator: (valor) => valor == null ? 'Selecione o professor' : null,
        ),
        if (widget.estadoProfessores == EstadoProfessoresAulaAvulsa.erro ||
            widget.estadoProfessores ==
                EstadoProfessoresAulaAvulsa.semConexao) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: widget.onTentarNovamente,
            child: const Text('Tentar novamente'),
          ),
        ],
      ],
    );
  }

  Widget _campoTipo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo', style: TextStyle(color: _cinza, fontSize: 14)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final tipo in TipoAulaAvulsaAdmin.values)
              _OpcaoTipo(
                rotulo: tipo.rotulo,
                selecionada: _tipo == tipo,
                onTap: () => setState(() {
                  _tipo = tipo;
                  if (tipo == TipoAulaAvulsaAdmin.personal && _vagas > 3) {
                    _vagas = 3;
                  }
                  _erroVagas = null;
                }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _campoVagas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vagas', style: TextStyle(color: _cinza, fontSize: 14)),
        const SizedBox(height: 12),
        Row(
          children: [
            _BotaoContador(
              simbolo: '−',
              onPressed: _vagas > 0 ? () => _alterarVagas(-1) : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '$_vagas',
                style: const TextStyle(
                  color: _laranja,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _BotaoContador(simbolo: '+', onPressed: () => _alterarVagas(1)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _tipo == TipoAulaAvulsaAdmin.personal
              ? 'Personal comporta até 3 alunos'
              : 'Informe o total de vagas',
          style: const TextStyle(fontSize: 12, color: _cinza),
        ),
        if (_erroVagas != null) ...[
          const SizedBox(height: 6),
          Text(
            _erroVagas!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _data ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (data == null || !mounted) return;
    setState(() {
      _data = data;
      _erroData = null;
    });
  }

  Future<void> _selecionarHorario() async {
    final inicio = await showTimePicker(
      context: context,
      initialTime: _horaInicio ?? TimeOfDay.now(),
      helpText: 'Horário de início',
    );
    if (inicio == null || !mounted) return;
    final fim = await showTimePicker(
      context: context,
      initialTime: _horaFim ?? TimeOfDay.now(),
      helpText: 'Horário de fim',
    );
    if (fim == null || !mounted) return;
    setState(() {
      _horaInicio = inicio;
      _horaFim = fim;
      _erroHorario = null;
    });
  }

  void _alterarVagas(int incremento) {
    setState(() {
      final novoTotal = _vagas + incremento;
      _vagas = _tipo == TipoAulaAvulsaAdmin.personal && novoTotal > 3
          ? 3
          : novoTotal;
      _erroVagas = null;
    });
  }

  void _salvar() {
    final valido = _formKey.currentState?.validate() ?? false;
    setState(() {
      _erroData = _data == null ? 'Selecione a data' : null;
      _erroHorario = _horaInicio == null || _horaFim == null
          ? 'Selecione o horário de início e fim'
          : null;
      _erroVagas = _vagas < 1 ? 'Informe ao menos uma vaga' : null;
    });
    if (!valido ||
        _data == null ||
        _horaInicio == null ||
        _horaFim == null ||
        _tipo == null ||
        _professorId == null ||
        _vagas < 1) {
      return;
    }

    final callback = widget.onSalvar;
    if (callback == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formulário pronto para integração.')),
      );
      return;
    }

    callback(
      NovaAulaAvulsaAdmin(
        data: _data!,
        horaInicio: _formatarHora(_horaInicio!),
        horaFim: _formatarHora(_horaFim!),
        professorId: _professorId!,
        tipo: _tipo!,
        vagasMaxima: _vagas,
      ),
    );
  }

  String _formatarHora(TimeOfDay hora) =>
      '${hora.hour.toString().padLeft(2, '0')}:'
      '${hora.minute.toString().padLeft(2, '0')}';
}

class _CampoSelecao extends StatelessWidget {
  const _CampoSelecao({
    required this.titulo,
    required this.valor,
    required this.onTap,
    this.helper,
    this.erro,
  });

  final String titulo;
  final String valor;
  final VoidCallback onTap;
  final String? helper;
  final String? erro;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onTap,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFBECBC8)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(valor, style: const TextStyle(fontSize: 15)),
            ),
          ),
        ),
        if (helper != null || erro != null) ...[
          const SizedBox(height: 6),
          Text(
            erro ?? helper!,
            style: TextStyle(
              color: erro == null
                  ? const Color(0xFF78827F)
                  : Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _OpcaoTipo extends StatelessWidget {
  const _OpcaoTipo({
    required this.rotulo,
    required this.selecionada,
    required this.onTap,
  });

  final String rotulo;
  final bool selecionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionada ? const Color(0xFF005B50) : const Color(0xFFEFF3F2),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Text(
            rotulo,
            style: TextStyle(
              color: selecionada ? Colors.white : const Color(0xFF33413F),
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _BotaoContador extends StatelessWidget {
  const _BotaoContador({required this.simbolo, required this.onPressed});

  final String simbolo;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF33413F),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFBECBC8)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        child: Text(simbolo, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
