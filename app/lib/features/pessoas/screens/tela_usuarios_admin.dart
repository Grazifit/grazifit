import 'package:flutter/material.dart';

import '../../../core/design_system/components/fundo_tela.dart';
import '../data/usuarios_admin_data.dart';

enum EstadoUsuariosAdmin { carregando, vazio, erro, semConexao, dados }

enum DestinoUsuariosAdmin { inicio, pessoas, aulas, treinos }

enum CategoriaUsuariosAdmin { alunos, professores }

enum FiltroUsuariosAdmin { ativos, inativos }

/// Lista de alunos e professores do perfil Admin.
///
/// A tela trabalha com dados recebidos e callbacks opcionais. A implementação
/// atual usa conteúdo fictício e não consulta serviços externos.
class TelaUsuariosAdmin extends StatefulWidget {
  const TelaUsuariosAdmin({
    super.key,
    this.dados = UsuariosAdminData.demonstracao,
    this.estado = EstadoUsuariosAdmin.dados,
    this.onTentarNovamente,
    this.onSelecionarUsuario,
    this.onAbrirVinculos,
    this.onNavegar,
  });

  final UsuariosAdminData dados;
  final EstadoUsuariosAdmin estado;
  final VoidCallback? onTentarNovamente;
  final ValueChanged<UsuarioAdminData>? onSelecionarUsuario;
  final VoidCallback? onAbrirVinculos;
  final ValueChanged<DestinoUsuariosAdmin>? onNavegar;

  static const _verde = Color(0xFF005B50);
  static const _texto = Color(0xFF33413F);
  static const _apoio = Color(0xFF78827F);
  static const _borda = Color(0xFFBECBC8);

  @override
  State<TelaUsuariosAdmin> createState() => _TelaUsuariosAdminState();
}

class _TelaUsuariosAdminState extends State<TelaUsuariosAdmin> {
  final _buscaController = TextEditingController();
  CategoriaUsuariosAdmin _categoria = CategoriaUsuariosAdmin.alunos;
  FiltroUsuariosAdmin _filtro = FiltroUsuariosAdmin.ativos;
  String _termo = '';

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
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: [
              const _TituloUsuarios(),
              const SizedBox(height: 17),
              _abasCategoria(),
              const SizedBox(height: 16),
              _campoBusca(),
              const SizedBox(height: 12),
              _filtrosStatus(),
              const SizedBox(height: 16),
              _listaUsuarios(),
              const SizedBox(height: 16),
              _cartaoVinculos(),
            ],
          ),
        ),
        bottomNavigationBar: _navegacaoInferior(context),
      ),
    );
  }

  Widget _abasCategoria() {
    return Row(
      children: [
        _AbaCategoria(
          rotulo: 'Alunos',
          selecionada: _categoria == CategoriaUsuariosAdmin.alunos,
          onTap: () => _selecionarCategoria(CategoriaUsuariosAdmin.alunos),
        ),
        const SizedBox(width: 8),
        _AbaCategoria(
          rotulo: 'Professores',
          selecionada: _categoria == CategoriaUsuariosAdmin.professores,
          onTap: () => _selecionarCategoria(CategoriaUsuariosAdmin.professores),
        ),
      ],
    );
  }

  Widget _campoBusca() {
    final tipo = _categoria == CategoriaUsuariosAdmin.alunos
        ? 'aluno'
        : 'professor';

    return SizedBox(
      height: 48,
      child: TextField(
        controller: _buscaController,
        onChanged: (valor) => setState(
          () => _termo = valor.trim().toLowerCase(),
        ),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar $tipo',
          hintStyle: const TextStyle(
            color: TelaUsuariosAdmin._apoio,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: TelaUsuariosAdmin._verde,
            size: 22,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: TelaUsuariosAdmin._borda),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: TelaUsuariosAdmin._borda),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(
              color: TelaUsuariosAdmin._verde,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _filtrosStatus() {
    return Row(
      children: [
        _FiltroStatus(
          rotulo: 'Ativos',
          selecionado: _filtro == FiltroUsuariosAdmin.ativos,
          onTap: () => setState(() => _filtro = FiltroUsuariosAdmin.ativos),
        ),
        const SizedBox(width: 8),
        _FiltroStatus(
          rotulo: 'Inativos',
          selecionado: _filtro == FiltroUsuariosAdmin.inativos,
          onTap: () => setState(() => _filtro = FiltroUsuariosAdmin.inativos),
        ),
      ],
    );
  }

  Widget _listaUsuarios() {
    return switch (widget.estado) {
      EstadoUsuariosAdmin.dados => _listaComDados(),
      EstadoUsuariosAdmin.carregando => const _EstadoLista(
          icone: null,
          mensagem: 'Carregando usuários',
          carregando: true,
        ),
      EstadoUsuariosAdmin.vazio => _EstadoLista(
          icone: Icons.search,
          mensagem: 'Não há usuários para exibir.',
        ),
      EstadoUsuariosAdmin.erro => _EstadoLista(
          icone: Icons.error_outline,
          mensagem: 'Não foi possível carregar os usuários.',
          onTentarNovamente: widget.onTentarNovamente,
        ),
      EstadoUsuariosAdmin.semConexao => _EstadoLista(
          icone: Icons.cloud_off,
          mensagem: 'Sem conexão. Confira sua internet e tente novamente.',
          onTentarNovamente: widget.onTentarNovamente,
        ),
    };
  }

  Widget _listaComDados() {
    final usuarios = _categoria == CategoriaUsuariosAdmin.alunos
        ? widget.dados.alunos
        : widget.dados.professores;
    final ativos = _filtro == FiltroUsuariosAdmin.ativos;
    final filtrados = usuarios
        .where((usuario) => usuario.ativo == ativos)
        .where((usuario) => usuario.nome.toLowerCase().contains(_termo))
        .toList(growable: false);

    if (filtrados.isEmpty) {
      final categoria = _categoria == CategoriaUsuariosAdmin.alunos
          ? 'aluno'
          : 'professor';
      final situacao = ativos ? 'ativo' : 'inativo';
      return _EstadoLista(
        icone: Icons.search,
        mensagem: _termo.isEmpty
            ? 'Nenhum $categoria $situacao.'
            : 'Nenhum usuário encontrado.',
      );
    }

    return Material(
      color: Colors.white,
      child: Column(
        children: [
          for (var indice = 0; indice < filtrados.length; indice++) ...[
            _LinhaUsuario(
              usuario: filtrados[indice],
              onTap: () => _abrirUsuario(filtrados[indice]),
            ),
            if (indice < filtrados.length - 1)
              const Divider(height: 1, color: Color(0xFFD4DEDB)),
          ],
        ],
      ),
    );
  }

  Widget _cartaoVinculos() {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: _abrirVinculos,
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Vínculos professor-aluno',
                    style: TextStyle(
                      color: TelaUsuariosAdmin._texto,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Text(
                    'Abrir',
                    style: TextStyle(
                      color: TelaUsuariosAdmin._verde,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navegacaoInferior(BuildContext context) {
    final alturaComConteudo = (84 - MediaQuery.of(context).viewPadding.bottom)
        .clamp(60.0, 84.0)
        .toDouble();
    const destinos = [
      (DestinoUsuariosAdmin.inicio, Icons.home_outlined, 'Início'),
      (DestinoUsuariosAdmin.pessoas, Icons.people_outline, 'Pessoas'),
      (DestinoUsuariosAdmin.aulas, Icons.directions_run, 'Aulas'),
      (DestinoUsuariosAdmin.treinos, Icons.fitness_center, 'Treinos'),
    ];

    return Container(
      color: TelaUsuariosAdmin._verde,
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
                  selecionado: destino.$1 == DestinoUsuariosAdmin.pessoas,
                  onTap: () => _selecionarDestino(context, destino.$1),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _selecionarCategoria(CategoriaUsuariosAdmin categoria) {
    if (_categoria == categoria) return;
    setState(() {
      _categoria = categoria;
      _termo = '';
      _buscaController.clear();
    });
  }

  void _abrirUsuario(UsuarioAdminData usuario) {
    if (widget.onSelecionarUsuario != null) {
      widget.onSelecionarUsuario!(usuario);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DetalheUsuario(
        usuario: usuario,
        mostrarVinculo: usuario.complemento != null,
      ),
    );
  }

  void _abrirVinculos() {
    if (widget.onAbrirVinculos != null) {
      widget.onAbrirVinculos!();
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _VinculosAguardandoIntegracao(),
    );
  }

  void _selecionarDestino(BuildContext context, DestinoUsuariosAdmin destino) {
    if (widget.onNavegar != null) {
      widget.onNavegar!(destino);
      return;
    }
    if (destino == DestinoUsuariosAdmin.pessoas) return;

    final nome = switch (destino) {
      DestinoUsuariosAdmin.inicio => 'Início',
      DestinoUsuariosAdmin.aulas => 'Aulas',
      DestinoUsuariosAdmin.treinos => 'Treinos',
      DestinoUsuariosAdmin.pessoas => 'Pessoas',
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
}

class _TituloUsuarios extends StatelessWidget {
  const _TituloUsuarios();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Usuários',
      style: TextStyle(
        color: TelaUsuariosAdmin._texto,
        fontSize: 25,
        fontWeight: FontWeight.w700,
        height: 1,
      ),
    );
  }
}

class _AbaCategoria extends StatelessWidget {
  const _AbaCategoria({
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
      color: selecionada ? TelaUsuariosAdmin._verde : const Color(0xFFEFF3F2),
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Center(
              child: Text(
                rotulo,
                style: TextStyle(
                  color: selecionada ? Colors.white : TelaUsuariosAdmin._texto,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FiltroStatus extends StatelessWidget {
  const _FiltroStatus({
    required this.rotulo,
    required this.selecionado,
    required this.onTap,
  });

  final String rotulo;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionado ? const Color(0xFFE2ECE9) : const Color(0xFFEFF3F2),
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                rotulo,
                style: TextStyle(
                  color: TelaUsuariosAdmin._texto,
                  fontSize: 12,
                  fontWeight: selecionado ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinhaUsuario extends StatelessWidget {
  const _LinhaUsuario({
    required this.usuario,
    required this.onTap,
  });

  final UsuarioAdminData usuario;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final complemento = usuario.complemento;
    final subtitulo = complemento == null || complemento.isEmpty
        ? usuario.status
        : '${usuario.status} · $complemento';

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 67,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  usuario.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TelaUsuariosAdmin._texto,
                    fontSize: 13,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TelaUsuariosAdmin._apoio,
                    fontSize: 10,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EstadoLista extends StatelessWidget {
  const _EstadoLista({
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
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (carregando)
            const CircularProgressIndicator(color: TelaUsuariosAdmin._verde)
          else if (icone != null)
            Icon(icone, size: 30, color: TelaUsuariosAdmin._verde),
          const SizedBox(height: 10),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TelaUsuariosAdmin._apoio,
              fontSize: 12,
            ),
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

class _DetalheUsuario extends StatelessWidget {
  const _DetalheUsuario({
    required this.usuario,
    required this.mostrarVinculo,
  });

  final UsuarioAdminData usuario;
  final bool mostrarVinculo;

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
              usuario.nome,
              style: const TextStyle(
                color: TelaUsuariosAdmin._texto,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _LinhaDetalhe(rotulo: 'Situação', valor: usuario.status),
            if (mostrarVinculo && usuario.complemento != null)
              _LinhaDetalhe(
                rotulo: 'Vínculo',
                valor: usuario.complemento!,
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: TelaUsuariosAdmin._verde,
                ),
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

class _VinculosAguardandoIntegracao extends StatelessWidget {
  const _VinculosAguardandoIntegracao();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vínculos professor-aluno',
              style: TextStyle(
                color: TelaUsuariosAdmin._texto,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Esta área está pronta para receber a navegação e os dados de vínculos.',
              style: TextStyle(
                color: TelaUsuariosAdmin._apoio,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: TelaUsuariosAdmin._verde,
                ),
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
            width: 92,
            child: Text(
              rotulo,
              style: const TextStyle(
                color: TelaUsuariosAdmin._apoio,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                color: TelaUsuariosAdmin._texto,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
