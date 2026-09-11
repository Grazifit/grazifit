import 'package:shared/erros/excecao_validacao.dart';
import 'validacoes.dart';

class CadastroService {
  Future<void> cadastrar({
    required String nome,
    required String email,
    required String cpf,
    required String senha,
  }) async {
    if (!Validacoes.emailValido(email)) {
      throw ExcecaoValidacao('Email inválido');
    }

    if (!Validacoes.cpfValido(cpf)) {
      throw ExcecaoValidacao('CPF inválido');
    }

  }
}