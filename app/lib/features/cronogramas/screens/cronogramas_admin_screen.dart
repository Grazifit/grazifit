import 'package:flutter/material.dart';

import '../../../core/design_system/components/app_bar_interna.dart';
import '../../../core/design_system/components/botao_primario.dart';
import '../../../core/design_system/components/cartao_lista.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/design_system/components/texto_apoio.dart';
import '../data/cronogramas_admin_data.dart';

enum EstadoCronogramasAdmin { carregando, vazio, erro, semConexao, dados }

/// Lista de cronogramas ativos do Admin.
class CronogramasAdminScreen extends StatelessWidget {
  const CronogramasAdminScreen({
    super.key,
    this.dados = CronogramasAdminData.vazio,
    this.estado = EstadoCronogramasAdmin.vazio,
    this.onTentarNovamente,
    this.onNovoCronograma,
    this.onSelecionarCronograma,
  });

  final CronogramasAdminData dados;
  final EstadoCronogramasAdmin estado;
  final VoidCallback? onTentarNovamente;
  final VoidCallback? onNovoCronograma;
  final ValueChanged<CronogramaResumoAdmin>? onSelecionarCronograma;

  static const _verde = Color(0xFF005B50);

  @override
  Widget build(BuildContext context) {
    return FundoTela(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBarInterna(context, 'Cronogramas'),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: TextoApoio('${dados.totalAtivos} cronogramas ativos'),
              ),
              Expanded(child: _conteudo()),
            ],
          ),
        ),
        bottomNavigationBar: BarraAcaoInferior(
          texto: 'Novo cronograma',
          onPressed: () {
            if (onNovoCronograma != null) {
              onNovoCronograma!();
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cadastro pronto para receber a integração.'),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _conteudo() {
    return switch (estado) {
      EstadoCronogramasAdmin.carregando => const Center(
        child: CircularProgressIndicator(color: _verde),
      ),
      EstadoCronogramasAdmin.vazio => const _EstadoCronogramas(
        icone: Icons.event_note_outlined,
        mensagem: 'Nenhum cronograma ativo.',
      ),
      EstadoCronogramasAdmin.erro => _estadoComAcao(
        Icons.error_outline,
        'Não foi possível carregar os cronogramas.',
      ),
      EstadoCronogramasAdmin.semConexao => _estadoComAcao(
        Icons.cloud_off,
        'Sem conexão. Confira sua internet e tente novamente.',
      ),
      EstadoCronogramasAdmin.dados => _lista(),
    };
  }

  Widget _lista() {
    if (dados.itens.isEmpty) {
      return const _EstadoCronogramas(
        icone: Icons.event_note_outlined,
        mensagem: 'Nenhum cronograma ativo.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CartaoLista(
        itens: [
          for (final cronograma in dados.itens)
            ItemLista(
              titulo: cronograma.nome,
              subtitulo: cronograma.resumo,
              onTap: onSelecionarCronograma == null
                  ? null
                  : () => onSelecionarCronograma!(cronograma),
            ),
        ],
      ),
    );
  }

  Widget _estadoComAcao(IconData icone, String mensagem) {
    return _EstadoCronogramas(
      icone: icone,
      mensagem: mensagem,
      onTentarNovamente: onTentarNovamente,
    );
  }
}

class _EstadoCronogramas extends StatelessWidget {
  const _EstadoCronogramas({
    required this.icone,
    required this.mensagem,
    this.onTentarNovamente,
  });

  final IconData icone;
  final String mensagem;
  final VoidCallback? onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 36, color: const Color(0xFF005B50)),
            const SizedBox(height: 12),
            Text(mensagem, textAlign: TextAlign.center),
            if (onTentarNovamente != null) ...[
              const SizedBox(height: 12),
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
