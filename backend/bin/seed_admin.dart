import 'dart:io';

import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/auth/auth_repository.dart';
import 'package:grazifit_backend/features/auth/criptografia.dart';
import 'package:grazifit_backend/features/auth/validacoes.dart';
import 'package:grazifit_backend/features/pessoas/admin/admin_repository.dart';

/// Seed do admin (D60): programa one-shot, executado a mao ou como servico
/// separado. NUNCA no boot do backend.
///
/// Uso, a partir de `backend/`, com as variaveis no ambiente:
///   dart run bin/seed_admin.dart
///
/// Variaveis: DATABASE_URL, SENHA_PEPPER (o mesmo do backend, senao a conta
/// nao autentica — D60) e SEED_ADMIN_NOME, SEED_ADMIN_CPF, SEED_ADMIN_EMAIL,
/// SEED_ADMIN_SENHA. Nenhuma credencial vive no repositorio.
///
/// Idempotente: se o e-mail ja existe em qualquer das tres tabelas (D61), sai
/// sem alterar nada.
Future<void> main() async {
  final nome = _obrigatoria('SEED_ADMIN_NOME');
  final cpf = _obrigatoria('SEED_ADMIN_CPF').replaceAll(RegExp(r'[^0-9]'), '');
  final email = _obrigatoria('SEED_ADMIN_EMAIL').toLowerCase();
  final senha = _obrigatoria('SEED_ADMIN_SENHA');
  final pepper = _obrigatoria('SENHA_PEPPER');
  final databaseUrl = _obrigatoria('DATABASE_URL');

  if (!Validacoes.cpfValido(cpf)) _falhar('SEED_ADMIN_CPF invalido.');
  if (!Validacoes.emailValido(email)) _falhar('SEED_ADMIN_EMAIL invalido.');
  if (senha.length < 8) _falhar('SEED_ADMIN_SENHA deve ter ao menos 8 caracteres.');

  final hasher = SenhaHasher(pepperBase64: pepper);
  final db = GraziDatabase.fromUrl(databaseUrl);

  try {
    final existentes = await AuthRepository(db).buscarPorEmail(email);
    if (existentes.isNotEmpty) {
      print('E-mail ja cadastrado; nada a fazer.');
      return;
    }

    final admin = await AdminRepository(db).create(
      cpf: cpf,
      nome: nome,
      email: email,
      senhaHash: hasher.gerarHash(senha),
    );
    print('Admin criado: id ${admin.idAdmin}, e-mail $email.');
  } finally {
    await db.close();
  }
}

String _obrigatoria(String nome) {
  final valor = Platform.environment[nome];
  if (valor == null || valor.trim().isEmpty) {
    _falhar('Variavel obrigatoria nao configurada: $nome');
  }
  return valor.trim();
}

Never _falhar(String mensagem) {
  stderr.writeln(mensagem);
  exit(1);
}
