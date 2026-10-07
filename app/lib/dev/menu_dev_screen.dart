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


class MenuDevScreen extends StatelessWidget {
  const MenuDevScreen({super.key});

  // Telas agrupadas por feature. Telas que recebem parâmetros usam dados
  // fictícios só para abrir.
  static final _grupos = <_GrupoDev>[
    _GrupoDev('Pessoas', [
      _TelaDev('Cadastro de aluno', () => const CriarCadastroAlunoScreen()),
      _TelaDev(
        'Boas-vindas do aluno',
        () => TelaBoasVindasAluno(
          nomeAluno: 'Ana Beatriz',
          onContinuar: (restricao, observacoes) {},
        ),
      ),
    ]),
    _GrupoDev('Alunos', [
      
    ]),
    // _GrupoDev('Auth', [
    //   _TelaDev('Login', () => const LoginScreen()),
    // ]),
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