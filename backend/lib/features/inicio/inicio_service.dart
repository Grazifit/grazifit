import '../../shared/autorizacao/identidade.dart';
import 'inicio_repository.dart';

/// Painel inicial montado a partir das leituras do repository.
class PainelInicio {
  const PainelInicio({
    required this.data,
    required this.aulas,
    required this.ocupacaoPercentual,
    required this.pessoasInativas,
  });

  /// `AAAA-MM-DD`.
  final String data;
  final List<AulaDoDia> aulas;
  final int ocupacaoPercentual;
  final int pessoasInativas;
}

class InicioService {
  InicioService(this._repository);

  final InicioRepository _repository;

  /// So o admin ve o painel.
  Future<PainelInicio> painel(Identidade identidade) async {
    exigirAdmin(identidade);

    final data = await _repository.dataDeHoje();
    final aulas = await _repository.aulasDeHoje();
    final inativas = await _repository.contarPessoasInativas();

    return PainelInicio(
      data: data,
      aulas: aulas,
      ocupacaoPercentual: calcularOcupacao(aulas),
      pessoasInativas: inativas,
    );
  }

  /// Vagas ocupadas / vagas totais, em percentual inteiro arredondado.
  /// Sem aulas, 0.
  static int calcularOcupacao(List<AulaDoDia> aulas) {
    final totais = aulas.fold<int>(0, (s, a) => s + a.vagasMaximas);
    if (totais == 0) return 0;
    final ocupadas = aulas.fold<int>(0, (s, a) => s + a.vagasOcupadas);
    return (ocupadas * 100 / totais).round();
  }
}
