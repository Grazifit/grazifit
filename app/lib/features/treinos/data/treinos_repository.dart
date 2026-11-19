import 'treino_detalhe.dart';
import 'treino_resumo.dart';

/// Contrato de acesso aos dados de treinos. As telas só conhecem esta
/// interface, então trocar o mock pela chamada real ao backend não exige mexer
/// nelas. Troque a implementação em `core/data/repositorios.dart`.
abstract class TreinosRepository {
  /// Lista de treinos do aluno: os montados pelo professor e os livres.
  Future<TreinosDoAluno> buscarTreinos();

  /// Busca o treino com seus exercícios.
  Future<TreinoDetalhe> buscarTreino(String id);

  /// Registra que o aluno executou o treino.
  Future<void> confirmarExecucao(String treinoId);
}

/// Implementação de exemplo, com dados fixos, para desenvolver a tela
/// enquanto o backend não fica pronto.
///
/// Quando a integração estiver pronta, este mock pode ser apagado junto com o
/// seu uso em `core/data/repositorios.dart`.
class TreinosRepositoryMock implements TreinosRepository {
  @override
  Future<TreinosDoAluno> buscarTreinos() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const TreinosDoAluno(
      professor: 'Prof. Marina Alves',
      treinosDoProfessor: [
        TreinoResumo(id: '1', nome: 'Inferiores A', objetivo: 'Força'),
        TreinoResumo(id: '2', nome: 'Superiores B', objetivo: 'Hipertrofia'),
      ],
      treinosLivres: [
        TreinoResumo(
          id: '3',
          nome: 'Full body iniciante',
          objetivo: 'Resistência',
        ),
        TreinoResumo(id: '4', nome: 'Cardio leve', objetivo: 'Cardio'),
      ],
    );
  }

  @override
  Future<TreinoDetalhe> buscarTreino(String id) async {
    await Future.delayed(const Duration(milliseconds: 600));

    switch (id) {
      case '1':
        return const TreinoDetalhe(
          id: '1',
          nome: 'Inferiores A',
          objetivo: 'Força',
          professor: 'Prof. Marina Alves',
          exercicios: [
            ExercicioTreino(
              id: '1',
              nome: 'Agachamento livre',
              series: 3,
              repeticoes: 12,
              carga: 40,
              observacao: 'Mantenha a coluna neutra e desça até 90°.',
              descansoSegundos: 90,
            ),
            ExercicioTreino(
              id: '2',
              nome: 'Leg press',
              series: 4,
              repeticoes: 10,
              carga: 80,
              descansoSegundos: 90,
            ),
            ExercicioTreino(
              id: '3',
              nome: 'Cadeira extensora',
              series: 3,
              repeticoes: 15,
              carga: 25,
              descansoSegundos: 60,
            ),
          ],
        );
      case '2':
        return const TreinoDetalhe(
          id: '2',
          nome: 'Superiores B',
          objetivo: 'Hipertrofia',
          professor: 'Prof. Marina Alves',
          exercicios: [
            ExercicioTreino(
              id: '4',
              nome: 'Supino reto',
              series: 4,
              repeticoes: 10,
              carga: 30,
            ),
            ExercicioTreino(
              id: '5',
              nome: 'Remada curvada',
              series: 3,
              repeticoes: 12,
              carga: 25,
            ),
            ExercicioTreino(
              id: '6',
              nome: 'Desenvolvimento com halteres',
              series: 3,
              repeticoes: 12,
              carga: 12.5,
            ),
          ],
        );
      case '3':
        return const TreinoDetalhe(
          id: '3',
          nome: 'Full body iniciante',
          objetivo: 'Resistência',
          professor: 'Treino livre',
          exercicios: [
            ExercicioTreino(
              id: '7',
              nome: 'Agachamento com peso do corpo',
              series: 3,
              repeticoes: 15,
            ),
            ExercicioTreino(
              id: '8',
              nome: 'Flexão de braço',
              series: 3,
              repeticoes: 10,
            ),
            ExercicioTreino(
              id: '9',
              nome: 'Remada com elástico',
              series: 3,
              repeticoes: 12,
            ),
          ],
        );
      case '4':
        return const TreinoDetalhe(
          id: '4',
          nome: 'Cardio leve',
          objetivo: 'Cardio',
          professor: 'Treino livre',
          exercicios: [
            ExercicioTreino(
              id: '10',
              nome: 'Caminhada na esteira',
              series: 1,
              repeticoes: 20,
              observacao: 'Duração em minutos, em ritmo confortável.',
            ),
          ],
        );
      default:
        throw Exception('Treino não encontrado');
    }
  }

  @override
  Future<void> confirmarExecucao(String treinoId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
