import 'package:flutter/material.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/campo_busca.dart';
import '../../../core/design_system/components/cartao_lista.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/design_system/components/texto_apoio.dart';
import '../data/inativos_admin_data.dart';

enum EstadoPainelInativosAdmin { carregando, vazio, erro, semConexao, dados }

enum CategoriaInativosAdmin { alunos, professores }

/// Painel do Admin para consultar alunos e professores sem acesso recente.
/// A tela recebe os resultados já preparados e não decide a regra D23.
class PainelInativosAdminScreen extends StatefulWidget {
  const PainelInativosAdminScreen({
    super.key,
    this.dados = InativosAdminData.demonstracao,
    this.estado = EstadoPainelInativosAdmin.dados,
    this.onTentarNovamente,
    this.onSelecionarPessoa,
  });

  final InativosAdminData dados;
  final EstadoPainelInativosAdmin estado;
  final VoidCallback? onTentarNovamente;
  final ValueChanged<PessoaInativaAdminData>? onSelecionarPessoa;

  @override
  State<PainelInativosAdminScreen> createState() =>
      _PainelInativosAdminScreenState();
}

class _PainelInativosAdminScreenState extends State<PainelInativosAdminScreen> {
  final _buscaController = TextEditingController();
  CategoriaInativosAdmin _categoria = CategoriaInativosAdmin.alunos;
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
        appBar: appBarInterna(context, 'Inativos'),
        body: SafeArea(
          child: widget.estado == EstadoPainelInativosAdmin.vazio
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: TextoApoio('Sem acesso há 30 dias ou mais'),
                    ),
                    const Expanded(child: _EstadoVazioInativos()),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TextoApoio('Sem acesso há 30 dias ou mais'),
                          const SizedBox(height: 16),
                          CampoBusca(
                            controller: _buscaController,
                            hint: 'Buscar pessoa',
                            onChanged: (valor) =>
                                setState(() => _busca = valor),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _CategoriaChip(
                                texto: 'Alunos',
                                selecionado:
                                    _categoria == CategoriaInativosAdmin.alunos,
                                onTap: () =>
                                    _selecionar(CategoriaInativosAdmin.alunos),
                              ),
                              const SizedBox(width: 8),
                              _CategoriaChip(
                                texto: 'Professores',
                                selecionado:
                                    _categoria ==
                                    CategoriaInativosAdmin.professores,
                                onTap: () => _selecionar(
                                  CategoriaInativosAdmin.professores,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(child: _conteudo()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _conteudo() {
    return switch (widget.estado) {
      EstadoPainelInativosAdmin.carregando => const Center(
        child: CircularProgressIndicator(color: Color(0xFF005B50)),
      ),
      EstadoPainelInativosAdmin.vazio => const _EstadoVazioInativos(),
      EstadoPainelInativosAdmin.erro => _estadoComAcao(
        Icons.error_outline,
        'Não foi possível carregar os inativos.',
      ),
      EstadoPainelInativosAdmin.semConexao => _estadoComAcao(
        Icons.cloud_off,
        'Sem conexão. Confira sua internet e tente novamente.',
      ),
      EstadoPainelInativosAdmin.dados => _listaDados(),
    };
  }

  Widget _listaDados() {
    final pessoas = _categoria == CategoriaInativosAdmin.alunos
        ? widget.dados.alunos
        : widget.dados.professores;
    final termo = _busca.trim().toLowerCase();
    final filtradas = pessoas
        .where((pessoa) => pessoa.nome.toLowerCase().contains(termo))
        .toList(growable: false);

    if (filtradas.isEmpty) {
      if (termo.isNotEmpty) {
        return const Center(child: Text('Nenhuma pessoa encontrada.'));
      }
      final categoria = _categoria == CategoriaInativosAdmin.alunos
          ? 'aluno'
          : 'professor';
      return Center(child: Text('Nenhum $categoria inativo.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CartaoLista(
        itens: [
          for (final pessoa in filtradas)
            ItemLista(
              titulo: pessoa.nome,
              subtitulo: pessoa.resumoAcesso,
              onTap: widget.onSelecionarPessoa == null
                  ? null
                  : () => widget.onSelecionarPessoa!(pessoa),
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

  void _selecionar(CategoriaInativosAdmin categoria) {
    if (_categoria == categoria) return;
    setState(() {
      _categoria = categoria;
      _busca = '';
      _buscaController.clear();
    });
  }
}

class _CategoriaChip extends StatelessWidget {
  const _CategoriaChip({
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

class _EstadoVazioInativos extends StatelessWidget {
  const _EstadoVazioInativos();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF6B35), width: 2),
              ),
              child: const Icon(
                Icons.query_stats_outlined,
                color: Color(0xFFFF6B35),
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ninguém está inativo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF33413F),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Todos os alunos e professores acessaram nos últimos 30 dias.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF78827F),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
