enum TipoAulaAvulsaAdmin {
  emGrupo('coletiva', 'Em grupo'),
  personal('individual', 'Personal (até 3)');

  const TipoAulaAvulsaAdmin(this.codigo, this.rotulo);

  final String codigo;
  final String rotulo;
}

class ProfessorAulaAvulsaOpcao {
  const ProfessorAulaAvulsaOpcao({required this.id, required this.nome});

  final int id;
  final String nome;
}

/// Formato de entrada da tela, pronto para ser encaminhado à camada de estado.
/// A tela não persiste nem envia esses dados.
/// A referência não coleta categoria, embora o schema exija esse campo;
/// a origem precisa ser definida antes de ligar este callback ao backend.
class NovaAulaAvulsaAdmin {
  const NovaAulaAvulsaAdmin({
    required this.data,
    required this.horaInicio,
    required this.horaFim,
    required this.professorId,
    required this.tipo,
    required this.vagasMaxima,
  });

  final DateTime data;
  final String horaInicio;
  final String horaFim;
  final int professorId;
  final TipoAulaAvulsaAdmin tipo;
  final int vagasMaxima;
}
