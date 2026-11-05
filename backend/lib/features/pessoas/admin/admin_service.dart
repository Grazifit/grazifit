import '../../auth/criptografia.dart';

import 'package:grazifit_backend/features/auth/validacoes.dart';

import '../../../database/database.dart';
import '../../../shared/autorizacao/identidade.dart';
import 'admin_repository.dart';

import 'package:grazifit_backend/shared/erros/admin_exceptions.dart'; // ver nota abaixo

class AdminService {
  final AdminRepository _repository;
  final SenhaHasher _senhaHasher;

  AdminService(this._repository, this._senhaHasher);

  Future<AdminData> criar({
    required Identidade identidade,
    required String cpf,
    required String senha,
    required String nome,
    required String email,
    String? telefone,
  }) async {
    exigirAdmin(identidade);
    if (!Validacoes.cpfValido(cpf)) {
      throw ValidationException('CPF inválido.');
    }
    if (!Validacoes.emailValido(email)) {
      throw ValidationException('E-mail inválido.');
    }
    if (senha.length < 8) {
      throw ValidationException('Senha deve ter no mínimo 8 caracteres.');
    }

    final cpfNormalizado = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    final senhaHash = _senhaHasher.gerarHash(senha);

    return _repository.create(
      cpf: cpfNormalizado,
      senhaHash: senhaHash,
      nome: nome.trim(),
      email: email.trim().toLowerCase(),
      telefone: telefone?.trim(),
    );
  }

  Future<AdminData> buscarPorId(Identidade identidade, int idAdmin) async {
    exigirAdmin(identidade);
    final admin = await _repository.buscarPorId(idAdmin);
    if (admin == null) {
      throw NotFoundException('Admin não encontrado.');
    }
    return admin;
  }

  Future<AdminData> atualizar({
    required Identidade identidade,
    required int idAdmin,
    String? nome,
    String? email,
    String? telefone,
    String? senha,
  }) async {
    exigirAdmin(identidade);
    if (email != null && !Validacoes.emailValido(email)) {
      throw ValidationException('E-mail inválido.');
    }
    if (senha != null && senha.length < 8) {
      throw ValidationException('Senha deve ter no mínimo 8 caracteres.');
    }

    final senhaHash = senha != null ? _senhaHasher.gerarHash(senha) : null;

    return _repository.atualizar(
      idAdmin: idAdmin,
      nome: nome?.trim(),
      email: email?.trim().toLowerCase(),
      telefone: telefone?.trim(),
      senhaHash: senhaHash,
    );
  }

  Future<void> deletar(Identidade identidade, int idAdmin) {
    exigirAdmin(identidade);
    return _repository.deletar(idAdmin);
  }
}
