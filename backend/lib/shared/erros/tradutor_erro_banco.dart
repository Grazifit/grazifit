import 'package:postgres/postgres.dart' as pg;
import 'package:shared/erros/codigo_erro.dart';

/// Tradutor **unico** de falha do banco para codigo do contrato.
/// Fonte: `docs/arquitetura.md` §7 (D64).
///
/// Nenhuma feature traduz por conta propria: constraint nova entra num dos
/// mapas abaixo, e o codigo precisa existir antes em `docs/arquitetura.md`
/// §7.1.

/// Triggers plpgsql com `ERRCODE` proprio (`docs/arquitetura.md` §7.2).
const Map<String, CodigoErro> _porSqlstate = <String, CodigoErro>{
  'GF001': CodigoErro.aulaSemVagas,
  'GF002': CodigoErro.aulaInativa,
  'GF003': CodigoErro.aulaCategoriaDivergente,
  'GF004': CodigoErro.aulaProfessorDivergente,
};

/// Unicidade (`23505`) e CHECK (`23514`), pelo nome da constraint.
const Map<String, CodigoErro> _porConstraint = <String, CodigoErro>{
  'uq_agendamento_aluno_aula': CodigoErro.agendamentoDuplicado,
  'uq_aula_professor_horario': CodigoErro.horarioConflitante,
  'uq_vinculo_aluno_ativo': CodigoErro.vinculoJaAtivo,
  'uq_avaliacao_aluno_data': CodigoErro.avaliacaoJaRegistrada,
  'uq_aluno_cpf': CodigoErro.cpfEmUso,
  'uq_aluno_email': CodigoErro.emailEmUso,

  // --- Professor ---
  'uq_professor_cpf': CodigoErro.cpfEmUso,
  'uq_professor_email': CodigoErro.emailEmUso,
  'dom_cpf_check': CodigoErro.cpfInvalido,
  'dom_email_check': CodigoErro.emailInvalido,
  'ck_aluno_nascimento': CodigoErro.dataNascimentoInvalida,
};

/// FKs `ON DELETE RESTRICT` que apontam para `aluno` e `professor` — so com
/// `23001`.
///
/// A mesma FK tambem falha com `23503` num INSERT que referencia registro
/// inexistente; isso nao e "registro em uso" e fica sem codigo.
const Map<String, CodigoErro> _porRestricao = <String, CodigoErro>{
  'fk_avaliacao_aluno': CodigoErro.registroEmUso,
  'fk_vinculo_aluno': CodigoErro.registroEmUso,
  'fk_agendamento_aluno': CodigoErro.registroEmUso,
  'fk_historico_aluno': CodigoErro.registroEmUso,
  'fk_vinculo_professor': CodigoErro.registroEmUso,
  'fk_cronograma_professor': CodigoErro.registroEmUso,
  'fk_aula_professor': CodigoErro.registroEmUso,
  'fk_treino_professor': CodigoErro.registroEmUso,
};

/// Traduz a partir dos dois campos crus do erro.
///
/// Existe separada de [traduzirErroBanco] porque `ServerException` nao pode
/// ser construida em teste. Devolve `null` quando nao ha mapeamento: o erro
/// vira 500, com a excecao original no log.
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

  if (sqlstate == '23001') {
    return _porRestricao[nomeConstraint];
  }

  return _porConstraint[nomeConstraint];
}

/// Ponto de entrada para quem trata `ServerException`.
CodigoErro? traduzirErroBanco(pg.ServerException e) =>
    traduzirCodigoBanco(sqlstate: e.code, nomeConstraint: e.constraintName);
