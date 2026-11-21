import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import '../theme/app_colors.dart';

/// Textos dos estados que o mockup não define (RNF-04). Ficam todos aqui para
/// o design trocar num lugar só.
///
/// TODO(design): confirmar os textos reais; estes são provisórios.
class TextosEstado {
  TextosEstado._();

  static const carregando = 'Carregando...';
  static const vazio = 'Nada por aqui ainda.';
  static const erro = 'Não foi possível carregar. Tente novamente.';
  static const semConexao = 'Sem conexão com o servidor.';
  static const pendente = 'Esta tela ainda não está ligada ao servidor.';
  static const tentarNovamente = 'Tentar novamente';
}

/// Renderiza os cinco estados da tela a partir de um [AsyncValue]:
/// carregando, vazio, erro, sem conexão e dados (RNF-04).
///
/// [vazio] decide quando "dados" conta como vazio (por padrão: lista vazia).
class EstadoAsync<T> extends StatelessWidget {
  const EstadoAsync({
    super.key,
    required this.valor,
    required this.dados,
    this.aoTentarNovamente,
    this.vazio,
    this.textoVazio = TextosEstado.vazio,
  });

  final AsyncValue<T> valor;
  final Widget Function(T dados) dados;
  final VoidCallback? aoTentarNovamente;
  final bool Function(T dados)? vazio;
  final String textoVazio;

  @override
  Widget build(BuildContext context) {
    return valor.when(
      skipLoadingOnRefresh: false,
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.verde),
      ),
      error: (erro, _) {
        final api = erro is ApiException ? erro : null;
        final texto = api == null
            ? TextosEstado.erro
            : api.pendente
                ? TextosEstado.pendente
                : api.semResposta
                    ? TextosEstado.semConexao
                    : TextosEstado.erro;
        return _Mensagem(
          texto: texto,
          // Endpoint pendente não melhora com nova tentativa.
          aoTentarNovamente: (api?.pendente ?? false) ? null : aoTentarNovamente,
        );
      },
      data: (d) {
        final estaVazio = vazio?.call(d) ?? (d is Iterable && d.isEmpty);
        if (estaVazio) return _Mensagem(texto: textoVazio);
        return dados(d);
      },
    );
  }
}

class _Mensagem extends StatelessWidget {
  const _Mensagem({required this.texto, this.aoTentarNovamente});

  final String texto;
  final VoidCallback? aoTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              texto,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            if (aoTentarNovamente != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: aoTentarNovamente,
                child: const Text(TextosEstado.tentarNovamente),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
