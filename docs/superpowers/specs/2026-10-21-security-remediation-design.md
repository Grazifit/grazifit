# Remediacao dos achados de seguranca — design

**Data:** 2026-10-21  
**Revisao avaliada:** `930e2aeb79993f1bc1140b7a3621358eed3555ad`  
**Escopo:** achados 1 a 6 do relatorio de seguranca fornecido pelo usuario

## Objetivo

Fechar as falhas confirmadas de autorizacao horizontal, exclusao destrutiva,
revogacao de sessao e consumo ilimitado de corpo HTTP, alem de remover
credenciais utilizaveis dos artefatos de API. A correcao preserva o RBAC em
Services, usa SQL versionado conforme D58 e nao amplia os DTOs publicos.

## Triagem

Nao existe `SECURITY.md` no repositorio. As fronteiras aplicaveis vem de
`docs/arquitetura.md` e `docs/guia-desenvolvimento.md`: o middleware resolve a
identidade, o Service decide permissao e o backend e a autoridade de acesso.

| # | Veredito | Evidencia principal |
|---:|---|---|
| 1 | confirmado | `AlunoService.atualizar` e `alterarStatus` nao recebem identidade |
| 2 | confirmado | `AlunoService.excluir` executa hard delete sem verificar papel |
| 3 | confirmado no repositorio; estado local nao validado | collections publicam pares previsiveis; consulta ao Docker nao foi autorizada |
| 4 | confirmado | busca e listagem de alunos nao recebem identidade |
| 5 | confirmado | denylist e local ao processo e troca de senha nao participa da validacao |
| 6 | confirmado | controllers acumulam a stream inteira com `readAsString()` |

## Invariantes de seguranca

1. Toda operacao de aluno recebe uma `Identidade` no Service antes de tocar o
   repository.
2. Falta de permissao e decidida antes da consulta de existencia, para que um
   ID valido e um inexistente sejam indistinguiveis para o papel proibido.
3. Um JWT so autoriza quando assinatura, prazo, conta e sessao persistente
   estiverem validos.
4. Logout e troca de senha invalidam sessoes em todas as instancias.
5. Nenhum endpoint acumula mais que o limite de corpo configurado.
6. Collections versionadas nao contem um par previsivel de e-mail e senha.

## Politica de autorizacao de aluno

| Operacao | Admin | Aluno dono | Outro aluno | Professor |
|---|---:|---:|---:|---:|
| `POST /aluno` | permite | nega | nega | nega |
| `GET /aluno` | permite | nega | nega | nega |
| `GET /aluno/<id>` | permite | permite | nega | nega |
| `PATCH /aluno/<id>` | permite | permite | nega | nega |
| `PATCH /aluno/<id>/status` | permite | nega | nega | nega |
| `DELETE /aluno/<id>` | permite | nega | nega | nega |

O controller extrai a identidade ja autenticada e a encaminha. O Service
aplica `exigirAdmin` ou a regra admin-ou-dono. O controller continua limitado
a forma HTTP, DTO e traducao de excecoes. Acesso negado responde `403
ACESSO_NEGADO`, inclusive para ID inexistente quando o chamador nao poderia
acessar nenhum objeto naquele escopo.

## Sessao persistente

### Schema

A migration aprovada `001_adiciona_sessao_auth.sql` cria `sessao_auth`:

- `jti_hash CHAR(64) PRIMARY KEY`: SHA-256 hexadecimal do `jti`, nunca o JWT;
- `papel VARCHAR(10) NOT NULL`, limitado a `admin`, `professor`, `aluno`;
- `id_usuario INT NOT NULL`;
- `criada_em TIMESTAMPTZ NOT NULL DEFAULT now()`;
- `expira_em TIMESTAMPTZ NOT NULL`;
- `revogada_em TIMESTAMPTZ`;
- checks de prazo e coerencia de revogacao;
- indice parcial para sessoes ativas por identidade e indice de expiracao.

Nao ha FK polimorfica para tres tabelas. A existencia e o status da conta
continuam revalidados por `AuthRepository.contaAtiva`.

### Ciclo de vida

`TokenService` continua responsavel pela criptografia do JWT e passa a devolver
metadados validados (`Identidade`, hash do `jti` e expiracao). O repository de
auth registra esses metadados no login. O middleware aceita o token somente se
a sessao correspondente existir, nao estiver revogada e ainda nao tiver
expirado.

`POST /auth/logout` marca a sessao atual como revogada e permanece idempotente
para a chamada autenticada. Tokens emitidos antes da migration nao possuem
registro e deixam de ser aceitos, forcando novo login.

Triggers `AFTER UPDATE OF senha_hash` em `admin`, `professor` e `aluno`
revogam todas as sessoes ativas daquela identidade quando o hash realmente
muda. O controle no banco cobre endpoints atuais, futuros e alteracoes
operacionais diretas. Uma funcao SQL compartilhada recebe o papel como
argumento do trigger.

Sessoes expiradas sao removidas de forma oportunista no login e logout. A
remocao nao faz parte da decisao de autorizacao; falhar a limpeza nao transforma
sessao invalida em valida.

## Limite de corpo HTTP

Um middleware compartilhado limita o corpo a **16 KiB**. Ele fica depois do
middleware de identidade no pipeline: rotas protegidas rejeitam primeiro um
token ausente ou invalido, enquanto login e health seguem as excecoes publicas
existentes.

O middleware:

- rejeita `Content-Length` acima do teto sem consumir o corpo;
- le streams sem tamanho declarado contando bytes;
- interrompe ao primeiro byte excedente;
- responde `413` no envelope JSON, sem chamar controller ou Service;
- recria o `Request` com os bytes limitados para o handler interno.

O login preserva seu teto especifico de 4 KiB. O limite global protege admin,
aluno e professor sem duplicar leitores. Proxy de producao deve aplicar limite
igual ou menor; isso permanece configuracao de implantacao.

## Collections e credencial publicada

As collections Insomnia e Postman substituem e-mail, CPF e senha de criacao por
variaveis sem valor secreto versionado. A senha nao recebe default previsivel.
As descricoes orientam preencher valores locais unicos.

A conta possivelmente ativa no PostgreSQL local nao sera alterada sem acesso
autorizado ao Docker. Portanto, a remediacao do artefato versionado pode ser
concluida, mas a rotacao/inativacao operacional sera registrada como pendencia
se a consulta continuar indisponivel.

## Contratos e compatibilidade

- Nao mudam os payloads publicos de aluno, admin ou professor.
- `403` passa a substituir respostas `200`, `204` ou `404` que hoje vazam para
  papeis sem permissao.
- `POST /auth/logout` continua respondendo `204` para sessao valida.
- JWT valido sem sessao persistida passa a responder `401 TOKEN_INVALIDO`.
- Corpo acima de 16 KiB passa a responder `413`; corpos validos menores mantem
  o comportamento atual.
- `database/schema/grazi_db_init_schema.sql` permanece intocado; a alteracao
  aprovada entra somente como migration D58.

## Testes e evidencias

1. Matriz HTTP e de Service para admin, dono, outro aluno e professor.
2. Mesma resposta `403` para alvo existente e inexistente quando proibido.
3. Login registra sessao; middleware recusa `jti` ausente, revogado ou expirado.
4. Logout continua revogado apos reconstruir Services com o mesmo banco.
5. Troca de senha de admin e professor revoga sessoes anteriores pelo trigger.
6. Corpo no limite passa; um byte acima retorna `413`, com e sem
   `Content-Length`, sem chamar o handler.
7. Collections parseiam e nao contem pares fixos utilizaveis.
8. Migration aplica duas vezes pelo fluxo idempotente do projeto.
9. `dart analyze`, suite completa do backend e fluxo Docker passam.

## Fora de escopo

- Politica de professor consultar alunos vinculados; depende da feature
  `vinculos` e de contrato proprio.
- Refresh token e renovacao silenciosa.
- Configuracao do proxy de producao e topologia externa nao disponivel.
- Exclusao da conta de exemplo local sem autorizacao operacional.

## Implantacao e recuperacao

Aplicar a migration antes de publicar o backend. O primeiro deploy encerra as
sessoes antigas por ausencia de registro persistido. Em caso de rollback do
codigo, a tabela adicional e os triggers sao inertes para o binario anterior;
uma migration aplicada nao e editada nem removida. A recuperacao operacional
mais conservadora e manter o schema aditivo e reimplantar o binario anterior.
