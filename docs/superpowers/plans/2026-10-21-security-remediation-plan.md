# Security Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Corrigir os seis achados do relatorio por meio de RBAC por objeto, sessoes persistentes, limite de corpo HTTP e collections sem credenciais previsiveis.

**Architecture:** O middleware continua autenticando e os Services passam a aplicar toda autorizacao de aluno. JWT permanece assinado por `TokenService`, mas cada `jti` passa a ter uma sessao persistente consultada pelo middleware; SQL versionado revoga sessoes em troca de senha. Um middleware unico limita e rebobina corpos HTTP antes dos controllers.

**Tech Stack:** Dart 3.13, Shelf, Drift com PostgreSQL 18, SQL D58, package:test, Docker Compose, collections Insomnia/Postman.

**Spec:** `docs/superpowers/specs/2026-10-21-security-remediation-design.md`

## Global Constraints

- Autorizacao pertence ao Service; controller somente encaminha identidade, valida forma e traduz erros.
- `database/schema/grazi_db_init_schema.sql` permanece intocado; schema novo entra em migration aprovada.
- Tokens, hashes, peppers e senhas nunca aparecem em logs, testes ou artefatos versionados.
- Nao remover nem sobrescrever alteracoes preexistentes do usuario.
- Nao criar commit enquanto o merge atual estiver pendente; os passos de commit ficam substituidos por revisao de diff e relato dos arquivos.
- Toda mudanca de comportamento segue RED, GREEN e refatoracao com a suite novamente verde.

## Review Focus

- Papel proibido usando ID inexistente deve receber `403`, nao `404`, para nao enumerar objetos.
- Aluno dono deve manter GET/PATCH proprio, mas nunca status, DELETE ou listagem.
- JWT assinado sem linha correspondente em `sessao_auth` deve receber `401` apos o deploy.
- Stream sem `Content-Length` deve parar no primeiro byte acima de 16 KiB e nao chamar o handler.
- Falha de limpeza de sessoes expiradas nao pode fazer login ou autorizacao falhar depois que a sessao atual foi persistida.

---

### Task 1: Fechar autorizacao horizontal e destrutiva de aluno

**Files:**
- Modify: `backend/lib/features/pessoas/aluno/aluno_controller.dart`
- Modify: `backend/lib/features/pessoas/aluno/aluno_service.dart`
- Modify: `backend/test/aluno_controller_test.dart`
- Modify: `backend/test/aluno_service_test.dart`

**Interfaces:**
- Consumes: `Identidade`, `Papel` e `exigirAdmin` de `shared/autorizacao/identidade.dart`.
- Produces: metodos `buscarAlunoPorId`, `buscarAlunos`, `atualizar`, `alterarStatus` e `excluir` com `Identidade` obrigatoria.

- [ ] **Step 1: Escrever testes RED da matriz de autorizacao**

Adicionar casos para admin, aluno dono, outro aluno e professor. Fixar `403` antes de existencia para acesso proibido, inclusive ID `0`/inexistente; preservar admin `200/204/404/409` e dono `200` em GET/PATCH proprio.

- [ ] **Step 2: Executar os testes focados e confirmar falha pelo controle ausente**

Run: `dart test test/aluno_service_test.dart test/aluno_controller_test.dart`  
Expected: FAIL porque os metodos atuais nao recebem/aplicam `Identidade`.

- [ ] **Step 3: Implementar as assinaturas e guards no Service**

Criar helper privado admin-ou-dono. `buscarAlunos`, `alterarStatus` e `excluir` chamam `exigirAdmin` antes do repository. Busca individual e atualizacao permitem admin ou `Papel.aluno` com `identidade.id == idAluno`; professor e outro aluno recebem `AcessoNegado`.

- [ ] **Step 4: Encaminhar identidade no controller e manter envelopes existentes**

Extrair com `identidadeDaRequisicao(req)` e passar ao Service em todas as rotas. Reutilizar o tratamento de `AcessoNegado` para `403 ACESSO_NEGADO`.

- [ ] **Step 5: Executar testes focados e revisar bypasses**

Run: `dart test test/aluno_service_test.dart test/aluno_controller_test.dart`  
Expected: PASS; verificar manualmente todos os cinco chamadores dos metodos alterados.

### Task 2: Persistir e validar sessoes JWT

**Files:**
- Create: `database/migrations/001_adiciona_sessao_auth.sql`
- Modify: `backend/lib/features/auth/token_service.dart`
- Modify: `backend/lib/features/auth/auth_repository.dart`
- Modify: `backend/lib/features/auth/auth_service.dart`
- Modify: `backend/lib/features/auth/auth_controller.dart`
- Modify: `backend/lib/shared/middleware/identidade_middleware.dart`
- Modify: `backend/bin/server.dart`
- Modify: `backend/test/token_service_test.dart`
- Modify: `backend/test/auth_service_test.dart`
- Modify: `backend/test/auth_http_test.dart`
- Create: `backend/test/auth_session_repository_test.dart`
- Modify: `backend/test/schema_verificacao_test.dart`

**Interfaces:**
- Produces: `TokenEmitido` (`token`, `jtiHash`, `expiraEm`) e `TokenValidado` (`identidade`, `jtiHash`, `expiraEm`).
- Produces em `AuthRepository`: `registrarSessao`, `sessaoAtiva`, `revogarSessao`, `limparSessoesExpiradas`.
- Consumes: `sessao_auth` criada pela migration e identidade autenticada no middleware.

- [ ] **Step 1: Escrever testes RED de persistencia e reinicio**

Cobrir registro no login, token sem sessao, logout persistente apos novas instancias de Service, sessao expirada/revogada e novo login independente.

- [ ] **Step 2: Escrever teste RED da migration e triggers**

Aplicar SQL em banco de teste; trocar `senha_hash` de admin e professor e afirmar `revogada_em IS NOT NULL` para todas as sessoes ativas da identidade. Conferir checks e indices esperados.

- [ ] **Step 3: Executar testes focados e confirmar falhas esperadas**

Run: `dart test test/token_service_test.dart test/auth_service_test.dart test/auth_http_test.dart test/auth_session_repository_test.dart test/schema_verificacao_test.dart`  
Expected: FAIL por tabela e APIs ainda inexistentes.

- [ ] **Step 4: Criar migration transacional D58**

Criar `sessao_auth`, checks, indices, funcao de trigger e triggers nas tres tabelas. Usar `BEGIN;`/`COMMIT;`, nomes estaveis e comandos que o aplicador registre uma unica vez.

- [ ] **Step 5: Separar criptografia de token de persistencia**

Alterar `emitir(Identidade) -> TokenEmitido` e `validar(String) -> TokenValidado?`. Remover a denylist em memoria. Validar `jti`, prazo e identidade sem consultar banco dentro de `TokenService`.

- [ ] **Step 6: Implementar repository e ciclo login/logout**

Login persiste antes de responder. Middleware exige conta e sessao ativas. Logout recebe os metadados validados do contexto e atualiza `revogada_em`; resposta continua `204`.

- [ ] **Step 7: Executar testes focados e desafiar o patch**

Run: mesmo comando do Step 3.  
Expected: PASS. Testar tambem `jti` desconhecido, papel/ID divergente e logout repetido com token ja revogado retornando `401` no middleware.

### Task 3: Limitar corpos HTTP antes dos controllers

**Files:**
- Create: `backend/lib/shared/middleware/limite_corpo.dart`
- Create: `backend/test/limite_corpo_test.dart`
- Modify: `backend/bin/server.dart`
- Modify: `shared/lib/erros/codigo_erro.dart`

**Interfaces:**
- Produces: `Middleware limiteCorpo({int maxBytes = 16384})`.
- Produces: codigo `CORPO_MUITO_GRANDE` usado no envelope `413`.

- [ ] **Step 1: Escrever testes RED do limite**

Cobrir corpo de 16 KiB, 16 KiB + 1, `Content-Length` declarado acima do teto, stream fragmentada sem tamanho e flag provando que o handler nao foi chamado no erro.

- [ ] **Step 2: Executar teste e confirmar falha por middleware ausente**

Run: `dart test test/limite_corpo_test.dart`  
Expected: FAIL por API inexistente.

- [ ] **Step 3: Implementar buffering limitado e resposta 413**

Contar bytes com `BytesBuilder`, interromper no excedente e recriar `Request` com bytes aceitos. Nao registrar corpo. Inserir depois de `identidadeMiddleware` no pipeline; manter `_lerJsonLimitado` de 4 KiB no login.

- [ ] **Step 4: Executar testes focados e controles legitimos**

Run: `dart test test/limite_corpo_test.dart test/auth_http_test.dart test/admin_controller_test.dart test/aluno_controller_test.dart test/professor_controller_test.dart`  
Expected: PASS para limite, login e CRUDs normais.

### Task 4: Remover credenciais previsiveis dos artefatos de API

**Files:**
- Modify: `backend/docs/insomnia/GraziFit.json`
- Modify: `docs/api/grazifit-pessoas.postman_collection.json`
- Create: `backend/test/api_collections_security_test.dart`

**Interfaces:**
- Produces: variaveis locais vazias para CPF, e-mail e senha de cada criacao; nenhuma credencial funcional versionada.

- [ ] **Step 1: Escrever teste RED que percorre as collections**

Parsear ambos os JSONs e recusar senhas literais, e-mails de criacao literais e os pares conhecidos do relatorio. Confirmar que referencias a variaveis continuam presentes.

- [ ] **Step 2: Executar teste e confirmar que encontra os exemplos atuais**

Run: `dart test test/api_collections_security_test.dart`  
Expected: FAIL encontrando `senha123` e e-mails literais.

- [ ] **Step 3: Substituir exemplos por variaveis sem defaults utilizaveis**

Preservar nomes, metodos, URLs e captura automatica de token. Descrever que cada desenvolvedor deve preencher valores unicos no ambiente local.

- [ ] **Step 4: Executar teste e validar importacao JSON**

Run: `dart test test/api_collections_security_test.dart`  
Expected: PASS; `ConvertFrom-Json` deve aceitar ambos os arquivos.

### Task 5: Documentacao, migration real e verificacao final

**Files:**
- Modify: `backend/lib/features/auth/README.md`
- Modify: `backend/lib/features/pessoas/README.md`
- Modify: `docs/arquitetura.md`
- Modify: `backend/docs/insomnia/GraziFit.json` se o contrato final exigir ajuste de descricao.

**Interfaces:**
- Consumes: contratos finais das Tasks 1–4.
- Produces: documentacao de RBAC, sessao persistente, limite de corpo e operacao de migration.

- [ ] **Step 1: Atualizar documentacao sem prometer a pendencia operacional**

Registrar matriz de permissao, encerramento de tokens anteriores ao deploy, `413`, limpeza de sessao e a necessidade de limite equivalente no proxy. Registrar separadamente que a conta local de exemplo nao foi consultada/rotacionada.

- [ ] **Step 2: Aplicar migration pelo Compose e repetir o aplicador**

Run: `docker compose up -d banco migrate` e repetir o servico `migrate`.  
Expected: primeira execucao aplica `001`; segunda informa ja aplicada e nao muda schema/dados.

- [ ] **Step 3: Executar formatacao e analise estatica**

Run: `dart format --output=none --set-exit-if-changed bin lib test` e `dart analyze` em `backend/`.  
Expected: nenhum arquivo por formatar e `No issues found!`.

- [ ] **Step 4: Executar suite completa**

Run: `dart test` em `backend/` com PostgreSQL de teste disponivel.  
Expected: todos os testes passam, incluindo os novos testes negativos.

- [ ] **Step 5: Reconstruir e validar fluxos HTTP reais**

Run: `docker compose up -d --build backend`.  
Expected: backend `healthy`; admin permitido; aluno dono permitido em GET/PATCH proprio; outro aluno/professor `403`; logout `204`; replay apos reinicio `401`; corpo grande `413`.

- [ ] **Step 6: Revisar diff e pendencias**

Run: `git diff --check`, `git diff --name-only --diff-filter=U` e `git status --short`.  
Expected: sem marcadores/conflitos e sem segredo novo. Nao criar commit durante o merge pendente.
