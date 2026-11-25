import '../../../core/network/api_client.dart';
import '../../../core/utils/datas.dart';
import '../../aulas/data/aulas_admin_data.dart';
import '../../pessoas/data/usuarios_admin_data.dart';
import '../../treinos/state/treinos_livres_admin_state.dart';
import 'inicio_admin_data.dart';

abstract class AdminRepository {
  /// Painel inicial: aulas do dia, ocupação, pessoas inativas.
  Future<InicioAdminData> buscarInicio();

  /// Lista de alunos e professores da tela "Pessoas".
  Future<UsuariosAdminData> buscarUsuarios();

  /// Aulas de um dia, para a aba "Aulas".
  Future<List<AulaListaAdminData>> buscarAulas(DateTime dia);

  /// Treinos livres (do sistema), para a aba "Treinos".
  Future<List<TreinoLivreAdminItem>> buscarTreinosLivres();
}

/// Implementação real de [AdminRepository].
///
/// - Início: `GET /inicio` (aulas de hoje, ocupação e pessoas inativas).
/// - Aulas: `GET /aulas?data=AAAA-MM-DD`.
/// - Treinos livres: `GET /treinos/livres`.
/// - Usuários: alunos por `GET /aluno` (primeira página de 100). Professores
///   ficam vazios: não existe `GET /professor` de listagem. O "complemento"
///   (professor do aluno) depende de vínculos e também não vem.
class AdminRepositoryHttp implements AdminRepository {
  const AdminRepositoryHttp(this._api);

  final ApiClient _api;

  @override
  Future<InicioAdminData> buscarInicio() async {
    final json = await _api.get('/inicio');
    final aulas = ((json['aulas'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map((a) {
      final ocupadas = a['vagas_ocupadas'] as int;
      final maximas = a['vagas_maximas'] as int;
      return AulaAdminData(
        horarioInicio: a['hora_inicio'] as String,
        horarioFim: a['hora_fim'] as String,
        modalidade: _rotuloCategoria(a['categoria'] as String),
        formato: _rotuloTipo(a['tipo'] as String),
        professor: a['professor'] as String,
        vagasOcupadas: ocupadas,
        vagasTotais: maximas,
        destaqueVagas: ocupadas >= maximas ? 'Lotada' : null,
      );
    }).toList();

    return InicioAdminData(
      dataLegivel: Datas.porExtenso(json['data'] as String?) ?? '',
      aulasHoje: json['aulas_hoje'] as int,
      ocupacaoPercentual: json['ocupacao_percentual'] as int,
      pessoasInativas: json['pessoas_inativas'] as int,
      aulas: aulas,
    );
  }

  @override
  Future<List<AulaListaAdminData>> buscarAulas(DateTime dia) async {
    final data = '${dia.year.toString().padLeft(4, '0')}-'
        '${dia.month.toString().padLeft(2, '0')}-'
        '${dia.day.toString().padLeft(2, '0')}';
    final json = await _api.get(
      '/aulas',
      query: {'data': data, 'limit': '100', 'offset': '0'},
    );
    final aulas = ((json['itens'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map((a) => AulaListaAdminData(
              id: a['id_aula'] as int,
              horarioInicio: a['hora_inicio'] as String,
              horarioFim: a['hora_fim'] as String,
              modalidade: _rotuloCategoria(a['categoria'] as String),
              formato: _rotuloTipo(a['tipo'] as String),
              vagasOcupadas: a['vagas_ocupadas'] as int,
              vagasTotais: a['vagas_maxima'] as int,
              cancelada: !(a['status'] as bool),
            ))
        .toList();
    aulas.sort((a, b) => a.horarioInicio.compareTo(b.horarioInicio));
    return aulas;
  }

  @override
  Future<List<TreinoLivreAdminItem>> buscarTreinosLivres() async {
    final json = await _api.get(
      '/treinos/livres',
      query: const {'limit': '100', 'offset': '0'},
    );
    return ((json['itens'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map((t) => TreinoLivreAdminItem(
              id: t['id_treino'] as int,
              nome: t['nome'] as String,
              tipo: t['tipo'] as String,
            ))
        .toList();
  }

  static String _rotuloCategoria(String codigo) => switch (codigo) {
        'musculacao' => 'Musculação',
        'funcional' => 'Funcional',
        'pilates' => 'Pilates',
        'crossfit' => 'Crossfit',
        'danca' => 'Dança',
        'spinning' => 'Spinning',
        _ => codigo,
      };

  static String _rotuloTipo(String codigo) => switch (codigo) {
        'coletiva' => 'Coletiva',
        'individual' => 'Individual',
        'experimental' => 'Experimental',
        _ => codigo,
      };

  @override
  Future<UsuariosAdminData> buscarUsuarios() async {
    final json = await _api.get(
      '/aluno',
      query: const {'limit': '100', 'offset': '0'},
    );
    final alunos = ((json['itens'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map((a) {
      final ativo = a['status'] as bool;
      return UsuarioAdminData(
        nome: a['nome'] as String,
        ativo: ativo,
        statusLegivel: ativo ? 'Ativo' : 'Inativo',
        complemento: '',
      );
    }).toList();

    // TODO(backend): GET /professor (listagem) para preencher professores.
    return UsuariosAdminData(alunos: alunos, professores: const []);
  }
}
