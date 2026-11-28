import 'package:shared/erros/codigo_erro.dart';

import '../../database/database.dart' show ExercicioData;
import '../../shared/autorizacao/identidade.dart';
import '../../shared/erros/exercicio_exception.dart';
import 'exercicio_repository.dart';

class ExercicioService {
  final ExercicioRepository _repository;

  ExercicioService(this._repository);

  /// Espelha `ck_exercicio_dificuldade`.
  static const List<String> dificuldades = [
    'iniciante',
    'intermediario',
    'avancado',
  ];

  Future<ExercicioData> criar({
    required Identidade identidade,
    required String nome,
    required String instrucoes,
    String? descricao,
    String dificuldade = 'iniciante',
  }) async {
    exigirAdmin(identidade);

    _exigirDificuldadeValida(dificuldade);

    final nomeLimpo = nome.trim();
    if (nomeLimpo.isEmpty) {
      throw const ExercicioValidationException(
        CodigoErro.campoInvalido,
        campo: 'nome',
      );
    }

    final instrucoesLimpas = instrucoes.trim();
    if (instrucoesLimpas.isEmpty) {
      throw const ExercicioValidationException(
        CodigoErro.campoInvalido,
        campo: 'instrucoes',
      );
    }

    if (await _repository.nomeEmUso(nomeLimpo)) {
      throw const ExercicioConflictException(
        CodigoErro.nomeEmUso,
        campo: 'nome',
      );
    }

    return _repository.create(
      idAdminCriador: identidade.id,
      nome: nomeLimpo,
      instrucoes: instrucoesLimpas,
      descricao: _textoOuNulo(descricao),
      dificuldade: dificuldade,
    );
  }

  /// Leitura de catalogo: qualquer perfil autenticado, sem checagem de dono.
  Future<ExercicioData> buscarExercicioPorId(
    int idExercicio, {
    required Identidade identidade,
  }) async {
    _exigirIdPossivel(idExercicio);

    final exercicio = await _repository.buscarExercicioPorId(idExercicio);
    if (exercicio == null) {
      throw const ExercicioNotFoundException();
    }
    return exercicio;
  }

  /// `limit` e `offset` chegam ja validados pelo controller.
  Future<({List<ExercicioData> itens, int total})> buscarExercicios({
    required Identidade identidade,
    required int limit,
    required int offset,
  }) async {
    final itens = await _repository.buscarExercicios(
      limit: limit,
      offset: offset,
    );
    final total = await _repository.countExercicios();
    return (itens: itens, total: total);
  }

  /// Campo nulo fica como esta. A existencia vem primeiro, para que id
  /// inexistente seja sempre 404.
  Future<ExercicioData> atualizar(
    int idExercicio, {
    required Identidade identidade,
    String? nome,
    String? instrucoes,
    String? descricao,
    String? dificuldade,
  }) async {
    exigirAdmin(identidade);
    _exigirIdPossivel(idExercicio);
    if (await _repository.buscarExercicioPorId(idExercicio) == null) {
      throw const ExercicioNotFoundException();
    }

    if (dificuldade != null) {
      _exigirDificuldadeValida(dificuldade);
    }

    final nomeLimpo = nome?.trim();
    if (nomeLimpo != null) {
      if (nomeLimpo.isEmpty) {
        throw const ExercicioValidationException(
          CodigoErro.campoInvalido,
          campo: 'nome',
        );
      }

      if (await _repository.nomeEmUso(
        nomeLimpo,
        excetoIdExercicio: idExercicio,
      )) {
        throw const ExercicioConflictException(
          CodigoErro.nomeEmUso,
          campo: 'nome',
        );
      }
    }

    final instrucoesLimpas = instrucoes?.trim();
    if (instrucoesLimpas != null && instrucoesLimpas.isEmpty) {
      throw const ExercicioValidationException(
        CodigoErro.campoInvalido,
        campo: 'instrucoes',
      );
    }

    final exercicio = await _repository.atualizar(
      idExercicio,
      nome: nomeLimpo,
      instrucoes: instrucoesLimpas,
      descricao: _textoOuNulo(descricao),
      dificuldade: dificuldade,
    );
    if (exercicio == null) {
      throw const ExercicioNotFoundException();
    }
    return exercicio;
  }

  /// Exclusao real. Exercicio usado em treino: o banco recusa e o controller
  /// responde `REGISTRO_EM_USO`.
  Future<void> excluir(
    int idExercicio, {
    required Identidade identidade,
  }) async {
    exigirAdmin(identidade);
    _exigirIdPossivel(idExercicio);
    if (await _repository.buscarExercicioPorId(idExercicio) == null) {
      throw const ExercicioNotFoundException();
    }
    if (!await _repository.excluir(idExercicio)) {
      throw const ExercicioNotFoundException();
    }
  }

  static void _exigirDificuldadeValida(String dificuldade) {
    if (!dificuldades.contains(dificuldade)) {
      throw const ExercicioValidationException(
        CodigoErro.campoInvalido,
        campo: 'dificuldade',
      );
    }
  }

  /// Descricao em branco e ausencia, nao string vazia.
  String? _textoOuNulo(String? valor) {
    final limpo = valor?.trim();
    return (limpo == null || limpo.isEmpty) ? null : limpo;
  }

  /// Id que nunca existe: nao precisa ir ao banco.
  static void _exigirIdPossivel(int idExercicio) {
    if (idExercicio <= 0) {
      throw const ExercicioNotFoundException();
    }
  }
}
