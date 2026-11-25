// app/lib/features/pessoas/screens/perfil_professor_screen.dart
//
// PROTÓTIPO VISUAL — sem integração com backend. Dados fictícios do mockup.
// Integração com o backend: ver docs/handoff-front-professor.md
//
// Perfil do professor: cabeçalho com nome e data de entrada, cartão com
// e-mail / telefone / CPF e botão "Editar perfil".
// A barra inferior (Agenda / Alunos / Perfil) já vem do design system.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/components/barra_navegacao.dart';
import '../../../core/design_system/components/cartao_lista.dart';
import '../../../core/design_system/tokens/cores_provisorias.dart';
import '../../../core/design_system/components/botao_sair.dart';
import '../../../core/state/estado_async.dart';
import '../data/professor_repository.dart';
import '../state/perfil_professor_providers.dart';
import 'editar_perfil_professor_screen.dart';

class PerfilProfessorScreen extends ConsumerWidget {
  const PerfilProfessorScreen({super.key});

  /// Campo que o backend ainda não devolve.
  static const _semDado = '—';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilProfessorProvider);

    return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: BotaoSair(),
                ),
              ),
              Expanded(
                child: EstadoAsync<Professor>(
                  valor: perfil,
                  aoTentarNovamente: () =>
                      ref.invalidate(perfilProfessorProvider),
                  vazio: (_) => false,
                  dados: (p) => ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _CabecalhoProfessor(nome: p.nome, desde: p.desde),
                      const SizedBox(height: 12),
                      // Valor em cima, rótulo embaixo (como no mockup).
                      CartaoLista(
                        itens: [
                          ItemLista(titulo: p.email, subtitulo: 'E-mail'),
                          ItemLista(titulo: p.telefone, subtitulo: 'Telefone'),
                          ItemLista(titulo: p.cpf ?? _semDado, subtitulo: 'CPF'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: corInstitucional,
                            side: const BorderSide(color: corInstitucional),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () =>
                              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EditarPerfilProfessorScreen(professor: p))),
                          child: const Text(
                            'Editar perfil',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const BarraNavegacao(indiceAtual: 2),
      );
  }
}

/// Cartão verde do topo: marca + nome + "Professora desde ...".
class _CabecalhoProfessor extends StatelessWidget {
  const _CabecalhoProfessor({required this.nome, required this.desde});

  final String nome;
  final String? desde;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: corInstitucional,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // TODO(specs): trocar pelo logotipo real (assets/images/marca.png)
          // quando o asset estiver declarado no pubspec.yaml.
          const Text(
            'GRAZI\nBRAZ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desde == null ? '' : 'Professora desde $desde',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}