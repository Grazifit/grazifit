import 'agenda_repository.dart';
import 'agendamento.dart';
import 'aula.dart';

/// Implementação de exemplo, com dados fixos em memória, para desenvolver as
/// telas sem backend. Agendar e cancelar alteram as listas, então o app se
/// comporta como se houvesse um servidor (enquanto estiver aberto).
///
/// Quando a integração estiver pronta, este arquivo pode ser apagado junto com
/// o seu uso em `core/data/repositorios.dart`.
class AgendaRepositoryMock implements AgendaRepository {
  final List<Aula> _aulas = [
    const Aula(
      id: '1',
      horarioInicio: '07:00',
      horarioFim: '08:00',
      modalidade: 'Funcional',
      tipo: 'Em grupo',
      professor: 'Prof. Marina Alves',
      vagasOcupadas: 8,
      vagasTotais: 12,
    ),
    const Aula(
      id: '2',
      horarioInicio: '09:00',
      horarioFim: '10:00',
      modalidade: 'Funcional',
      tipo: 'Em grupo',
      professor: 'Prof. Marina Alves',
      vagasOcupadas: 11,
      vagasTotais: 12,
    ),
    const Aula(
      id: '3',
      horarioInicio: '18:00',
      horarioFim: '19:00',
      modalidade: 'Funcional',
      tipo: 'Em grupo',
      professor: 'Prof. Marina Alves',
      vagasOcupadas: 12,
      vagasTotais: 12,
    ),
  ];

  final List<Agendamento> _agendamentos = [
    const Agendamento(
      id: 'ag1',
      aulaId: '1',
      horarioInicio: '07:00',
      horarioFim: '08:00',
      modalidade: 'Funcional',
      tipo: 'Em grupo',
      professor: 'Prof. Marina Alves',
      vagasOcupadas: 8,
      vagasTotais: 12,
    ),
    const Agendamento(
      id: 'ag2',
      aulaId: '2',
      horarioInicio: '09:00',
      horarioFim: '10:00',
      modalidade: 'Funcional',
      tipo: 'Em grupo',
      professor: 'Prof. Marina Alves',
      vagasOcupadas: 8,
      vagasTotais: 12,
      aviso: 'Agendamento encerra 2 horas antes da aula',
    ),
  ];

  int _proximoId = 3;

  Future<void> _simularRede() =>
      Future.delayed(const Duration(milliseconds: 400));

  Aula _comVagas(Aula a, int vagasOcupadas) => Aula(
        id: a.id,
        horarioInicio: a.horarioInicio,
        horarioFim: a.horarioFim,
        modalidade: a.modalidade,
        tipo: a.tipo,
        professor: a.professor,
        vagasOcupadas: vagasOcupadas,
        vagasTotais: a.vagasTotais,
        antecedenciaCancelamentoHoras: a.antecedenciaCancelamentoHoras,
      );

  @override
  Future<List<Modalidade>> buscarModalidades() async {
    await _simularRede();
    return const [
      Modalidade(id: '1', nome: 'Funcional'),
      Modalidade(id: '2', nome: 'Musculação'),
      Modalidade(id: '3', nome: 'Pilates'),
    ];
  }

  @override
  Future<List<Aula>> buscarAulas() async {
    await _simularRede();
    return List.of(_aulas);
  }

  @override
  Future<void> agendarAula(String aulaId) async {
    await _simularRede();
    final i = _aulas.indexWhere((a) => a.id == aulaId);
    if (i < 0) throw Exception('Aula não encontrada');
    final aula = _aulas[i];
    if (aula.status == StatusAula.lotada) throw Exception('Aula lotada');

    _aulas[i] = _comVagas(aula, aula.vagasOcupadas + 1);
    _agendamentos.add(
      Agendamento(
        id: 'ag${_proximoId++}',
        aulaId: aula.id,
        horarioInicio: aula.horarioInicio,
        horarioFim: aula.horarioFim,
        modalidade: aula.modalidade,
        tipo: aula.tipo,
        professor: aula.professor,
        vagasOcupadas: aula.vagasOcupadas + 1,
        vagasTotais: aula.vagasTotais,
      ),
    );
  }

  @override
  Future<List<Agendamento>> buscarMeusAgendamentos() async {
    await _simularRede();
    return List.of(_agendamentos);
  }

  @override
  Future<void> cancelarAgendamento(String agendamentoId) async {
    await _simularRede();
    final i = _agendamentos.indexWhere((a) => a.id == agendamentoId);
    if (i < 0) throw Exception('Agendamento não encontrado');
    final agendamento = _agendamentos.removeAt(i);

    final j = _aulas.indexWhere((a) => a.id == agendamento.aulaId);
    if (j >= 0 && _aulas[j].vagasOcupadas > 0) {
      _aulas[j] = _comVagas(_aulas[j], _aulas[j].vagasOcupadas - 1);
    }
  }
}
