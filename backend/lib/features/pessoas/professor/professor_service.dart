import 'package:shared/erros/codigo_erro.dart';

import '../../../database/database.dart' show ProfessorData;
import '../../auth/criptografia.dart';
import '../../auth/validacoes.dart';
import 'professor_exception.dart';
import 'professor_repository.dart';

class ProfessorService {
  final ProfessorRepository _repository;

  final String Function(String senha) hash;

  ProfessorService(this._repository, {this.hash = hashPassword});

  Future<ProfessorData> criar({
    required String cpf,
    required String senha,
    required String nome,
    required String telefone,
    required String email,
    int? idAdminCriador,
    int? idEndereco,
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
      senhaHash: hash(senha),
      nome: nome.trim(),
      telefone: telefone.trim(),
      email: emailNormalizado,
      idAdminCriador: idAdminCriador,
      idEndereco: idEndereco,
    );
  }
}