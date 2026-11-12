import 'agenda_repository.dart';
import 'aula.dart';

/// Implementação de exemplo, com dados fixos, para desenvolver a tela sem
/// backend. Quando a integração estiver pronta, este arquivo pode ser apagado
/// junto com o seu uso em `_criarRepositorio` (`TelaAgendaAluno`).
class AgendaRepositoryMock implements AgendaRepository {
  @override
  Future<List<Modalidade>> buscarModalidades() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      Modalidade(id: '1', nome: 'Funcional'),
      Modalidade(id: '2', nome: 'Musculação'),
      Modalidade(id: '3', nome: 'Pilates'),
    ];
  }

  @override
  Future<List<Aula>> buscarAulas() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      Aula(
        id: '1',
        horarioInicio: '07:00',
        horarioFim: '08:00',
        modalidade: 'Funcional',
        tipo: 'Em grupo',
        professor: 'Prof. Marina Alves',
        vagasOcupadas: 8,
        vagasTotais: 12,
      ),
      Aula(
        id: '2',
        horarioInicio: '09:00',
        horarioFim: '10:00',
        modalidade: 'Funcional',
        tipo: 'Em grupo',
        professor: 'Prof. Marina Alves',
        vagasOcupadas: 11,
        vagasTotais: 12,
      ),
      Aula(
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
  }
}