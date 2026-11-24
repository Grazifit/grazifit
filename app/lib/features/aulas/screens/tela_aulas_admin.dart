import 'package:flutter/material.dart';

import '../../../core/utils/datas.dart';
import '../data/aulas_admin_data.dart';

enum EstadoAulasAdmin { carregando, erro, semConexao, dados }

/// Aba "Aulas" do Admin: aulas de um dia, com navegação entre dias.
/// Dados e callbacks vêm de `PaginaAulasAdmin`.
class TelaAulasAdmin extends StatelessWidget {
  const TelaAulasAdmin({
    super.key,
    required this.dia,
    required this.estado,
    this.aulas = const [],
    this.onMudarDia,
    this.onTentarNovamente,
  });

  final DateTime dia;
  final EstadoAulasAdmin estado;
  final List<AulaListaAdminData> aulas;
  final ValueChanged<int>? onMudarDia;
  final VoidCallback? onTentarNovamente;

  static const _verde = Color(0xFF005B50);
  static const _texto = Color(0xFF33413F);
  static const _cinza = Color(0xFF78827F);

  String get _rotuloDia {
    final iso = '${dia.year.toString().padLeft(4, '0')}-'
        '${dia.month.toString().padLeft(2, '0')}-'
        '${dia.day.toString().padLeft(2, '0')}';
    return Datas.porExtenso(iso) ?? iso;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const Text(
              'Aulas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF26312F),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  tooltip: 'Dia anterior',
                  onPressed: onMudarDia == null ? null : () => onMudarDia!(-1),
                  icon: const Icon(Icons.chevron_left, color: _verde),
                ),
                Expanded(
                  child: Text(
                    _rotuloDia,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _texto,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Próximo dia',
                  onPressed: onMudarDia == null ? null : () => onMudarDia!(1),
                  icon: const Icon(Icons.chevron_right, color: _verde),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _conteudo(),
          ],
        ),
      ),
    );
  }

  Widget _conteudo() {
    switch (estado) {
      case EstadoAulasAdmin.carregando:
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator(color: _verde)),
        );
      case EstadoAulasAdmin.erro:
      case EstadoAulasAdmin.semConexao:
        final offline = estado == EstadoAulasAdmin.semConexao;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                offline ? Icons.cloud_off : Icons.error_outline,
                color: _verde,
                size: 38,
              ),
              const SizedBox(height: 14),
              Text(
                offline
                    ? 'Sem conexão. Confira sua internet e tente novamente.'
                    : 'Não foi possível carregar as aulas.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _texto, fontSize: 14),
              ),
              if (onTentarNovamente != null) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: onTentarNovamente,
                  style: OutlinedButton.styleFrom(foregroundColor: _verde),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ],
          ),
        );
      case EstadoAulasAdmin.dados:
        if (aulas.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFFBECBC8)),
            ),
            child: const Text(
              'Não há aulas programadas para este dia.',
              style: TextStyle(color: _cinza, fontSize: 13),
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < aulas.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _CartaoAula(aula: aulas[i]),
            ],
          ],
        );
    }
  }
}

class _CartaoAula extends StatelessWidget {
  const _CartaoAula({required this.aula});

  final AulaListaAdminData aula;

  @override
  Widget build(BuildContext context) {
    final riscado = aula.cancelada;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFBECBC8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${aula.horarioInicio} – ${aula.horarioFim}',
                  style: TextStyle(
                    color: TelaAulasAdmin._texto,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    decoration: riscado ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (aula.cancelada)
                const Text(
                  'Cancelada',
                  style: TextStyle(
                    color: Color(0xFF9A5B00),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                aula.modalidade,
                style: const TextStyle(color: TelaAulasAdmin._texto, fontSize: 13),
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
                  style: const TextStyle(color: TelaAulasAdmin._texto, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            aula.resumoVagas,
            style: const TextStyle(
              color: TelaAulasAdmin._texto,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
