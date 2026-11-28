import 'package:shared/erros/codigo_erro.dart';

import 'api_exception.dart';

/// Texto usado quando não há mensagem própria para o código.
const mensagemErroGeral = 'Não foi possível concluir. Tente novamente.';

/// Texto de tela escolhido pelo `codigo` de [erro]. Nunca devolve o
/// `mensagem` do servidor. Códigos fora de [CodigoErro] (REDE, TIMEOUT,
/// CONFIGURACAO, RESPOSTA_INVALIDA, ENDPOINT_PENDENTE) caem na mensagem geral.
String mensagemDoErro(ApiException erro) {
  final campo = erro.campo;
  final temCampo = campo != null && campo.trim().isNotEmpty;
  return switch (erro.codigoErro) {
    null => mensagemErroGeral,
    CodigoErro.aulaSemVagas => 'Esta aula não tem mais vagas.',
    CodigoErro.aulaInativa => 'Esta aula foi cancelada.',
    CodigoErro.aulaCategoriaDivergente => 'A categoria não confere com a aula.',
    CodigoErro.aulaProfessorDivergente => 'O professor não confere com a aula.',
    CodigoErro.aulaDataPassada => 'Esta aula já passou.',
    CodigoErro.agendamentoForaDaJanela =>
      'Fora do prazo permitido para agendar ou cancelar.',
    CodigoErro.agendamentoDuplicado => 'Você já está agendado nesta aula.',
    CodigoErro.horarioConflitante => 'Já existe uma aula nesse horário.',
    CodigoErro.vinculoJaAtivo => 'Este vínculo já está ativo.',
    CodigoErro.avaliacaoJaRegistrada => 'Avaliação já registrada.',
    CodigoErro.cpfEmUso => 'CPF já cadastrado.',
    CodigoErro.emailEmUso => 'E-mail já cadastrado.',
    CodigoErro.nomeEmUso => 'Já existe um registro com este nome.',
    CodigoErro.cpfInvalido => 'CPF inválido.',
    CodigoErro.emailInvalido => 'E-mail inválido.',
    CodigoErro.dataNascimentoInvalida => 'Data de nascimento inválida.',
    CodigoErro.registroEmUso =>
      'Este registro está em uso e não pode ser removido.',
    CodigoErro.registroNaoEncontrado => 'Registro não encontrado.',
    CodigoErro.jsonInvalido => mensagemErroGeral,
    CodigoErro.campoObrigatorio =>
      temCampo
          ? 'Preencha o campo obrigatório: $campo.'
          : 'Preencha os campos obrigatórios.',
    CodigoErro.campoInvalido =>
      temCampo ? 'Confira o campo: $campo.' : 'Confira os dados informados.',
    CodigoErro.professorEmUso =>
      'Este professor tem vínculos e não pode ser removido.',
    CodigoErro.professorNaoEncontrado => 'Professor não encontrado.',
    CodigoErro.requisicaoInvalida => 'Confira os dados informados.',
    CodigoErro.credenciaisInvalidas => 'E-mail ou senha incorretos.',
    CodigoErro.muitasTentativas =>
      'Muitas tentativas. Aguarde um pouco e tente novamente.',
    CodigoErro.corpoMuitoGrande => 'Os dados enviados são grandes demais.',
    CodigoErro.tokenInvalido => 'Sessão expirada. Entre novamente.',
    CodigoErro.acessoNegado => 'Você não tem permissão para esta ação.',
    CodigoErro.erroInterno => mensagemErroGeral,
  };
}
