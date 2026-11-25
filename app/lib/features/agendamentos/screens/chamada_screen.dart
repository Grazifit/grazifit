// app/lib/features/agendamentos/screens/chamada_screen.dart
//
// Alunos de `detalheAulaProvider(idAula)`; encerrar depende do backend.
// Integração: docs/integracao-frontend.md
//
// Chamada (professor). Cobre os dois quadros do mockup: marcando
// Presente/Faltou por aluno e chamada encerrada (banner verde, botões
// travados). A Chamada (F-11) pertence à feature agendamentos.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/botao_primario.dart';
import '../../../core/design_system/components/cartao_lista.dart';
import '../../../core/design_system/components/texto_apoio.dart';
import '../../../core/design_system/tokens/cores_provisorias.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/state/estado_async.dart';
import '../../../core/utils/datas.dart';
import '../../aulas/data/aulas_professor_repository.dart';
import '../../aulas/state/aulas_providers.dart';
import '../../../core/data/repositorios.dart';

class ChamadaScreen extends ConsumerWidget {
  const ChamadaScreen({super.key, required this.idAula});

  final int idAula;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalhe = ref.watch(detalheAulaProvider(idAula));
    final d = detalhe.valueOrNull;
    if (d != null) return _ChamadaConteudo(detalhe: d);

    return Scaffold(
        appBar: appBarInterna(context, 'Chamada'),
        body: SafeArea(
          child: EstadoAsync<AulaProfessorDetalhe>(
            valor: detalhe,
            aoTentarNovamente: () => ref.invalidate(detalheAulaProvider(idAula)),
            vazio: (_) => false,
            dados: (_) => const SizedBox.shrink(),
          ),
        ),
      );
  }
}

class _ChamadaConteudo extends ConsumerStatefulWidget {
  const _ChamadaConteudo({required this.detalhe});

  final AulaProfessorDetalhe detalhe;

  @override
  ConsumerState<_ChamadaConteudo> createState() => _ChamadaConteudoState();
}

class _ChamadaConteudoState extends ConsumerState<_ChamadaConteudo> {
  List<AlunoNaAula> get _alunos => widget.detalhe.alunos;

  /// Uma posição por aluno: true = Presente, false = Faltou, null = sem marcar.
  late final List<bool?> _marcacoes =
      List<bool?>.filled(widget.detalhe.alunos.length, null);
  bool _encerrada = false;

  int get _presentes => _marcacoes.where((m) => m == true).length;
  int get _faltas => _marcacoes.where((m) => m == false).length;
  int get _marcados => _presentes + _faltas;

  String _plural(int n, String singular, String plural) =>
      '$n ${n == 1 ? singular : plural}';

  void _marcar(int indice, bool presente) {
    if (_encerrada) return;
    setState(() => _marcacoes[indice] = presente);
  }

  // TODO(produto): o mockup não define o que acontece com quem ficou sem
  // marcação ao encerrar (bloquear? contar como falta?). Confirmar com o time.
  Future<void> _encerrar() async {
    final mensagem = ScaffoldMessenger.of(context);
    try {
      await Repositorios.aulasProfessor.encerrarChamada(
        widget.detalhe.aula.idAula,
        {for (var i = 0; i < _alunos.length; i++) _alunos[i].idAluno: _marcacoes[i]},
      );
    } on ApiException {
      // TODO(design): texto do erro ao encerrar não está no mockup.
      mensagem.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível encerrar. Tente novamente.'),
        ),
      );
      return;
    }
    if (mounted) setState(() => _encerrada = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: appBarInterna(context, 'Chamada'),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                '${widget.detalhe.aula.modalidade} · ${widget.detalhe.aula.horario}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              TextoApoio(Datas.porExtenso(widget.detalhe.data) ?? widget.detalhe.data),
              const SizedBox(height: 12),
              if (_encerrada) ...[
                _BannerEncerrada(
                  texto: 'Chamada encerrada · '
                      '${_plural(_presentes, 'presente', 'presentes')}, '
                      '${_plural(_faltas, 'falta', 'faltas')}',
                ),
                const SizedBox(height: 12),
              ],
              TextoApoio('$_marcados de ${_alunos.length} marcados'),
              const SizedBox(height: 8),
              CartaoLista(
                itens: [
                  for (var i = 0; i < _alunos.length; i++)
                    _LinhaAluno(
                      nome: _alunos[i].nome,
                      marcacao: _marcacoes[i],
                      travada: _encerrada,
                      onMarcar: (presente) => _marcar(i, presente),
                    ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: BarraAcaoInferior(
          texto: _encerrada ? 'Chamada encerrada' : 'Encerrar chamada',
          onPressed: _encerrada ? null : _encerrar,
        ),
      );
  }
}

class _LinhaAluno extends StatelessWidget {
  const _LinhaAluno({
    required this.nome,
    required this.marcacao,
    required this.travada,
    required this.onMarcar,
  });

  final String nome;
  final bool? marcacao;
  final bool travada;
  final ValueChanged<bool> onMarcar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              nome,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          _BotaoPresenca(
            texto: 'Presente',
            selecionado: marcacao == true,
            corSelecionado: corInstitucional,
            onTap: travada ? null : () => onMarcar(true),
          ),
          const SizedBox(width: 8),
          _BotaoPresenca(
            texto: 'Faltou',
            selecionado: marcacao == false,
            corSelecionado: corAlerta,
            onTap: travada ? null : () => onMarcar(false),
          ),
        ],
      ),
    );
  }
}

class _BotaoPresenca extends StatelessWidget {
  const _BotaoPresenca({
    required this.texto,
    required this.selecionado,
    required this.corSelecionado,
    required this.onTap,
  });

  final String texto;
  final bool selecionado;
  final Color corSelecionado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionado ? corSelecionado : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(
          color: selecionado ? corSelecionado : Colors.grey.shade400,
        ),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selecionado ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerEncerrada extends StatelessWidget {
  const _BannerEncerrada({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: corInstitucional,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(Icons.check, size: 20, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}