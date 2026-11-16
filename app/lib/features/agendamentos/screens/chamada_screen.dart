// app/lib/features/agendamentos/screens/chamada_screen.dart
//
// PROTÓTIPO VISUAL — sem integração com backend. Dados fictícios do mockup.
// Integração com o backend: ver docs/handoff-front-professor.md
//
// Chamada (professor). Cobre os dois quadros do mockup: marcando
// Presente/Faltou por aluno e chamada encerrada (banner verde, botões
// travados). A Chamada (F-11) pertence à feature agendamentos.

import 'package:flutter/material.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/botao_primario.dart';
import '../../../core/design_system/components/cartao_lista.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/design_system/components/texto_apoio.dart';
import '../../../core/design_system/tokens/cores_provisorias.dart';

class ChamadaScreen extends StatefulWidget {
  const ChamadaScreen({
    super.key,
    this.modalidade = 'Funcional',
    this.horario = '07:00 - 08:00',
    this.data = 'Segunda, 01 de setembro',
    this.alunos = const ['Ana Beatriz Ramos', 'Carlos Menezes', 'Júlia Prado'],
    this.marcacoesIniciais,
    this.encerrada = false,
  });

  // Valores padrão = dados fictícios do mockup.
  final String modalidade;
  final String horario;
  final String data;
  final List<String> alunos;

  /// Uma posição por aluno: true = Presente, false = Faltou, null = sem marcar.
  /// Sem informar, todos começam sem marcar.
  final List<bool?>? marcacoesIniciais;

  /// Abre a tela já no estado "chamada encerrada".
  final bool encerrada;

  @override
  State<ChamadaScreen> createState() => _ChamadaScreenState();
}

class _ChamadaScreenState extends State<ChamadaScreen> {
  late final List<bool?> _marcacoes =
      List<bool?>.of(
        widget.marcacoesIniciais ?? List<bool?>.filled(widget.alunos.length, null),
      );
  late bool _encerrada = widget.encerrada;

  int get _presentes => _marcacoes.where((m) => m == true).length;
  int get _faltas => _marcacoes.where((m) => m == false).length;
  int get _marcados => _presentes + _faltas;

  String _plural(int n, String singular, String plural) =>
      '$n ${n == 1 ? singular : plural}';

  void _marcar(int indice, bool presente) {
    if (_encerrada) return;
    setState(() => _marcacoes[indice] = presente);
  }

  // TODO(backend): encerrar grava agendamento.status e data_presenca de cada
  // aluno (F-11, feature agendamentos).
  // TODO(produto): o mockup não define o que acontece com quem ficou sem
  // marcação ao encerrar (bloquear? contar como falta?). Confirmar com o time.
  void _encerrar() {
    setState(() => _encerrada = true);
  }

  @override
  Widget build(BuildContext context) {
    return FundoTela(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBarInterna(context, 'Chamada'),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                '${widget.modalidade} · ${widget.horario}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              TextoApoio(widget.data),
              const SizedBox(height: 12),
              if (_encerrada) ...[
                _BannerEncerrada(
                  texto: 'Chamada encerrada · '
                      '${_plural(_presentes, 'presente', 'presentes')}, '
                      '${_plural(_faltas, 'falta', 'faltas')}',
                ),
                const SizedBox(height: 12),
              ],
              TextoApoio('$_marcados de ${widget.alunos.length} marcados'),
              const SizedBox(height: 8),
              CartaoLista(
                itens: [
                  for (var i = 0; i < widget.alunos.length; i++)
                    _LinhaAluno(
                      nome: widget.alunos[i],
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