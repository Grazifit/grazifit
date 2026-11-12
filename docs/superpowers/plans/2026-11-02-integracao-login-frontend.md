# Integração do Login no Frontend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Conectar a tela de login Flutter ao endpoint existente de autenticação e navegar para a tela inicial correspondente ao papel, sem alteração visual nem mudança no backend.

**Architecture:** A `LoginScreen` delega autenticação a um controller Riverpod, que usa um repository e um cliente HTTP injetáveis. O token e a identidade ficam somente em memória; a tela faz apenas a navegação de interface após o resultado.

**Tech Stack:** Flutter, Dart 3.13.2, `http`, Riverpod 2, pacote local `shared`, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-11-02-integracao-login-frontend-design.md`

## Global Constraints

- Não alterar componentes, textos, cores, tamanhos ou disposição da `LoginScreen`.
- Não alterar o endpoint `POST /auth/login` nem regras do backend.
- Não persistir token fora da memória do processo.
- Preservar todas as alterações locais já existentes no worktree.
- Usar `API_BASE_URL` fornecida por `--dart-define`.
- Destinos: admin → `TelaInicioAdmin`; aluno → `TelaAgendaAluno`; professor → `MeusAlunosScreen`.
- Cada tarefa segue RED → GREEN → REFACTOR e só inclui seus próprios arquivos no commit.

## Review Focus

- Resposta `200` malformada deve produzir erro controlado, não `TypeError` na UI — coberto na Task 2.
- Clique duplo durante requisição deve produzir uma única chamada — coberto na Task 4.
- `401` deve ativar somente o erro visual já existente — coberto na Task 5.
- `429` ou falha de rede não devem ser apresentados como credenciais inválidas — coberto nas Tasks 2, 4 e 5.
- Papel desconhecido não deve abrir uma tela privilegiada — coberto na Task 5.

---

### Task 1: Dependências e contrato de resposta

**Files:**
- Modify: `app/pubspec.yaml`
- Modify: `app/pubspec.lock`
- Modify: `shared/lib/dtos/auth_dto.dart`
- Create: `app/test/features/auth/auth_dto_test.dart`

**Interfaces:**
- Produces: `LoginResponseDto.fromJson(Map<String, dynamic> json)`.
- Produces: dependências `http`, `flutter_riverpod` e `shared: {path: ../shared}` disponíveis no app.

- [ ] **Step 1: Escrever os testes de desserialização**

Criar testes que confirmem o parse de `access_token`, `expires_in` e `usuario.{id,papel,nome}`, e que JSON sem esses tipos obrigatórios lance `FormatException`.

- [ ] **Step 2: Executar o teste e confirmar RED**

Run: `cd app && flutter test test/features/auth/auth_dto_test.dart`

Expected: FAIL porque `LoginResponseDto.fromJson` ainda não existe.

- [ ] **Step 3: Adicionar dependências preservando o conteúdo local**

Adicionar `http: ^1.6.0`, `flutter_riverpod: ^2.6.1` e `shared` por path. Manter os assets e quaisquer mudanças locais atuais. Rodar `flutter pub get` para atualizar o lockfile.

- [ ] **Step 4: Implementar o factory do DTO**

Adicionar `factory LoginResponseDto.fromJson(Map<String, dynamic> json)` com validação explícita e `FormatException` para estrutura inválida. Não alterar `toJson`.

- [ ] **Step 5: Executar o teste e confirmar GREEN**

Run: `cd app && flutter test test/features/auth/auth_dto_test.dart`

Expected: PASS.

- [ ] **Step 6: Commit isolado**

```bash
git add app/pubspec.yaml app/pubspec.lock shared/lib/dtos/auth_dto.dart app/test/features/auth/auth_dto_test.dart
git commit -m "feat(auth): preparar contrato de login no app"
```

### Task 2: Cliente HTTP comum

**Files:**
- Create: `app/lib/core/network/api_client.dart`
- Create: `app/lib/core/network/api_exception.dart`
- Create: `app/test/core/network/api_client_test.dart`

**Interfaces:**
- Produces: `ApiClient({http.Client? client, Uri? baseUri, Duration timeout = const Duration(seconds: 10)})`.
- Produces: `Future<Map<String, dynamic>> postJson(String path, Map<String, Object?> body)`.
- Produces: `ApiException` com `statusCode`, `codigo`, `mensagem` e `retryAfter` opcionais.

- [ ] **Step 1: Escrever testes do cliente**

Usar `MockClient` para verificar URL, método, `Content-Type`, corpo JSON, parse de `200`, parse de erro JSON, leitura de `Retry-After`, timeout e corpo `200` malformado.

- [ ] **Step 2: Executar e confirmar RED**

Run: `cd app && flutter test test/core/network/api_client_test.dart`

Expected: FAIL porque os tipos ainda não existem.

- [ ] **Step 3: Implementar `ApiException`**

Criar um tipo imutável que não contenha senha, token ou corpo cru da resposta.

- [ ] **Step 4: Implementar `ApiClient`**

Usar `const String.fromEnvironment('API_BASE_URL')` quando `baseUri` não for injetada. Rejeitar configuração vazia com erro controlado e converter falhas de transporte/timeout em `ApiException`.

- [ ] **Step 5: Executar e confirmar GREEN**

Run: `cd app && flutter test test/core/network/api_client_test.dart`

Expected: PASS.

- [ ] **Step 6: Commit isolado**

```bash
git add app/lib/core/network app/test/core/network
git commit -m "feat(network): adicionar cliente HTTP do app"
```

### Task 3: Repository de autenticação

**Files:**
- Create: `app/lib/features/auth/data/auth_repository.dart`
- Create: `app/test/features/auth/data/auth_repository_test.dart`

**Interfaces:**
- Consumes: `ApiClient.postJson` e `LoginResponseDto.fromJson`.
- Produces: `AuthRepository(ApiClient client)`.
- Produces: `Future<LoginResponseDto> login({required String email, required String senha})`.

- [ ] **Step 1: Escrever testes do repository**

Verificar `POST /auth/login`, JSON com chaves exatas `email` e `senha`, conversão do sucesso e propagação tipada de `401` e `429`. O teste não deve registrar senha nem token.

- [ ] **Step 2: Executar e confirmar RED**

Run: `cd app && flutter test test/features/auth/data/auth_repository_test.dart`

Expected: FAIL porque `AuthRepository` ainda não existe.

- [ ] **Step 3: Implementar o repository mínimo**

Não normalizar senha e não duplicar regras do backend. O e-mail é enviado como digitado; qualquer normalização permanece responsabilidade do endpoint atual.

- [ ] **Step 4: Executar e confirmar GREEN**

Run: `cd app && flutter test test/features/auth/data/auth_repository_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit isolado**

```bash
git add app/lib/features/auth/data app/test/features/auth/data
git commit -m "feat(auth): adicionar repository de login"
```

### Task 4: Controller e sessão em memória

**Files:**
- Create: `app/lib/features/auth/state/auth_state.dart`
- Create: `app/lib/features/auth/state/auth_controller.dart`
- Create: `app/test/features/auth/state/auth_controller_test.dart`

**Interfaces:**
- Consumes: `AuthRepository.login`.
- Produces: `AuthState` com estado inicial, em andamento, autenticado, credenciais inválidas e falha não visual.
- Produces: `AuthController.login(String email, String senha)` com guarda contra chamada concorrente.
- Produces: providers de `ApiClient`, `AuthRepository` e `AuthController`, todos substituíveis em teste.

- [ ] **Step 1: Escrever testes do controller**

Cobrir sucesso mantendo `LoginResponseDto` em memória, `401`, `429`, falha de rede e dois logins concorrentes resultando em uma chamada ao repository.

- [ ] **Step 2: Executar e confirmar RED**

Run: `cd app && flutter test test/features/auth/state/auth_controller_test.dart`

Expected: FAIL porque controller e estado ainda não existem.

- [ ] **Step 3: Implementar estado e controller**

Não persistir a sessão. Não incluir senha em estado, exceção, `toString` ou logs.

- [ ] **Step 4: Implementar providers injetáveis**

Montar a cadeia `ApiClient → AuthRepository → AuthController` sem instanciar transporte dentro da tela.

- [ ] **Step 5: Executar e confirmar GREEN**

Run: `cd app && flutter test test/features/auth/state/auth_controller_test.dart`

Expected: PASS.

- [ ] **Step 6: Commit isolado**

```bash
git add app/lib/features/auth/state app/test/features/auth/state
git commit -m "feat(auth): controlar sessão de login em memória"
```

### Task 5: Ligar a tela e navegar por papel

**Files:**
- Modify: `app/lib/features/auth/screens/login_screen.dart`
- Create: `app/test/features/auth/screens/login_screen_test.dart`

**Interfaces:**
- Consumes: provider do `AuthController` e `LoginResponseDto.papel`.
- Produces: navegação por `pushReplacement` para as três telas aprovadas.

- [ ] **Step 1: Criar testes de widget preservando o visual**

Confirmar que os textos existentes continuam sendo `E-mail`, `Senha`, `Entrar`, `Esqueci minha senha` e `E-mail ou senha inválidos`. Testar envio dos valores digitados, `401`, clique duplo e os destinos admin/aluno/professor.

- [ ] **Step 2: Executar e confirmar RED**

Run: `cd app && flutter test test/features/auth/screens/login_screen_test.dart`

Expected: FAIL porque o botão ainda ativa o erro simulado.

- [ ] **Step 3: Conectar somente o comportamento do botão**

Converter a tela para consumir Riverpod sem alterar a árvore visual. Substituir apenas o callback simulado por uma função assíncrona que lê os controllers existentes e chama o controller.

- [ ] **Step 4: Implementar navegação segura**

Após sucesso e com `context.mounted`, usar `pushReplacement`:

- `admin` → `const TelaInicioAdmin()`;
- `aluno` → `const TelaAgendaAluno()`;
- `professor` → `const MeusAlunosScreen()`;
- valor desconhecido → permanecer no login, sem assumir privilégios.

- [ ] **Step 5: Mapear somente `401` para o erro visual existente**

Falhas não visuais devem liberar nova tentativa sem trocar texto ou componente.

- [ ] **Step 6: Executar e confirmar GREEN**

Run: `cd app && flutter test test/features/auth/screens/login_screen_test.dart`

Expected: PASS.

- [ ] **Step 7: Commit isolado**

```bash
git add app/lib/features/auth/screens/login_screen.dart app/test/features/auth/screens/login_screen_test.dart
git commit -m "feat(auth): integrar tela ao fluxo de login"
```

### Task 6: Entrada da aplicação e verificação final

**Files:**
- Modify: `app/lib/main.dart`
- Modify: `app/pubspec.yaml`
- Create: `app/test/main_test.dart`

**Interfaces:**
- Consumes: providers de autenticação e `LoginScreen`.
- Produces: aplicação iniciando dentro de `ProviderScope` na tela de login.

- [ ] **Step 1: Escrever teste da entrada do app**

Verificar que a raiz contém `ProviderScope`, abre `LoginScreen` e não abre `MenuDevScreen` em produção.

- [ ] **Step 2: Executar e confirmar RED**

Run: `cd app && flutter test test/main_test.dart`

Expected: FAIL porque `main.dart` ainda abre o menu de desenvolvimento.

- [ ] **Step 3: Atualizar a entrada sem alterar o menu DEV**

Inicializar `ProviderScope` e `LoginScreen`. Não editar `menu_dev_screen.dart`, que possui alterações locais fora do escopo.

- [ ] **Step 4: Declarar o asset da marca preservando os atuais**

Adicionar `assets/images/marca.png` à lista existente de assets; não remover `logo.png` nem `logo_perfil.png`.

- [ ] **Step 5: Executar verificações finais**

Run:

```bash
cd app
flutter test
flutter analyze
dart format --output=none --set-exit-if-changed lib test
```

Expected: todos os testes passam, análise sem erros novos e formatação limpa. Se a análise apontar problema preexistente fora do escopo, registrar separadamente sem alterar o arquivo.

- [ ] **Step 6: Validar integração com backend local**

Com Docker saudável e `API_BASE_URL=http://localhost:8080`, autenticar um usuário de cada papel e confirmar os três destinos sem imprimir token ou senha nos logs.

- [ ] **Step 7: Commit isolado**

```bash
git add app/lib/main.dart app/pubspec.yaml app/pubspec.lock app/test/main_test.dart
git commit -m "feat(auth): iniciar aplicativo pelo login"
```

