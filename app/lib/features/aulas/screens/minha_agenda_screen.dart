// app/lib/features/aulas/screens/minha_agenda_screen.dart
//
// Minha agenda (professor): aulas do dia, com selo de "Últimas vagas" e
// "Cancelada". Tocar em uma aula abre o Detalhe da aula. Dados de
// `agendaProfessorProvider` (depende do backend de aulas).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/components/barra_navegacao.dart';
import '../../../core/design_system/components/botao_sair.dart';
import '../../../core/design_system/components/texto_apoio.dart';
import '../../../core/state/estado_async.dart';
import '../../../core/utils/datas.dart';
import '../data/aulas_professor_repository.dart';
import '../state/aulas_providers.dart';
import '../widgets/cartao_aula.dart';
import 'detalhe_aula_screen.dart';

class MinhaAgendaScreen extends ConsumerWidget {
  const MinhaAgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agenda = ref.watch(agendaProfessorProvider);

    return Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 4, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Minha agenda',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const BotaoSair(),
                  ],
                ),
              ),
              if (agenda.hasValue)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: TextoApoio(
                    Datas.porExtenso(agenda.value!.data) ?? agenda.value!.data,
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: EstadoAsync<AgendaProfessor>(
                  valor: agenda,
                  aoTentarNovamente: () =>
                      ref.invalidate(agendaProfessorProvider),
                  vazio: (a) => a.aulas.isEmpty,
                  textoVazio: 'Nenhuma aula hoje.',
                  dados: (a) => ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      for (final aula in a.aulas) ...[
                        CartaoAula(
                          horario: aula.horario,
                          modalidade: aula.modalidade,
                          professor: aula.professor,
                          vagasOcupadas: aula.vagasOcupadas,
                          vagasTotais: aula.vagasTotais,
                          status: aula.status,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DetalheAulaScreen(idAula: aula.idAula))),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const BarraNavegacao(indiceAtual: 0),
      );
  }
}
