import 'avaliacoes_repository.dart';
import 'evolucao_aluno.dart';

/// Implementação de exemplo, com dados fixos em memória, para desenvolver as
/// telas sem backend. Registrar uma medida altera a lista, e uma nova medida no
/// mesmo mês substitui a anterior.
///
/// Quando a integração estiver pronta, este arquivo pode ser apagado junto com
/// o seu uso em `core/data/repositorios.dart`.
class AvaliacoesRepositoryMock implements AvaliacoesRepository {
  static const double _alturaM = 1.68;

  final List<MedidaPeso> _medidas = [
    MedidaPeso(data: DateTime(2026, 3, 15), peso: 70.0),
    MedidaPeso(data: DateTime(2026, 4, 15), peso: 71.0),
    MedidaPeso(data: DateTime(2026, 5, 15), peso: 70.6),
    MedidaPeso(data: DateTime(2026, 6, 15), peso: 72.0),
    MedidaPeso(data: DateTime(2026, 7, 15), peso: 72.5),
  ];

  @override
  Future<EvolucaoAluno> buscarEvolucao() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return EvolucaoAluno(alturaM: _alturaM, medidas: List.of(_medidas));
  }

  @override
  Future<void> registrarMedida(double peso) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final agora = DateTime.now();
    final i = _medidas.indexWhere(
      (m) => m.data.year == agora.year && m.data.month == agora.month,
    );
    final nova = MedidaPeso(data: agora, peso: peso);
    if (i >= 0) {
      _medidas[i] = nova;
    } else {
      _medidas.add(nova);
    }
    _medidas.sort((a, b) => a.data.compareTo(b.data));
  }
}
