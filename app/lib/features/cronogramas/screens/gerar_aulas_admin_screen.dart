import 'package:flutter/material.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/design_system/components/texto_apoio.dart';
import '../../../core/design_system/tokens/cores_provisorias.dart';
import '../state/geracao_aulas_admin_estado.dart';

/// Prévia e resultado de F-19. Esta tela não calcula ocorrências nem cria aulas.
class GerarAulasAdminScreen extends StatefulWidget {
  const GerarAulasAdminScreen({
    super.key,
    this.cronogramaId,
    this.nomeCronograma,
    this.estado = EstadoGeracaoAulasAdmin.periodo,
    this.previa,
    this.resultado,
    this.onSolicitarPrevia,
    this.onCriarAulas,
    this.onVerAulasCriadas,
    this.onTentarNovamente,
  });

  final int? cronogramaId;
  final String? nomeCronograma;
  final EstadoGeracaoAulasAdmin estado;
  final PreviaGeracaoAulasAdmin? previa;
  final ResultadoGeracaoAulasAdmin? resultado;
  final ValueChanged<PeriodoGeracaoAulasAdmin>? onSolicitarPrevia;
  final ValueChanged<ConfirmacaoGeracaoAulasAdmin>? onCriarAulas;
  final VoidCallback? onVerAulasCriadas;
  final VoidCallback? onTentarNovamente;

  @override
  State<GerarAulasAdminScreen> createState() => _GerarAulasAdminScreenState();
}

class _GerarAulasAdminScreenState extends State<GerarAulasAdminScreen> {
  DateTime? _dataInicio;
  DateTime? _dataFim;

  @override
  void initState() {
    super.initState();
    final periodo = _periodoRecebido;
    _dataInicio = periodo?.dataInicio;
    _dataFim = periodo?.dataFim;
  }

  @override
  Widget build(BuildContext context) {
    final concluidas = widget.estado == EstadoGeracaoAulasAdmin.resultado;
    return FundoTela(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBarInterna(context, 'Gerar aulas'),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    TextoApoio(
                      widget.nomeCronograma ??
                          'Aguardando seleção do cronograma',
                    ),
                    const SizedBox(height: 20),
                    _campoData(
                      rotulo: 'Início do período',
                      data: _dataInicio,
                      dataMinima: DateTime(2000),
                      habilitado: !concluidas,
                      onSelecionar: (valor) => setState(() {
                        _dataInicio = valor;
                        if (_dataFim != null && _dataFim!.isBefore(valor)) {
                          _dataFim = null;
                        }
                      }),
                    ),
                    const SizedBox(height: 20),
                    _campoData(
                      rotulo: 'Fim do período',
                      data: _dataFim,
                      dataMinima: _dataInicio ?? DateTime(2000),
                      habilitado: !concluidas,
                      onSelecionar: (valor) => setState(() => _dataFim = valor),
                    ),
                    const SizedBox(height: 28),
                    if (concluidas)
                      _cartaoResultado()
                    else if (widget.estado == EstadoGeracaoAulasAdmin.previa &&
                        widget.previa != null)
                      _previaEstaAtual
                          ? _cartaoPrevia(widget.previa!)
                          : const _EstadoGeracao(
                              icone: Icons.event_repeat_outlined,
                              mensagem:
                                  'O período mudou. Gere uma nova prévia para continuar.',
                            )
                    else if (_estaCarregando)
                      const _EstadoGeracao(
                        icone: null,
                        mensagem: 'Preparando aulas',
                        carregando: true,
                      )
                    else if (_temErro)
                      _estadoErro()
                    else if (widget.estado == EstadoGeracaoAulasAdmin.periodo)
                      _cartaoPreviaAguardandoDados()
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ),
              _acoesInferiores(concluidas),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }

  bool get _estaCarregando =>
      widget.estado == EstadoGeracaoAulasAdmin.carregandoPrevia ||
      widget.estado == EstadoGeracaoAulasAdmin.criando;

  bool get _temErro =>
      widget.estado == EstadoGeracaoAulasAdmin.erroPrevia ||
      widget.estado == EstadoGeracaoAulasAdmin.semConexaoPrevia ||
      widget.estado == EstadoGeracaoAulasAdmin.erroCriacao ||
      widget.estado == EstadoGeracaoAulasAdmin.semConexaoCriacao;

  PeriodoGeracaoAulasAdmin? get _periodoRecebido =>
      widget.resultado?.periodo ?? widget.previa?.periodo;

  bool get _previaEstaAtual {
    final previa = widget.previa;
    final periodo = _periodoSelecionado;
    return previa != null && _mesmosPeriodos(previa.periodo, periodo);
  }

  bool _mesmosPeriodos(
    PeriodoGeracaoAulasAdmin esperado,
    PeriodoGeracaoAulasAdmin? atual,
  ) {
    if (atual == null || esperado.cronogramaId != atual.cronogramaId) {
      return false;
    }
    return DateUtils.isSameDay(esperado.dataInicio, atual.dataInicio) &&
        DateUtils.isSameDay(esperado.dataFim, atual.dataFim);
  }

  Widget _campoData({
    required String rotulo,
    required DateTime? data,
    required DateTime dataMinima,
    required bool habilitado,
    required ValueChanged<DateTime> onSelecionar,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(
            color: Color(0xFF33413F),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _CampoData(
          data: data,
          habilitado: habilitado,
          onTap: () async {
            final valor = await _pedirData(data, dataMinima);
            if (valor != null && mounted) onSelecionar(valor);
          },
        ),
      ],
    );
  }

  Future<DateTime?> _pedirData(DateTime? dataAtual, DateTime dataMinima) {
    final controlador = TextEditingController(
      text: dataAtual == null ? '' : _formatarData(dataAtual),
    );
    return showGeneralDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar seleção de data',
      barrierColor: Colors.black54,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecionar data',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controlador,
                      autofocus: true,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: 'Data',
                        hintText: 'DD/MM/AAAA',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: corInstitucional,
                          ),
                          onPressed: () {
                            final valor = _lerData(controlador.text);
                            if (valor == null || valor.isBefore(dataMinima)) {
                              _mostrarAvisoData(context);
                              return;
                            }
                            Navigator.of(context).pop(valor);
                          },
                          child: const Text('Confirmar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(controlador.dispose);
  }

  DateTime? _lerData(String texto) {
    final partes = texto.trim().split('/');
    if (partes.length != 3) return null;
    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final ano = int.tryParse(partes[2]);
    if (dia == null || mes == null || ano == null) return null;
    final data = DateTime(ano, mes, dia);
    if (data.year != ano || data.month != mes || data.day != dia) return null;
    if (data.isBefore(DateTime(2000)) || data.isAfter(DateTime(2100))) {
      return null;
    }
    return data;
  }

  String _formatarData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  void _mostrarAvisoData(BuildContext dialogContext) {
    ScaffoldMessenger.of(dialogContext).showSnackBar(
      const SnackBar(content: Text('Informe uma data válida após a data inicial.')),
    );
  }

  Widget _cartaoPreviaAguardandoDados() {
    return _CartaoAulas(
      titulo: 'Aulas que serão criadas',
      resumo: 'A prévia será exibida após selecionar o cronograma e o período.',
      aulas: const [],
    );
  }

  Widget _cartaoPrevia(PreviaGeracaoAulasAdmin previa) {
    final quantidade = previa.quantidadeParaCriar;
    return _CartaoAulas(
      titulo: 'Aulas que serão criadas',
      resumo:
          '${_quantidadeAulas(quantidade)} '
          '${quantidade == 1 ? 'será criada' : 'serão criadas'} · '
          '${previa.quantidadeJaExistentes} já existem no mesmo horário',
      aulas: previa.aulas,
    );
  }

  Widget _cartaoResultado() {
    final resultado = widget.resultado;
    if (resultado == null) {
      return const _EstadoGeracao(
        icone: Icons.event_busy_outlined,
        mensagem: 'O resultado da geração ainda não foi recebido.',
      );
    }
    final quantidade = resultado.quantidadeCriadas;
    return _CartaoAulas(
      titulo: 'Aulas criadas',
      resumo:
          '${_quantidadeAulas(quantidade)} '
          '${quantidade == 1 ? 'criada' : 'criadas'} · '
          '${resultado.quantidadeJaExistentes} puladas por já existirem',
      aulas: resultado.aulas,
      acao: TextButton(
        onPressed: widget.onVerAulasCriadas,
        child: const Text('Ver aulas criadas'),
      ),
    );
  }

  Widget _estadoErro() {
    final semConexao =
        widget.estado == EstadoGeracaoAulasAdmin.semConexaoPrevia ||
            widget.estado == EstadoGeracaoAulasAdmin.semConexaoCriacao;
    return _EstadoGeracao(
      icone: semConexao ? Icons.cloud_off : Icons.error_outline,
      mensagem: semConexao
          ? 'Sem conexão. Confira sua internet e tente novamente.'
          : 'Não foi possível concluir a operação.',
      onTentarNovamente: widget.onTentarNovamente,
    );
  }

  bool get _falhaCriacao =>
      widget.estado == EstadoGeracaoAulasAdmin.erroCriacao ||
      widget.estado == EstadoGeracaoAulasAdmin.semConexaoCriacao;

  bool get _previaDisponivel =>
      widget.estado == EstadoGeracaoAulasAdmin.previa && _previaEstaAtual;

  VoidCallback get _acaoPrincipal {
    if (_falhaCriacao && _previaEstaAtual) {
      return widget.onTentarNovamente ?? _criarAulas;
    }
    return _previaDisponivel ? _criarAulas : _solicitarPrevia;
  }

  String get _rotuloAcaoPrincipal {
    if (_falhaCriacao && _previaEstaAtual) return 'Tentar novamente';
    if (_previaDisponivel) {
      return 'Criar ${_quantidadeAulas(widget.previa!.quantidadeParaCriar)}';
    }
    return 'Ver prévia';
  }

  Widget _acoesInferiores(bool concluidas) {
    if (concluidas) return const SizedBox(height: 8);

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          TextButton(
            onPressed: _estaCarregando
                ? null
                : () => Navigator.of(context).maybePop(),
            child: const Text('Voltar'),
          ),
          const Spacer(),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: corInstitucional),
            onPressed: _estaCarregando ? null : _acaoPrincipal,
            child: Text(_rotuloAcaoPrincipal),
          ),
        ],
      ),
    );
  }

  String _quantidadeAulas(int quantidade) =>
      '$quantidade ${quantidade == 1 ? 'aula' : 'aulas'}';

  void _solicitarPrevia() {
    if (widget.cronogramaId == null ||
        _dataInicio == null ||
        _dataFim == null) {
      _mostrarAviso('Selecione o cronograma e o período para ver a prévia.');
      return;
    }
    if (_dataFim!.isBefore(_dataInicio!)) {
      _mostrarAviso('A data final deve ser igual ou posterior à data inicial.');
      return;
    }
    final callback = widget.onSolicitarPrevia;
    if (callback == null) {
      _mostrarAviso('Prévia aguardando integração dos dados.');
      return;
    }
    callback(
      PeriodoGeracaoAulasAdmin(
        cronogramaId: widget.cronogramaId!,
        dataInicio: _dataInicio!,
        dataFim: _dataFim!,
      ),
    );
  }

  void _criarAulas() {
    final previa = widget.previa;
    if (previa == null) return;
    if (!_previaEstaAtual) {
      _mostrarAviso('Gere uma nova prévia para o período selecionado.');
      return;
    }
    final callback = widget.onCriarAulas;
    if (callback == null) {
      _mostrarAviso('Criação aguardando integração dos dados.');
      return;
    }
    callback(
      ConfirmacaoGeracaoAulasAdmin(
        periodo: previa.periodo,
        previa: previa,
      ),
    );
  }

  PeriodoGeracaoAulasAdmin? get _periodoSelecionado {
    final cronogramaId = widget.cronogramaId;
    final dataInicio = _dataInicio;
    final dataFim = _dataFim;
    if (cronogramaId == null || dataInicio == null || dataFim == null) {
      return null;
    }
    return PeriodoGeracaoAulasAdmin(
      cronogramaId: cronogramaId,
      dataInicio: dataInicio,
      dataFim: dataFim,
    );
  }

  void _mostrarAviso(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }
}

class _CampoData extends StatelessWidget {
  const _CampoData({
    required this.data,
    required this.habilitado,
    required this.onTap,
  });

  final DateTime? data;
  final bool habilitado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final valor = data == null
        ? 'Selecionar data'
        : '${data!.day.toString().padLeft(2, '0')}/'
            '${data!.month.toString().padLeft(2, '0')}/'
            '${data!.year}';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        onTap: habilitado ? onTap : null,
        child: Container(
          height: 48,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFBECBC8)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            valor,
            style: TextStyle(
              color: data == null
                  ? const Color(0xFF78827F)
                  : const Color(0xFF33413F),
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _CartaoAulas extends StatelessWidget {
  const _CartaoAulas({
    required this.titulo,
    required this.resumo,
    required this.aulas,
    this.acao,
  });

  final String titulo;
  final String resumo;
  final List<ItemAulaGeracaoAdmin> aulas;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFBECBC8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                color: Color(0xFF33413F),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              resumo,
              style: const TextStyle(color: corAlerta, fontSize: 12),
            ),
            const SizedBox(height: 14),
            if (aulas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Nenhuma ocorrência para exibir.',
                  style: TextStyle(color: Color(0xFF78827F), fontSize: 13),
                ),
              )
            else
              for (final aula in aulas) ...[
                _LinhaAulaGeracao(aula: aula),
                const Divider(height: 1, color: corDivisor),
              ],
            if (acao != null)
              Align(alignment: Alignment.centerRight, child: acao!),
          ],
        ),
      ),
    );
  }
}

class _LinhaAulaGeracao extends StatelessWidget {
  const _LinhaAulaGeracao({required this.aula});

  final ItemAulaGeracaoAdmin aula;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            aula.dataLegivel,
            style: const TextStyle(
              color: Color(0xFF33413F),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              aula.horario,
              style: TextStyle(
                color: aula.jaExistia ? const Color(0xFF78827F) : null,
                fontSize: 14,
              ),
            ),
          ),
          if (aula.jaExistia)
            const Chip(
              label: Text('Já existe'),
              backgroundColor: corErro,
              labelStyle: TextStyle(color: Colors.white, fontSize: 11),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _EstadoGeracao extends StatelessWidget {
  const _EstadoGeracao({
    required this.icone,
    required this.mensagem,
    this.carregando = false,
    this.onTentarNovamente,
  });

  final IconData? icone;
  final String mensagem;
  final bool carregando;
  final VoidCallback? onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (carregando)
              const CircularProgressIndicator(color: corInstitucional)
            else if (icone != null)
              Icon(icone, size: 30, color: corInstitucional),
            const SizedBox(height: 12),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF78827F), fontSize: 13),
            ),
            if (onTentarNovamente != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onTentarNovamente,
                child: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
