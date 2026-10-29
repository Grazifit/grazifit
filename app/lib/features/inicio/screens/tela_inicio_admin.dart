import 'package:flutter/material.dart';

import '../../../core/design_system/components/fundo_tela.dart';
import '../data/inicio_admin_data.dart';

enum EstadoInicioAdmin { carregando, vazio, erro, semConexao, dados }

enum DestinoInicioAdmin { inicio, pessoas, aulas, treinos }

/// Painel inicial do perfil Admin.
///
/// A tela recebe dados e callbacks por construtor. A versão atual usa dados
/// locais de demonstração e não faz chamadas de rede.
class TelaInicioAdmin extends StatelessWidget {
  const TelaInicioAdmin({
    super.key,
    this.dados = InicioAdminData.exemplo,
    this.estado = EstadoInicioAdmin.dados,
    this.onTentarNovamente,
    this.onNavegar,
    this.onAbrirAula,
  });

  final InicioAdminData dados;
  final EstadoInicioAdmin estado;
  final VoidCallback? onTentarNovamente;
  final ValueChanged<DestinoInicioAdmin>? onNavegar;
  final ValueChanged<AulaAdminData>? onAbrirAula;

  static const _verde = Color(0xFF005B50);
  static const _texto = Color(0xFF33413F);
  static const _cinza = Color(0xFF78827F);
  static const _laranja = Color(0xFFE97542);

  @override
  Widget build(BuildContext context) {
    return FundoTela(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: switch (estado) {
            EstadoInicioAdmin.dados => _conteudo(context),
            EstadoInicioAdmin.carregando => _estadoSimples(
                context,
                icone: null,
                mensagem: 'Carregando informações do dia',
                carregando: true,
              ),
            EstadoInicioAdmin.vazio => _estadoSimples(
                context,
                icone: Icons.event_busy,
                mensagem: 'Nenhuma informação disponível para hoje.',
              ),
            EstadoInicioAdmin.erro => _estadoSimples(
                context,
                icone: Icons.error_outline,
                mensagem: 'Não foi possível carregar o início.',
                permitirNovaTentativa: true,
              ),
            EstadoInicioAdmin.semConexao => _estadoSimples(
                context,
                icone: Icons.cloud_off,
                mensagem: 'Sem conexão. Confira sua internet e tente novamente.',
                permitirNovaTentativa: true,
              ),
          },
        ),
        bottomNavigationBar: _navegacaoInferior(context),
      ),
    );
  }

  Widget _conteudo(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _CabecalhoAdmin(),
        const SizedBox(height: 17),
        Text(
          dados.dataLegivel,
          style: const TextStyle(
            color: _cinza,
            fontSize: 11,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 17),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _IndicadorResumo(
                rotulo: 'Aulas hoje',
                valor: '${dados.aulasHoje}',
                corValor: _verde,
              ),
            ),
            Expanded(
              child: _IndicadorResumo(
                rotulo: 'Ocupação',
                valor: '${dados.ocupacaoPercentual}%',
                corValor: _laranja,
              ),
            ),
            Expanded(
              child: _IndicadorResumo(
                rotulo: 'Inativos',
                valor: '${dados.pessoasInativas}',
                corValor: _texto,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Aulas de hoje',
          style: TextStyle(
            color: _texto,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        if (dados.aulas.isEmpty)
          const _ListaVazia()
        else
          for (var indice = 0; indice < dados.aulas.length; indice++) ...[
            _CartaoAula(
              aula: dados.aulas[indice],
              onTap: () => _abrirAula(context, dados.aulas[indice]),
            ),
            if (indice < dados.aulas.length - 1)
              const SizedBox(height: 12),
          ],
      ],
    );
  }

  Widget _estadoSimples(
    BuildContext context, {
    required IconData? icone,
    required String mensagem,
    bool carregando = false,
    bool permitirNovaTentativa = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (carregando)
              const CircularProgressIndicator(color: _verde)
            else if (icone != null)
              Icon(icone, color: _verde, size: 38),
            const SizedBox(height: 14),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _texto, fontSize: 14, height: 1.4),
            ),
            if (permitirNovaTentativa && onTentarNovamente != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onTentarNovamente,
                style: OutlinedButton.styleFrom(foregroundColor: _verde),
                child: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _navegacaoInferior(BuildContext context) {
    final alturaComConteudo = (84 - MediaQuery.of(context).viewPadding.bottom)
        .clamp(60.0, 84.0)
        .toDouble();
    const destinos = [
      (DestinoInicioAdmin.inicio, Icons.home_outlined, 'Início'),
      (DestinoInicioAdmin.pessoas, Icons.people_outline, 'Pessoas'),
      (DestinoInicioAdmin.aulas, Icons.directions_run, 'Aulas'),
      (DestinoInicioAdmin.treinos, Icons.fitness_center, 'Treinos'),
    ];

    return Container(
      color: _verde,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: alturaComConteudo,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final destino in destinos)
                _ItemNavegacao(
                  icone: destino.$2,
                  rotulo: destino.$3,
                  selecionado: destino.$1 == DestinoInicioAdmin.inicio,
                  onTap: () => _selecionarDestino(context, destino.$1),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _selecionarDestino(BuildContext context, DestinoInicioAdmin destino) {
    if (onNavegar != null) {
      onNavegar!(destino);
      return;
    }
    if (destino == DestinoInicioAdmin.inicio) return;

    final nome = switch (destino) {
      DestinoInicioAdmin.pessoas => 'Pessoas',
      DestinoInicioAdmin.aulas => 'Aulas',
      DestinoInicioAdmin.treinos => 'Treinos',
      DestinoInicioAdmin.inicio => 'Início',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('A área de $nome aguarda integração.'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _abrirAula(BuildContext context, AulaAdminData aula) {
    if (onAbrirAula != null) {
      onAbrirAula!(aula);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DetalheAula(aula: aula),
    );
  }
}

class _CabecalhoAdmin extends StatelessWidget {
  const _CabecalhoAdmin();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        children: const [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Hoje',
              style: TextStyle(
                color: TelaInicioAdmin._texto,
                fontSize: 25,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
          _MarcaColorida(),
        ],
      ),
    );
  }
}

class _MarcaColorida extends StatelessWidget {
  const _MarcaColorida();

  @override
  Widget build(BuildContext context) {
    const cores = [
      Color(0xFF126D74),
      Color(0xFFE99A22),
      Color(0xFF087D8A),
      Color(0xFFF2B62B),
    ];

    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 1,
            child: _Petala(cor: cores[0]),
          ),
          Positioned(
            right: 1,
            child: Transform.rotate(
              angle: 1.5708,
              child: _Petala(cor: cores[1]),
            ),
          ),
          Positioned(
            bottom: 1,
            child: Transform.rotate(
              angle: 3.1416,
              child: _Petala(cor: cores[2]),
            ),
          ),
          Positioned(
            left: 1,
            child: Transform.rotate(
              angle: -1.5708,
              child: _Petala(cor: cores[3]),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(color: Color(0xFFEBA72A), shape: BoxShape.circle),
            child: SizedBox(width: 4, height: 4),
          ),
        ],
      ),
    );
  }
}

class _Petala extends StatelessWidget {
  const _Petala({required this.cor});

  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 15,
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _IndicadorResumo extends StatelessWidget {
  const _IndicadorResumo({
    required this.rotulo,
    required this.valor,
    required this.corValor,
  });

  final String rotulo;
  final String valor;
  final Color corValor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: TelaInicioAdmin._cinza, fontSize: 11),
        ),
        const SizedBox(height: 5),
        Text(
          valor,
          style: TextStyle(
            color: corValor,
            fontSize: 31,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _CartaoAula extends StatelessWidget {
  const _CartaoAula({required this.aula, required this.onTap});

  final AulaAdminData aula;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          constraints: const BoxConstraints(minHeight: 151),
          padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFBECBC8)),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${aula.horarioInicio} – ${aula.horarioFim}',
                      style: const TextStyle(
                        color: TelaInicioAdmin._texto,
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  ),
                  if (aula.destaqueVagas != null)
                    _EtiquetaDestaque(texto: aula.destaqueVagas!),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.accessibility_new,
                    color: Color(0xFF39827C),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    aula.modalidade,
                    style: const TextStyle(color: TelaInicioAdmin._texto, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EFED),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      aula.formato,
                      style: const TextStyle(color: TelaInicioAdmin._texto, fontSize: 10),
                    ),
                  ),
                ],
              ),
              Text(
                aula.professor,
                style: const TextStyle(color: TelaInicioAdmin._texto, fontSize: 13),
              ),
              Text(
                aula.resumoVagas,
                style: TextStyle(
                  color: aula.destaqueVagas == null
                      ? TelaInicioAdmin._texto
                      : const Color(0xFF9A5B00),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EtiquetaDestaque extends StatelessWidget {
  const _EtiquetaDestaque({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF905500),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        texto,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}

class _ListaVazia extends StatelessWidget {
  const _ListaVazia();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFBECBC8)),
      ),
      child: const Text(
        'Não há aulas programadas para hoje.',
        style: TextStyle(color: TelaInicioAdmin._cinza, fontSize: 13),
      ),
    );
  }
}

class _ItemNavegacao extends StatelessWidget {
  const _ItemNavegacao({
    required this.icone,
    required this.rotulo,
    required this.selecionado,
    required this.onTap,
  });

  final IconData icone;
  final String rotulo;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selecionado,
      label: rotulo,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 72,
          height: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: selecionado ? 28 : 0,
                height: 3,
                margin: const EdgeInsets.only(bottom: 7),
                decoration: BoxDecoration(
                  color: selecionado ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Icon(
                icone,
                size: 22,
                color: selecionado ? Colors.white : Colors.white70,
              ),
              const SizedBox(height: 4),
              Text(
                rotulo,
                style: TextStyle(
                  color: selecionado ? Colors.white : Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetalheAula extends StatelessWidget {
  const _DetalheAula({required this.aula});

  final AulaAdminData aula;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${aula.horarioInicio} – ${aula.horarioFim}',
              style: const TextStyle(
                color: TelaInicioAdmin._texto,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _LinhaDetalhe(rotulo: 'Modalidade', valor: aula.modalidade),
            _LinhaDetalhe(rotulo: 'Formato', valor: aula.formato),
            _LinhaDetalhe(rotulo: 'Professor', valor: aula.professor),
            _LinhaDetalhe(rotulo: 'Ocupação', valor: aula.resumoVagas),
            if (aula.destaqueVagas != null)
              _LinhaDetalhe(rotulo: 'Disponibilidade', valor: aula.destaqueVagas!),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: TelaInicioAdmin._verde),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinhaDetalhe extends StatelessWidget {
  const _LinhaDetalhe({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(rotulo, style: const TextStyle(color: TelaInicioAdmin._cinza, fontSize: 13)),
          ),
          Expanded(
            child: Text(valor, style: const TextStyle(color: TelaInicioAdmin._texto, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
