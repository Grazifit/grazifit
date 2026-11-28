import 'package:flutter_test/flutter_test.dart';
import 'package:grazifit_app/core/network/api_exception.dart';
import 'package:grazifit_app/core/network/mensagem_erro.dart';
import 'package:shared/erros/codigo_erro.dart';

void main() {
  const tecnica = 'duplicate key value violates unique constraint';

  test('código conhecido devolve o texto do código', () {
    expect(
      mensagemDoErro(const ApiException(codigo: 'CPF_EM_USO')),
      'CPF já cadastrado.',
    );
    expect(
      mensagemDoErro(const ApiException(codigo: 'TOKEN_INVALIDO')),
      'Sessão expirada. Entre novamente.',
    );
  });

  test('códigos de campo incluem o campo, se houver', () {
    expect(
      mensagemDoErro(
        const ApiException(codigo: 'CAMPO_OBRIGATORIO', campo: 'nome'),
      ),
      contains('nome'),
    );
    expect(
      mensagemDoErro(
        const ApiException(codigo: 'CAMPO_INVALIDO', campo: 'telefone'),
      ),
      contains('telefone'),
    );
    expect(
      mensagemDoErro(const ApiException(codigo: 'CAMPO_INVALIDO')),
      'Confira os dados informados.',
    );
  });

  test('REDE, TIMEOUT e códigos sem texto devolvem a mensagem geral', () {
    for (final codigo in [
      'REDE',
      'TIMEOUT',
      'CONFIGURACAO',
      'RESPOSTA_INVALIDA',
      'ENDPOINT_PENDENTE',
      'CODIGO_QUE_NAO_EXISTE',
      null,
    ]) {
      expect(
        mensagemDoErro(ApiException(codigo: codigo, mensagem: tecnica)),
        mensagemErroGeral,
        reason: '$codigo',
      );
    }
    expect(mensagemDoErro(const ApiException.pendente()), mensagemErroGeral);
  });

  test('todo CodigoErro tem texto próprio, sem a mensagem do servidor', () {
    for (final codigo in CodigoErro.values) {
      final texto = mensagemDoErro(
        ApiException(codigo: codigo.valor, mensagem: tecnica, campo: 'x'),
      );
      expect(texto.trim(), isNotEmpty, reason: codigo.valor);
      expect(texto, isNot(tecnica), reason: codigo.valor);
      expect(texto, isNot(contains(tecnica)), reason: codigo.valor);
    }
  });
}
