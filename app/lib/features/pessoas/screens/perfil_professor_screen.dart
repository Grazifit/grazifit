// app/lib/features/pessoas/screens/perfil_professor_screen.dart
//
// PROTÓTIPO VISUAL — sem integração com backend. Dados fictícios do mockup.
// Integração com o backend: ver docs/handoff-front-professor.md
//
// Perfil do professor: cabeçalho com nome e data de entrada, cartão com
// e-mail / telefone / CPF e botão "Editar perfil".
// A barra inferior (Agenda / Alunos / Perfil) já vem do design system.

import 'package:flutter/material.dart';

import '../../../core/design_system/components/barra_navegacao.dart';
import '../../../core/design_system/components/cartao_lista.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/design_system/tokens/cores_provisorias.dart';
import 'editar_perfil_professor_screen.dart';

class PerfilProfessorScreen extends StatelessWidget {
  const PerfilProfessorScreen({
    super.key,
    this.nome = 'Marina Alves',
    this.desde = '04/01/2025',
    this.email = 'marina.alves@exemplo.com',
    this.telefone = '(45) 90000-0001',
    this.cpf = '000.000.000-01',
  });

  // TODO(backend): GET /professor/<id> existe, mas só admin acessa e o DTO
  // público NÃO traz cpf nem data_cadastro ("Professora desde"). Ver o
  // guia, itens L1 e L2.
  // Valores padrão = dados fictícios do mockup. No real virão do backend.
  final String nome;
  final String desde;
  final String email;
  final String telefone;
  final String cpf;

  void _abrirEdicao(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditarPerfilProfessorScreen(
          nome: nome,
          telefone: telefone,
          email: email,
          cpf: cpf,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FundoTela(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _CabecalhoProfessor(nome: nome, desde: desde),
              const SizedBox(height: 12),
              // Valor em cima, rótulo embaixo (como no mockup).
              CartaoLista(
                itens: [
                  ItemLista(titulo: email, subtitulo: 'E-mail'),
                  ItemLista(titulo: telefone, subtitulo: 'Telefone'),
                  ItemLista(titulo: cpf, subtitulo: 'CPF'),
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
                  onPressed: () => _abrirEdicao(context),
                  child: const Text(
                    'Editar perfil',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const BarraNavegacao(indiceAtual: 2),
      ),
    );
  }
}

/// Cartão verde do topo: marca + nome + "Professora desde ...".
class _CabecalhoProfessor extends StatelessWidget {
  const _CabecalhoProfessor({required this.nome, required this.desde});

  final String nome;
  final String desde;

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
                  'Professora desde $desde',
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