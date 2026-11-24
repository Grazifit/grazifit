
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

/// Linha de "Meus alunos" (vínculo ativo do professor logado).
class AlunoVinculado {
  final int idAluno;
  final String nome;

  /// Data da última avaliação (`AAAA-MM-DD`); nulo = sem avaliação.
  final String? ultimaAvaliacao;

  const AlunoVinculado({
    required this.idAluno,
    required this.nome,
    this.ultimaAvaliacao,
  });

  factory AlunoVinculado.fromJson(Map<String, dynamic> json) => AlunoVinculado(
        idAluno: json['id_aluno'] as int,
        nome: json['nome'] as String,
        ultimaAvaliacao: json['ultima_avaliacao'] as String?,
      );
}

/// Aluno vinculado sem acesso recente. A regra dos "30 dias" é do backend.
class AlunoInativo {
  final int idAluno;
  final String nome;

  /// Nulo = nunca acessou (`aluno.data_ultimo_acesso` nulo).
  final int? diasSemAcesso;

  const AlunoInativo({
    required this.idAluno,
    required this.nome,
    this.diasSemAcesso,
  });

  factory AlunoInativo.fromJson(Map<String, dynamic> json) => AlunoInativo(
        idAluno: json['id_aluno'] as int,
        nome: json['nome'] as String,
        diasSemAcesso: (json['dias_sem_acesso'] as num?)?.toInt(),
      );
}

/// Detalhe do aluno na visão do **professor**. Traz dado clínico
/// (`restricao_medica`, `observacao_saude`): precisa de DTO próprio e teste
/// de RBAC (LGPD). Ver docs/integracao-frontend.md, lacuna I-4.
class AlunoDetalhe {
  final int idAluno;
  final String nome;
  final String? restricaoMedica;
  final String? observacaoSaude;
  final String? vinculoDesde;
  final int totalTreinos;
  final int execucoes30Dias;
  final String? ultimaAvaliacao;

  /// Vem do banco (`avaliacao.imc`); o app não calcula.
  final double? imc;

  /// Peso (kg) e altura (m) da última avaliação, para pré-preencher a
  /// avaliação do dia.
  final double? ultimoPeso;
  final double? ultimaAltura;

  const AlunoDetalhe({
    required this.idAluno,
    required this.nome,
    this.restricaoMedica,
    this.observacaoSaude,
    this.vinculoDesde,
    this.totalTreinos = 0,
    this.execucoes30Dias = 0,
    this.ultimaAvaliacao,
    this.imc,
    this.ultimoPeso,
    this.ultimaAltura,
  });

  factory AlunoDetalhe.fromJson(Map<String, dynamic> json) => AlunoDetalhe(
        idAluno: json['id_aluno'] as int,
        nome: json['nome'] as String,
        restricaoMedica: json['restricao_medica'] as String?,
        observacaoSaude: json['observacao_saude'] as String?,
        vinculoDesde: json['vinculo_desde'] as String?,
        totalTreinos: (json['total_treinos'] as num?)?.toInt() ?? 0,
        execucoes30Dias: (json['execucoes_30_dias'] as num?)?.toInt() ?? 0,
        ultimaAvaliacao: json['ultima_avaliacao'] as String?,
        imc: json['imc'] == null ? null : double.parse(json['imc'].toString()),
        ultimoPeso: json['ultimo_peso'] == null
            ? null
            : double.parse(json['ultimo_peso'].toString()),
        ultimaAltura: json['ultima_altura'] == null
            ? null
            : double.parse(json['ultima_altura'].toString()),
      );
}

abstract class VinculosRepository {
  Future<List<AlunoVinculado>> listarAtivos();
  Future<List<AlunoInativo>> listarInativos();
  Future<AlunoDetalhe> detalhe(int idAluno);
}

/// **Não existe backend de `vinculos` ainda** (só README). O único endpoint
/// de aluno é `GET /aluno` do admin, que não filtra por professor.
/// Ver docs/integracao-frontend.md (Vínculos).
class VinculosRepositoryHttp implements VinculosRepository {
  // ignore: unused_field
  final ApiClient _api;

  const VinculosRepositoryHttp(this._api);

  @override
  Future<List<AlunoVinculado>> listarAtivos() async {
    // TODO(backend): vinculo_professor_aluno (status ativo) + última avaliação.
    throw const ApiException.pendente();
  }

  @override
  Future<List<AlunoInativo>> listarInativos() async {
    // TODO(backend): vinculados sem acesso (aluno.data_ultimo_acesso).
    throw const ApiException.pendente();
  }

  @override
  Future<AlunoDetalhe> detalhe(int idAluno) async {
    // TODO(backend): DTO do aluno na visão do professor (L4).
    throw const ApiException.pendente();
  }
}
