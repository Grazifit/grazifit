// app/lib/dev/menu_dev_screen.dart
//
// MENU APENAS PARA DESENVOLVIMENTO: abre qualquer tela sem passar pelo login.
// Só é usado por lib/main_dev.dart (flutter run -t lib/main_dev.dart).
// A main.dart de produção NÃO importa nada de lib/dev/.
//
// Para registrar uma tela nova: importe-a e adicione UMA linha em [_grupos].

import 'package:flutter/material.dart';


import '../features/pessoas/screens/boas_vindas_alunos.dart';
import '../features/pessoas/screens/criar_cadastro_aluno.dart';
import '../features/pessoas/screens/cadastro_professor_screen.dart';
import '../features/pessoas/screens/editar_perfil_aluno.dart';
import '../features/pessoas/screens/editar_perfil_professor_screen.dart';
import '../features/pessoas/screens/perfil_professor_screen.dart';
import '../features/pessoas/screens/tela_perfil_aluno.dart';

import '../features/treinos/screens/treinos_aluno_screen.dart';
import '../features/treinos/screens/historico_treinos_screen.dart';
import '../features/treinos/screens/montar_treino_screen.dart';

import '../features/vinculos/screens/meus_alunos_screen.dart';
import '../features/vinculos/screens/aluno_detalhe_screen.dart';
import '../features/vinculos/screens/alunos_inativos_screen.dart';

import '../features/auth/screens/login_screen.dart';

import '../features/avaliacoes/screens/tela_registrar_medida_aluno.dart';
import '../features/avaliacoes/screens/tela_evolucao_aluno.dart';


class MenuDevScreen extends StatelessWidget {
  const MenuDevScreen({super.key});

  // Telas agrupadas por feature. Telas que recebem parâmetros usam dados
  // fictícios só para abrir.
  static final _grupos = <_GrupoDev>[
    _GrupoDev('Pessoas', [
      _TelaDev('Login', () => const LoginScreen()),
      
      _TelaDev('Cadastro de aluno', () => const CriarCadastroAlunoScreen()),
      _TelaDev('Boas-vindas do aluno', () => TelaBoasVindasAluno( nomeAluno: 'Ana Beatriz', onContinuar: (restricao, observacoes) {}, )),
      _TelaDev('Perfil do aluno', () => const TelaPerfilAluno()),
      _TelaDev('Editar perfil do aluno', () => const EditarPerfilAlunoScreen()),
      _TelaDev('Cadastro de professor', () => const CadastroProfessorScreen()),
      _TelaDev('Perfil do professor', () => const PerfilProfessorScreen()),
      _TelaDev('Editar perfil do professor', () => const EditarPerfilProfessorScreen()),
    ]),
    _GrupoDev('Alunos', [
      
    ]),

    _GrupoDev('Treinos', [
      _TelaDev('Treinos do aluno', () => const TreinosAlunoScreen(nomeAluno: 'Ana Beatriz Ramos')),
      _TelaDev('Histórico de treinos', () => const HistoricoTreinosScreen(nomeAluno: 'Ana Beatriz Ramos')),
      _TelaDev('Registrar medida do aluno', () => const TelaRegistrarMedidaAluno(alturaM: 1.70)),
      _TelaDev('Evolução do aluno', () => const TelaEvolucaoAluno()),
      _TelaDev('Montar treino', () => const MontarTreinoScreen())
    ]),

    _GrupoDev('Vínculos', [
      _TelaDev('Meus alunos', () => const MeusAlunosScreen()),
      _TelaDev('Detalhe do aluno', () => const AlunoDetalheScreen(nome: 'Ana Beatriz Ramos')),
      _TelaDev('Alunos inativos', () => const AlunosInativosScreen()),
    ]),
  ];

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Telas (DEV)')),
      body: ListView(
        children: [
          for (final grupo in _grupos) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                grupo.titulo.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            for (final tela in grupo.telas)
              ListTile(
                title: Text(tela.nome),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => tela.builder()),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _GrupoDev {
  const _GrupoDev(this.titulo, this.telas);

  final String titulo;
  final List<_TelaDev> telas;
}

class _TelaDev {
  const _TelaDev(this.nome, this.builder);

  final String nome;
  final Widget Function() builder;
}