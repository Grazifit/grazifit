import 'package:postgres/postgres.dart' as pg;
import 'package:shared/erros/codigo_erro.dart';

/// Tradutor **unico** de falha do banco para codigo do contrato — D64.
///
/// `docs/arquitetura.md` secao 7: *"Um tradutor unico no error_handler
/// mapeia a falha do banco para o codigo; nenhuma feature traduz por conta
/// propria."* O contrato desta pasta em `docs/guia-desenvolvimento.md` diz o
/// mesmo pelo avesso, na coluna **Nunca**: *"Ser duplicado dentro de uma
/// feature."*
///
/// Na pratica: **nenhum `*_repository.dart` escreve `catch` sobre
/// `ServerException` para inspecionar `constraintName`.** Se voce sentir
/// vontade de escrever um `if (e.constraintName == ...)` dentro de uma
/// feature, a entrada nova vai em um dos dois mapas abaixo — e o codigo
/// correspondente precisa existir antes em `docs/arquitetura.md` secao 7.1.

/// Erros levantados pelos triggers plpgsql, que ganharam `ERRCODE` proprio
/// (arquitetura secao 7.2). A classe `GF` nao e usada pelo padrao SQL nem
/// pelo PostgreSQL, entao nao ha risco de colisao.
const Map<String, CodigoErro> _porSqlstate = <String, CodigoErro>{
  'GF001': CodigoErro.aulaSemVagas,
  'GF002': CodigoErro.aulaInativa,
  'GF003': CodigoErro.aulaCategoriaDivergente,
  'GF004': CodigoErro.aulaProfessorDivergente,
};

/// Violacao de constraint. A chave e o **nome da constraint**, nao o
/// SQLSTATE: arquitetura secao 7 diz que *"o nome e a chave do mapeamento,
/// e e estavel"*. Cobre `23505` (unicidade) e `23514` — tanto o CHECK de
/// dominio quanto o CHECK de tabela, que compartilham o mesmo espaco de
/// nomes.
const Map<String, CodigoErro> _porConstraint = <String, CodigoErro>{
  'uq_agendamento_aluno_aula': CodigoErro.agendamentoDuplicado,
  'uq_aula_professor_horario': CodigoErro.horarioConflitante,
  'uq_vinculo_aluno_ativo': CodigoErro.vinculoJaAtivo,
  'uq_avaliacao_aluno_data': CodigoErro.avaliacaoJaRegistrada,
  'uq_aluno_cpf': CodigoErro.cpfEmUso,
  'uq_aluno_email': CodigoErro.emailEmUso,
  'dom_cpf_check': CodigoErro.cpfInvalido,
  'dom_email_check': CodigoErro.emailInvalido,
  'ck_aluno_nascimento': CodigoErro.dataNascimentoInvalida,
};

/// O nucleo da traducao, sobre os dois primitivos que o banco entrega.
///
/// Esta funcao existe separada de [traduzirErroBanco] por um motivo
/// pratico: `ServerException` tem **construtor privado** no pacote
/// `postgres`, entao nao ha como forjar uma num teste. Recebendo
/// `sqlstate` e `nomeConstraint` soltos, a tabela de mapeamento fica
/// verificavel sem subir Postgres — e o que sobra em [traduzirErroBanco]
/// e so a extracao dos dois campos, que o teste de integracao cobre.
///
/// Devolve `null` quando o erro **nao esta mapeado**, e isso e deliberado:
/// erro sem codigo e falha do servidor e deve virar 500, com a excecao
/// original preservada para o log. Chutar um codigo generico esconderia
/// bug atras de mensagem amigavel — exatamente o que D64 existe para
/// impedir.
///
/// O SQLSTATE e consultado antes do nome da constraint porque os `GF*` vem
/// de `RAISE` dentro de funcao, sem constraint associada.
CodigoErro? traduzirCodigoBanco({
  required String? sqlstate,
  required String? nomeConstraint,
}) {
  final porSqlstate = _porSqlstate[sqlstate];
  if (porSqlstate != null) {
    return porSqlstate;
  }

  if (nomeConstraint == null) {
    return null;
  }

  return _porConstraint[nomeConstraint];
}

/// Traduz a falha do banco para o codigo do contrato.
///
/// Ponto de entrada para o `error_handler`. Delega a
/// [traduzirCodigoBanco] — ver la o porque da separacao.
CodigoErro? traduzirErroBanco(pg.ServerException e) =>
    traduzirCodigoBanco(sqlstate: e.code, nomeConstraint: e.constraintName);
