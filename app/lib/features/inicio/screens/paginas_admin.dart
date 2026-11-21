import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repositorios.dart';
import '../../../core/network/api_exception.dart';
import '../../aulas/data/aulas_admin_data.dart';
import '../../aulas/screens/tela_aulas_admin.dart';
import '../../pessoas/data/usuarios_admin_data.dart';
import '../../pessoas/screens/tela_usuarios_admin.dart';
import '../../treinos/screens/treinos_livres_admin_screen.dart';
import '../../treinos/state/treinos_livres_admin_state.dart';
import '../data/inicio_admin_data.dart';
import 'tela_inicio_admin.dart';

final inicioAdminProvider = FutureProvider.autoDispose<InicioAdminData>(
  (ref) => Repositorios.admin.buscarInicio(),
);

final usuariosAdminProvider = FutureProvider.autoDispose<UsuariosAdminData>(
  (ref) => Repositorios.admin.buscarUsuarios(),
);

/// Dia exibido na aba "Aulas" (começa em hoje).
final diaAulasAdminProvider = StateProvider<DateTime>((ref) {
  final agora = DateTime.now();
  return DateTime(agora.year, agora.month, agora.day);
});

final aulasAdminProvider =
    FutureProvider.autoDispose<List<AulaListaAdminData>>(
  (ref) => Repositorios.admin.buscarAulas(ref.watch(diaAulasAdminProvider)),
);

final treinosLivresAdminProvider =
    FutureProvider.autoDispose<List<TreinoLivreAdminItem>>(
  (ref) => Repositorios.admin.buscarTreinosLivres(),
);

bool _semRede(Object? e) => e is ApiException && e.semResposta && !e.pendente;

/// Liga a tela de Início do admin ao repositório: traduz o `AsyncValue` em
/// `estado` + `dados`.
class PaginaInicioAdmin extends ConsumerWidget {
  const PaginaInicioAdmin({
    super.key,
    this.mostrarNavegacaoInferior = true,
    this.onNavegar,
  });

  final bool mostrarNavegacaoInferior;
  final ValueChanged<DestinoInicioAdmin>? onNavegar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(inicioAdminProvider);
    final estado = v.isLoading && !v.hasValue
        ? EstadoInicioAdmin.carregando
        : v.hasError
            ? (_semRede(v.error)
                ? EstadoInicioAdmin.semConexao
                : EstadoInicioAdmin.erro)
            // Sem aulas hoje, o painel ainda mostra os indicadores; a lista
            // de aulas exibe o próprio estado vazio.
            : EstadoInicioAdmin.dados;

    return TelaInicioAdmin(
      dados: v.valueOrNull ?? InicioAdminData.vazio,
      estado: estado,
      mostrarNavegacaoInferior: mostrarNavegacaoInferior,
      onNavegar: onNavegar,
      onTentarNovamente: () => ref.invalidate(inicioAdminProvider),
    );
  }
}

/// Idem, para a tela "Pessoas" do admin.
class PaginaUsuariosAdmin extends ConsumerWidget {
  const PaginaUsuariosAdmin({
    super.key,
    this.mostrarNavegacaoInferior = true,
    this.onNavegar,
  });

  final bool mostrarNavegacaoInferior;
  final ValueChanged<DestinoUsuariosAdmin>? onNavegar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(usuariosAdminProvider);
    final estado = v.isLoading && !v.hasValue
        ? EstadoUsuariosAdmin.carregando
        : v.hasError
            ? (_semRede(v.error)
                ? EstadoUsuariosAdmin.semConexao
                : EstadoUsuariosAdmin.erro)
            : ((v.value?.alunos.isEmpty ?? true) &&
                    (v.value?.professores.isEmpty ?? true))
                ? EstadoUsuariosAdmin.vazio
                : EstadoUsuariosAdmin.dados;

    return TelaUsuariosAdmin(
      dados: v.valueOrNull ?? UsuariosAdminData.vazio,
      estado: estado,
      mostrarNavegacaoInferior: mostrarNavegacaoInferior,
      onNavegar: onNavegar,
      onTentarNovamente: () => ref.invalidate(usuariosAdminProvider),
    );
  }
}

/// Liga a aba "Aulas" do admin ao repositório.
class PaginaAulasAdmin extends ConsumerWidget {
  const PaginaAulasAdmin({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dia = ref.watch(diaAulasAdminProvider);
    final v = ref.watch(aulasAdminProvider);
    // `isLoading` (e não só "sem valor"): ao trocar de dia, não mostrar a
    // lista do dia anterior enquanto a nova carrega.
    final estado = v.isLoading
        ? EstadoAulasAdmin.carregando
        : v.hasError
            ? (_semRede(v.error)
                ? EstadoAulasAdmin.semConexao
                : EstadoAulasAdmin.erro)
            : EstadoAulasAdmin.dados;

    return TelaAulasAdmin(
      dia: dia,
      estado: estado,
      aulas: v.valueOrNull ?? const [],
      onMudarDia: (delta) => ref.read(diaAulasAdminProvider.notifier).state =
          DateTime(dia.year, dia.month, dia.day + delta),
      onTentarNovamente: () => ref.invalidate(aulasAdminProvider),
    );
  }
}

/// Liga a aba "Treinos" do admin (treinos livres) ao repositório.
class PaginaTreinosLivresAdmin extends ConsumerWidget {
  const PaginaTreinosLivresAdmin({super.key, this.onAbrirExercicios});

  final VoidCallback? onAbrirExercicios;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(treinosLivresAdminProvider);
    final estado = v.isLoading && !v.hasValue
        ? EstadoTreinosLivresAdmin.carregando
        : v.hasError
            ? (_semRede(v.error)
                ? EstadoTreinosLivresAdmin.semConexao
                : EstadoTreinosLivresAdmin.erro)
            : (v.value?.isEmpty ?? true)
                ? EstadoTreinosLivresAdmin.vazio
                : EstadoTreinosLivresAdmin.dados;

    return TreinosLivresAdminScreen(
      estado: estado,
      treinos: v.valueOrNull ?? const [],
      mostrarNavegacaoInferior: false,
      onAbrirExercicios: onAbrirExercicios,
      onTentarNovamente: () => ref.invalidate(treinosLivresAdminProvider),
    );
  }
}
