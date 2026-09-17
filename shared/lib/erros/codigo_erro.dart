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
/// **Fonte:** docs/arquitetura.md secao 7.1 (a tabela de nove linhas) e
/// secao 7.3 (`CPF_INVALIDO` e `EMAIL_INVALIDO`, que estao fora da tabela).
/// Nenhum codigo aqui foi inventado: todos sao transcricao daquelas duas
/// secoes. Codigo novo nasce la primeiro, nunca aqui.
enum CodigoErro {
  // --- Triggers, com ERRCODE proprio (arquitetura secao 7.2) ---
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

  dataNascimentoInvalida('DATA_NASCIMENTO_INVALIDA');

  const CodigoErro(this.valor);

  final String valor;
}
