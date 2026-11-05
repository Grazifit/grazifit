import 'package:shared/erros/codigo_erro.dart';

/// Status HTTP de cada codigo do contrato de erro.
/// Fonte: `docs/arquitetura.md` §7.1 e §7.5.
///
/// O `switch` nao tem caso padrao de proposito: codigo novo no enum so
/// compila depois de ganhar um status aqui.
int statusHttp(CodigoErro codigo) => switch (codigo) {
  CodigoErro.jsonInvalido ||
  CodigoErro.campoObrigatorio ||
  CodigoErro.campoInvalido ||
  CodigoErro.cpfInvalido ||
  CodigoErro.emailInvalido ||
  CodigoErro.dataNascimentoInvalida => 400,
  CodigoErro.requisicaoInvalida => 400,
  CodigoErro.credenciaisInvalidas || CodigoErro.tokenInvalido => 401,
  CodigoErro.acessoNegado => 403,
  CodigoErro.registroNaoEncontrado || CodigoErro.professorNaoEncontrado => 404,
  CodigoErro.cpfEmUso ||
  CodigoErro.emailEmUso ||
  CodigoErro.registroEmUso ||
  CodigoErro.agendamentoDuplicado ||
  CodigoErro.horarioConflitante ||
  CodigoErro.vinculoJaAtivo ||
  CodigoErro.avaliacaoJaRegistrada ||
  CodigoErro.aulaSemVagas ||
  CodigoErro.aulaInativa ||
  CodigoErro.aulaCategoriaDivergente ||
  CodigoErro.aulaProfessorDivergente => 409,
  CodigoErro.professorEmUso => 409,
  CodigoErro.muitasTentativas => 429,
  CodigoErro.corpoMuitoGrande => 413,
  CodigoErro.erroInterno => 500,
};
