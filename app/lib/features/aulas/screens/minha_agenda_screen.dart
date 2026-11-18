// app/lib/features/aulas/screens/minha_agenda_screen.dart
//
// PROTÓTIPO VISUAL — sem integração com backend. Dados fictícios do mockup.
// Integração com o backend: ver docs/handoff-front-professor.md
//
// Minha agenda (professor): aulas do dia, com selo de "Últimas vagas" e
// "Cancelada". Tocar em uma aula abre o Detalhe da aula.

import 'package:flutter/material.dart';

import '../../../core/design_system/components/barra_navegacao.dart';
import '../../../core/design_system/components/fundo_tela.dart';
import '../../../core/design_system/components/texto_apoio.dart';
import '../../../core/design_system/tokens/cores_provisorias.dart';
import '../widgets/cartao_aula.dart';
import 'detalhe_aula_screen.dart';

class MinhaAgendaScreen extends StatelessWidget {
  const MinhaAgendaScreen({super.key});

  // TODO(backend): aulas do dia do professor logado (feature aulas) e a data
  // de hoje formatada no app. Estados: carregando, vazio, erro, sem conexão.
  static const _data = 'Segunda, 01 de setembro';

  static const _aulas = <_AulaAgenda>[
    _AulaAgenda(
      horario: '07:00 - 08:00',
      vagasOcupadas: 8,
      vagasTotais: 12,
      status: StatusAula.normal,
    ),
    _AulaAgenda(
      horario: '09:00 - 10:00',
      vagasOcupadas: 11,
      vagasTotais: 12,
      status: StatusAula.ultimasVagas,
    ),
    _AulaAgenda(
      horario: '18:00 - 19:00',
      vagasOcupadas: 8,
      vagasTotais: 12,
      status: StatusAula.cancelada,
    ),
  ];

  void _abrirDetalhe(BuildContext context, _AulaAgenda aula) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalheAulaScreen(
          horario: aula.horario,
          vagasOcupadas: aula.vagasOcupadas,
          vagasTotais: aula.vagasTotais,
          cancelada: aula.status == StatusAula.cancelada,
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
              // TODO(specs): trocar pelo logotipo real quando o asset estiver
              // declarado no pubspec.yaml.
              const Center(
                child: Icon(
                  Icons.local_florist_outlined,
                  size: 28,
                  color: corInstitucional,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Minha agenda',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              const TextoApoio(_data),
              const SizedBox(height: 16),
              for (final aula in _aulas) ...[
                CartaoAula(
                  horario: aula.horario,
                  modalidade: 'Funcional',
                  professor: 'Prof. Marina Alves',
                  vagasOcupadas: aula.vagasOcupadas,
                  vagasTotais: aula.vagasTotais,
                  status: aula.status,
                  onTap: () => _abrirDetalhe(context, aula),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        // TODO: a barra ainda não navega (depende do desenho de rotas).
        bottomNavigationBar: const BarraNavegacao(indiceAtual: 0),
      ),
    );
  }
}

class _AulaAgenda {
  const _AulaAgenda({
    required this.horario,
    required this.vagasOcupadas,
    required this.vagasTotais,
    required this.status,
  });

  final String horario;
  final int vagasOcupadas;
  final int vagasTotais;
  final StatusAula status;
}