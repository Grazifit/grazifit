import 'package:grazifit_backend/features/auth/validacoes.dart';
import 'package:shared/erros/codigo_erro.dart';

import '../../../database/database.dart' show ProfessorData;
import '../../../shared/erros/professor_exception.dart';
import '../../auth/criptografia.dart';
import 'professor_repository.dart';

class ProfessorService {
  final ProfessorRepository _repository;
  final SenhaHasher _senhaHasher;

  ProfessorService(this._repository, this._senhaHasher);

  Future<ProfessorData> criar({
    required String cpf,
    required String senha,
    required String nome,
    required String telefone,
    required String email,
    int? idAdminCriador,
  }) async {
    final cpfNormalizado = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    final emailNormalizado = email.trim().toLowerCase();

    if (!Validacoes.cpfValido(cpfNormalizado)) {
      throw const ProfessorValidationException(
        CodigoErro.cpfInvalido,
        campo: 'cpf',
      );
    }

    if (!Validacoes.emailValido(emailNormalizado)) {
      throw const ProfessorValidationException(
        CodigoErro.emailInvalido,
        campo: 'email',
      );
    }

    if (await _repository.cpfEmUso(cpfNormalizado)) {
      throw const ProfessorConflictException(
        CodigoErro.cpfEmUso,
        campo: 'cpf',
      );
    }

    if (await _repository.emailEmUso(emailNormalizado)) {
      throw const ProfessorConflictException(
        CodigoErro.emailEmUso,
        campo: 'email',
      );
    }

    return _repository.create(
      cpf: cpfNormalizado,
      senhaHash: _senhaHasher.gerarHash(senha),
      nome: nome.trim(),
      telefone: telefone.trim(),
      email: emailNormalizado,
      idAdminCriador: idAdminCriador,
    );
  }

  Future<ProfessorData> buscarPorId(int idProfessor) async {
    final professor = await _repository.buscarPorId(idProfessor);
    if (professor == null) {
      throw const ProfessorNotFoundException();
    }
    return professor;
  }

  Future<ProfessorData> atualizar({
    required int idProfessor,
    String? nome,
    String? email,
    String? telefone,
    String? senha,
    bool? status,
  }) async {
    final emailNormalizado = email?.trim().toLowerCase();

    if (emailNormalizado != null) {
      if (!Validacoes.emailValido(emailNormalizado)) {
        throw const ProfessorValidationException(
          CodigoErro.emailInvalido,
          campo: 'email',
        );
      }

      if (await _repository.emailEmUso(
        emailNormalizado,
        ignorarIdProfessor: idProfessor,
      )) {
        throw const ProfessorConflictException(
          CodigoErro.emailEmUso,
          campo: 'email',
        );
      }
    }

    final atualizado = await _repository.atualizar(
      idProfessor: idProfessor,
      nome: nome?.trim(),
      email: emailNormalizado,
      telefone: telefone?.trim(),
      senhaHash: senha != null ? _senhaHasher.gerarHash(senha) : null,
      status: status,
    );

    if (atualizado == null) {
      throw const ProfessorNotFoundException();
    }
    return atualizado;
  }

  Future<void> deletar(int idProfessor) async {
    final removido = await _repository.deletar(idProfessor);
    if (!removido) {
      throw const ProfessorNotFoundException();
    }
  }
}