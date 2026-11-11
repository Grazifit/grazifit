import 'package:flutter/material.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/botao_primario.dart';
import '../../../core/design_system/components/campo_busca.dart';
import '../../../core/design_system/components/cartao_lista.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/design_system/components/texto_apoio.dart';
import '../data/vinculos_admin_data.dart';

enum EstadoVinculosAdmin { carregando, vazio, erro, semConexao, dados }

enum FiltroVinculosAdmin { ativos, encerrados }

/// Lista administrativa de vínculos professor-aluno.
/// Operações são delegadas por callbacks; a tela não altera vínculos localmente.
class VinculosAdminScreen extends StatefulWidget {
  const VinculosAdminScreen({
    super.key,
    this.dados = VinculosAdminData.demonstracao,
    this.estado = EstadoVinculosAdmin.dados,
    this.onTentarNovamente,
    this.onNovoVinculo,
    this.onEncerrarVinculo,
  });

  final VinculosAdminData dados;
  final EstadoVinculosAdmin estado;
  final VoidCallback? onTentarNovamente;
  final VoidCallback? onNovoVinculo;
  final ValueChanged<VinculoAdminData>? onEncerrarVinculo;

  @override
  State<VinculosAdminScreen> createState() => _VinculosAdminScreenState();
}

class _VinculosAdminScreenState extends State<VinculosAdminScreen> {
  final _buscaController = TextEditingController();
  FiltroVinculosAdmin _filtro = FiltroVinculosAdmin.ativos;
  String _busca = '';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FundoTela(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBarInterna(context, 'Vínculos'),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CampoBusca(
                      controller: _buscaController,
                      hint: 'Buscar aluno',
                      onChanged: (valor) => setState(() => _busca = valor),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _FiltroChip(
                          texto: 'Ativos',
                          selecionado: _filtro == FiltroVinculosAdmin.ativos,
                          onTap: () => _selecionar(FiltroVinculosAdmin.ativos),
                        ),
                        const SizedBox(width: 8),
                        _FiltroChip(
                          texto: 'Encerrados',
                          selecionado:
                              _filtro == FiltroVinculosAdmin.encerrados,
                          onTap: () =>
                              _selecionar(FiltroVinculosAdmin.encerrados),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _conteudo()),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextoApoio(
                  'Cada aluno pode ter no máximo um professor ativo.',
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BarraAcaoInferior(
          texto: 'Novo vínculo',
          onPressed: _abrirNovoVinculo,
        ),
      ),
    );
  }

  Widget _conteudo() {
    return switch (widget.estado) {
      EstadoVinculosAdmin.carregando => const Center(
        child: CircularProgressIndicator(color: Color(0xFF005B50)),
      ),
      EstadoVinculosAdmin.vazio => const _EstadoListaVinculos(
        mensagem: 'Nenhum vínculo cadastrado.',
      ),
      EstadoVinculosAdmin.erro => _estadoComAcao(
        Icons.error_outline,
        'Não foi possível carregar os vínculos.',
      ),
      EstadoVinculosAdmin.semConexao => _estadoComAcao(
        Icons.cloud_off,
        'Sem conexão. Confira sua internet e tente novamente.',
      ),
      EstadoVinculosAdmin.dados => _lista(),
    };
  }

  Widget _lista() {
    final itens = _filtro == FiltroVinculosAdmin.ativos
        ? widget.dados.ativos
        : widget.dados.encerrados;
    final termo = _busca.trim().toLowerCase();
    final filtrados = itens
        .where((vinculo) => vinculo.alunoNome.toLowerCase().contains(termo))
        .toList(growable: false);

    if (filtrados.isEmpty) {
      final mensagem = termo.isNotEmpty
          ? 'Nenhum aluno encontrado.'
          : _filtro == FiltroVinculosAdmin.ativos
          ? 'Nenhum vínculo ativo.'
          : 'Nenhum vínculo encerrado.';
      return _EstadoListaVinculos(mensagem: mensagem);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CartaoLista(
        itens: [
          for (final vinculo in filtrados)
            ItemLista(
              titulo: vinculo.alunoNome,
              trailing: _filtro == FiltroVinculosAdmin.ativos
                  ? TextButton(
                      onPressed: () => _confirmarEncerramento(vinculo),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF005B50),
                      ),
                      child: const Text('Encerrar'),
                    )
                  : null,
            ),
        ],
      ),
    );
  }

  Widget _estadoComAcao(IconData icone, String mensagem) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 36, color: const Color(0xFF005B50)),
            const SizedBox(height: 12),
            Text(mensagem, textAlign: TextAlign.center),
            if (widget.onTentarNovamente != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onTentarNovamente,
                child: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarEncerramento(VinculoAdminData vinculo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Encerrar vínculo?'),
        content: Text('O vínculo de ${vinculo.alunoNome} será encerrado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF005B50),
            ),
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final callback = widget.onEncerrarVinculo;
    if (callback == null) {
      _mostrarAguardandoIntegracao('Encerrar vínculo');
      return;
    }
    callback(vinculo);
  }

  void _abrirNovoVinculo() {
    final callback = widget.onNovoVinculo;
    if (callback == null) {
      _mostrarAguardandoIntegracao('Criar vínculo');
      return;
    }
    callback();
  }

  void _mostrarAguardandoIntegracao(String acao) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$acao aguarda integração dos dados.')),
      );
  }

  void _selecionar(FiltroVinculosAdmin filtro) {
    if (_filtro == filtro) return;
    setState(() {
      _filtro = filtro;
      _busca = '';
      _buscaController.clear();
    });
  }
}

class _FiltroChip extends StatelessWidget {
  const _FiltroChip({
    required this.texto,
    required this.selecionado,
    required this.onTap,
  });

  final String texto;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionado ? const Color(0xFF005B50) : const Color(0xFFEFF3F2),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Text(
            texto,
            style: TextStyle(
              color: selecionado ? Colors.white : const Color(0xFF33413F),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _EstadoListaVinculos extends StatelessWidget {
  const _EstadoListaVinculos({required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          mensagem,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF78827F), fontSize: 14),
        ),
      ),
    );
  }
}
