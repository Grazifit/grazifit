/// Codigos do envelope de erro `{ codigo, mensagem, campo? }` — D64.
///
/// Sao codigos **para maquina**. A tela escolhe o texto A PARTIR do codigo,
/// jamais pela string de mensagem do Postgres. Por isso nenhum texto de
/// interface mora aqui: e o contrato desta pasta
/// (docs/guia-desenvolvimento.md, tabela de contrato de `shared/lib/erros/`).
///
/// Este arquivo nao importa nada — nem do projeto, nem de pacote externo.
/// Ele e lido pelos dois lados do fio: `backend/lib/shared/erros/`, que
/// traduz a falha do banco para um destes valores, e
/// `app/lib/core/network/`, que escolhe o texto da tela a partir dele.
///
/// **Fonte:** `docs/arquitetura.md` §7.1 (erros do banco), §7.3 (dominio)
/// e §7.5 (erros que nao nascem no banco). Todo codigo aqui e transcricao
/// dessas secoes; codigo novo nasce la primeiro, nunca aqui.
enum CodigoErro {
  // --- Triggers, com ERRCODE proprio (`docs/arquitetura.md` §7.2) ---
  aulaSemVagas('AULA_SEM_VAGAS'),
  aulaInativa('AULA_INATIVA'),
  aulaCategoriaDivergente('AULA_CATEGORIA_DIVERGENTE'),
  aulaProfessorDivergente('AULA_PROFESSOR_DIVERGENTE'),

  // --- Violacao de unicidade (23505) ---
  agendamentoDuplicado('AGENDAMENTO_DUPLICADO'),
  horarioConflitante('HORARIO_CONFLITANTE'),
  vinculoJaAtivo('VINCULO_JA_ATIVO'),
  avaliacaoJaRegistrada('AVALIACAO_JA_REGISTRADA'),
  cpfEmUso('CPF_EM_USO'),
  emailEmUso('EMAIL_EM_USO'),

  cpfInvalido('CPF_INVALIDO'),
  emailInvalido('EMAIL_INVALIDO'),

  dataNascimentoInvalida('DATA_NASCIMENTO_INVALIDA'),

  // --- Registro referenciado por FK RESTRICT (23001) ---
  registroEmUso('REGISTRO_EM_USO'),

  registroNaoEncontrado('REGISTRO_NAO_ENCONTRADO'),

  // --- Fora do banco: forma da requisicao (`docs/arquitetura.md` §7.5) ---
  jsonInvalido('JSON_INVALIDO'),
  campoObrigatorio('CAMPO_OBRIGATORIO'),
  campoInvalido('CAMPO_INVALIDO'),

  // --- Falha nao mapeada: sempre 500 (`docs/arquitetura.md` §7.5) ---
  erroInterno('ERRO_INTERNO');

  const CodigoErro(this.valor);

  final String valor;
}
