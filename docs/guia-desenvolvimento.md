# Guia de Desenvolvimento — GraziFit

**Como se constrói uma feature neste repositório: em que ordem, em qual pasta e com qual critério de pronto.**

Este documento não decide nada. Ele registra decisões já tomadas em `docs/arquitetura.md` e no prompt de implementação, expandidas com os caminhos reais criados na Fase 1. Se algo aqui divergir do schema ou de `docs/arquitetura.md`, **eles vencem** — e a divergência é para ser reportada, não interpretada.

**Subir o banco, baixar dependências, rodar e testar: §12.**

## Ordem de autoridade

1. Instrução explícita do usuário
2. `database/schema/grazi_db_init_schema.sql` — o domínio de dados
3. `docs/arquitetura.md` — as decisões de arquitetura
4. Este documento — a ordem e o método de construção

Em conflito entre fontes, **pare e pergunte**. Nunca escolha uma interpretação por conta própria.

---

## 1. Fatias verticais, nunca camadas horizontais

**Não** construa todos os repositories, depois todos os services, depois todos os controllers. Construa **uma feature de ponta a ponta** antes de começar a próxima.

A razão é prática, não estética:

- Horizontal só entrega valor no fim, e empurra todo erro de contrato para a integração final.
- Vertical entrega uma jornada funcionando por vez — que é exatamente como o roadmap está cortado, cada sprint fechando jornadas — e faz o erro de contrato aparecer na primeira fatia, quando ainda custa barato.

Uma fatia vertical vai do DTO em `shared/lib/dtos/` até a tela em `app/lib/features/<feature>/screens/`, passando por repository, service e controller. Ela termina quando a jornada F-xx funciona do toque à gravação — ver §7.

Feature não coincide com sprint: `auth`, `agendamentos` e `treinos` atravessam duas sprints cada. Sprint com feature aberta não é sprint com pendência, desde que a coluna "Fecha" do quadro de sprints seja respeitada (`docs/arquitetura.md` §3.7).

---

## 2. A ordem entre features é ditada pelas chaves estrangeiras

Não é preferência. Uma entidade não se constrói antes daquilo que referencia:

```
auth → pessoas → vinculos ─┐
         │                 ├→ treinos → historico
         │    exercicios ──┘
         └→ cronogramas → aulas → agendamentos
         └→ avaliacoes
```

`inicio` é a última: só compõe leitura do que as outras produzem.

As dez features existem com o mesmo nome dos dois lados — `backend/lib/features/` e `app/lib/features/`. Feature que exista só em um lado é erro.

| Feature | Jornadas | Tabelas que possui |
|---|---|---|
| `auth` | F-01, F-24 | nenhuma — resolve identidade sobre as três |
| `pessoas` | F-02, F-09, F-16, F-23 | `aluno`, `professor`, `admin`, `endereco` |
| `vinculos` | F-13, F-17 | `vinculo_professor_aluno` |
| `avaliacoes` | F-08, F-15 | `avaliacao` |
| `cronogramas` | F-18, F-19 | `cronograma`, `cronograma_dia` |
| `aulas` | F-10, F-12, F-20 | `aula` |
| `agendamentos` | F-03, F-04, F-05, F-11 | `agendamento` |
| `exercicios` | F-21 | `exercicio` |
| `treinos` | F-06, F-07, F-14, F-22 | `treino`, `treino_exercicio`, `historico_treino` |
| `inicio` | — | nenhuma — só compõe leitura |

**Uma tabela, um dono.** Só o repository da feature dona escreve na tabela. Ler tabela ou view de outra feature é livre; escrever em tabela alheia acontece só **service → service**, e existem exatamente duas escritas assim em todo o sistema — ambas coincidentes com os dois triggers do banco. Uma terceira é sinal de recorte errado e se discute antes de implementar.

---

## 3. Sim, autenticação primeiro — pela razão certa

Não porque "é a base", mas porque **toda feature seguinte precisa da identidade e do papel para decidir escopo**. Sem `auth` não há como testar RBAC, e RBAC é onde vive a regra que o roadmap classifica como risco de LGPD e não como defeito de interface: `restricao_medica` e `observacao_saude` não podem sequer existir no payload destinado ao admin.

Junto de `auth` nascem duas peças que não moram dentro da feature:

| Peça | Onde vive |
|---|---|
| Middleware de identidade (backend) | `backend/lib/shared/middleware/` |
| Guard de rota por papel (app) | `app/lib/core/routing/` |

`auth` fica **incompleta até a S2**, quando F-24 fecha.

---

## 4. O mapa de pastas

Onde cada coisa mora, o que ela pode importar e quem pode importá-la. Esta seção é **referência**: consulte-a antes de criar arquivo em pasta nova.

Antes de tudo, a desambiguação que já causou confusão. Existem **dois `database`** no repositório, e eles não têm relação um com o outro:

| Caminho | O que é |
|---|---|
| `database/` (raiz) | **SQL.** Schema e migrations. Fonte de verdade do domínio de dados |
| `backend/lib/database/` | **Dart.** A conexão Drift — `GraziDatabase`, endpoint, pool. **Não é camada de repositório** |

O repository **não** mora em `backend/lib/database/`. Ele mora dentro da feature dona da tabela — ver §4.3.

### 4.1 As quatro raízes

| Raiz | O que é | Fronteira |
|---|---|---|
| `database/` | SQL puro. Nem Dart, nem pacote pub | Não é importado por ninguém: é aplicado ao Postgres por `database/aplicar.sh` |
| `shared/` | Dart puro — o contrato que os dois lados enxergam | Não importa `flutter`, nem `shelf`, nem `drift_postgres` |
| `backend/` | Servidor HTTP e acesso ao banco | Nunca importa `package:flutter` |
| `app/` | Flutter | Nunca importa `shelf` nem `drift_postgres` |

Essas três negativas são verificáveis em lint a partir da Fase 3 — ver §10.

### 4.2 Referência por pasta

Marcadas com **◇** as regras que são **derivação** de decisões firmadas, não citação literal delas. As quatro estão listadas ao final desta seção.

**Raiz — o SQL**

| Pasta | O que vive | Consumido por | Nunca |
|---|---|---|---|
| `database/schema/` | `grazi_db_init_schema.sql` — 14 tabelas, 2 views, 2 funções, 2 triggers | `database/aplicar.sh`; e o container do teste de integração, que sobe deste mesmo arquivo | Ser gerado por Dart ou pelo Drift |
| `database/migrations/` | Migrations SQL numeradas, aplicadas em ordem | `database/aplicar.sh` | Nascer do `make-migrations` do Drift — o fluxo não é usado neste projeto |
| `database/seed/` | Vazia hoje. O seed do admin é programa Dart e serviço one-shot da Fase 3 — **◻ nenhuma fonte fixa o caminho dele ainda** | — | Rodar no boot do backend |

**Contrato — o que os dois lados enxergam**

| Pasta | O que vive | Pode importar | É importado por | Nunca |
|---|---|---|---|---|
| `shared/lib/dtos/` | Os DTOs. **DTO distinto por perfil**, não um DTO comum com campos anulados | nada do projeto | os `*_controller.dart` do backend e as `data/` do app | Carregar campo que um perfil não pode ver — campo que chega ao cliente e é ocultado na tela já vazou |
| `shared/lib/erros/` | Os códigos do envelope `{ codigo, mensagem, campo? }` | nada | `backend/lib/shared/erros/`, `app/lib/core/network/` | Conter texto de interface — o código é para máquina, a tela escolhe o texto |

**Backend**

| Pasta | O que vive | Pode importar | É importado por | Nunca |
|---|---|---|---|---|
| `backend/bin/` | `server.dart` — lê config, abre o pool, monta middleware e router, sobe o HTTP. **Fase 3** | `lib/router.dart`, `lib/shared/middleware/`, `lib/database/` | ninguém | Conter regra de negócio; rodar o seed |
| `backend/lib/database/` | `database.dart` + `database.g.dart` — `GraziDatabase`, tradução da `DATABASE_URL`, pool, `MigrationStrategy` deliberadamente vazia | `drift`, `drift_postgres`, `postgres`, e os `*_table.dart` das features, para registrá-los em `@DriftDatabase` | os `*_repository.dart`, e só eles ◇ | Emitir DDL; conhecer HTTP, perfil ou regra de negócio |
| `backend/lib/features/<f>/` | Os quatro papéis da feature, direto na pasta — §4.3 | ver §4.3 | `lib/router.dart` importa os controllers | Ter subpasta por camada |
| `backend/lib/shared/autorizacao/` | A matriz RBAC de 15 entidades × 3 perfis, como tabela declarativa e não como `if` espalhado | nada do domínio | os `*_service.dart`, e só eles | Ser consultada por controller ou repository |
| `backend/lib/shared/erros/` | O tradutor **único** de SQLSTATE e nome de constraint para código do contrato | `shared/lib/erros/` | o error handler do middleware | Ser duplicado dentro de uma feature |
| `backend/lib/shared/middleware/` | Autenticação, resolução do papel, injeção da identidade no contexto, log com id de requisição | `lib/shared/erros/`, `features/auth/` | `bin/server.dart` | Decidir permissão — responde *quem é*, jamais *pode* |
| `backend/lib/router.dart` | Reúne os controllers das 10 features numa árvore de rotas. **Fase 3** | os `*_controller.dart` | `bin/server.dart` | Conter lógica de qualquer espécie |
| `backend/test/` | Os três níveis de teste: unitário com repository falso, integração contra Postgres real, concorrência com commits reais | tudo de `lib/` | — | Mockar o banco em teste de repository |

**App**

| Pasta | O que vive | Pode importar | É importado por | Nunca |
|---|---|---|---|---|
| `app/lib/core/design_system/tokens/` | 48 variáveis, 8 estilos de texto, 3 elevações | nada | `components/` e as `screens/` de qualquer feature | Ser redefinido dentro de uma feature |
| `app/lib/core/design_system/components/` | Os 21 conjuntos portados do protótipo | `tokens/` | `screens/` e `widgets/` de qualquer feature | Conhecer feature ou DTO |
| `app/lib/core/state/` | `AsyncState<T>` e seus cinco estados — carregando, vazio, erro, sem conexão, dados | nada | `state/` e `screens/` de todas as features | — |
| `app/lib/core/routing/` | `go_router`, guard por papel, os três shells parametrizados | `features/*/screens/`, `features/auth/state/` | `main.dart` | Ser mecanismo de segurança — pode ocultar o que o papel não usa, mas quem nega é o backend |
| `app/lib/core/network/` | Cliente HTTP, base URL, leitura do envelope de erro | `shared/lib/erros/` | as `data/` de todas as features | Conhecer tela ou provider |
| `app/lib/features/<f>/data/` | Chamada HTTP e parse do DTO | `core/network/`, `shared/lib/dtos/`, `shared/lib/erros/` | `state/` da mesma feature | Guardar estado; tocar em widget; persistir em disco |
| `app/lib/features/<f>/state/` | Providers Riverpod devolvendo `AsyncState` | `data/` da mesma feature, `core/state/` | `screens/` e `widgets/` da mesma feature | Fazer HTTP por conta própria |
| `app/lib/features/<f>/screens/` | As telas, cada uma com os cinco estados | `state/` e `widgets/` da mesma feature, `core/design_system/` | `core/routing/` | Chamar `data/` direto ◇; conter regra de negócio; recalcular o que o banco já calculou |
| `app/lib/features/<f>/widgets/` | Componentes que só esta feature usa | `core/design_system/`, `state/` da mesma feature | `screens/` da mesma feature | Fazer chamada HTTP ◇ |
| `app/test/` | Testes de widget | `lib/` | — | Depender do banco |

**As quatro derivações ◇**, e de onde decorrem:

| ◇ | Decorre de |
|---|---|
| `lib/database/` só é importado por repository | "Repository — única camada que conversa com Drift/Postgres" (`docs/arquitetura.md` §2) |
| `screens/` não chama `data/` direto | a ordem 5→6→7 da §5, somada a "toda chamada devolve `AsyncState`" (§6) |
| `widgets/` não faz chamada HTTP | mesma origem |
| Repository pode importar `*_table.dart` de outra feature para **ler** | R3 — "ler tabela ou view de outra feature é livre" (`docs/arquitetura.md` §3.2) |

### 4.3 Dentro de uma feature do backend

Arquivos **direto na pasta, sem subpasta por camada**. Quatro papéis, nome de domínio em pt-BR e papel em inglês:

```
backend/lib/features/pessoas/
├── README.md
├── aluno_table.dart         declara ao Drift o subconjunto de colunas usado
├── aluno_repository.dart    única camada que fala Drift/Postgres
├── aluno_service.dart       regra de negócio e escopo de autorização
├── aluno_controller.dart    forma da requisição e montagem do DTO
├── professor_table.dart
├── professor_repository.dart
└── ...
```

**Por que sem subpasta.** A pergunta reaparece toda vez que uma feature cresce, e a resposta é a mesma três vezes:

1. **A camada já está no nome do arquivo.** `aluno_repository.dart` não fica mais claro dentro de uma pasta `repository/` — ela repetiria o que a convenção de nomenclatura (§9) já obriga o nome a dizer.
2. **Flat agrupa por entidade; subpasta agruparia por camada.** Ordenado alfabeticamente, `aluno_controller` · `aluno_repository` · `aluno_service` · `aluno_table` ficam vizinhos. Quem constrói uma fatia vertical (§1) trabalha uma entidade por vez, nunca uma camada por vez — e agrupar por camada é justamente o que a §1 proíbe.
3. **Subpasta faria a fatia atravessar quatro diretórios** dentro da própria feature, e criaria cerca de 40 diretórios no backend, a maioria com um arquivo só. `auth`, que não possui tabela, ficaria com uma pasta `table/` vazia.

Escala real: das 10 features, **oito possuem uma tabela ou nenhuma**. Só `pessoas` (4 tabelas) e `treinos` (3) passam de cinco arquivos.

**A cadeia de chamada:**

```
controller ──▶ service ──▶ repository ──▶ lib/database/ ──▶ PostgreSQL
                  │
                  ├──▶ shared/autorizacao/
                  └──▶ service de outra feature   (só as duas escritas de arquitetura.md §3.5)
```

Cada seta é a **única** entrada permitida na camada seguinte. As proibições que sustentam isso:

| Quem | Nunca |
|---|---|
| `controller` | Pular o service; decidir permissão; conhecer Drift |
| `service` | Falar com o banco direto; conhecer HTTP; escrever em tabela de outra feature |
| `repository` | Conhecer HTTP ou perfil de usuário; escrever em tabela que a feature não possui |
| `*_table.dart` | Criar, versionar ou governar o banco |

**Leitura atravessa, escrita não.** O repository de uma feature pode importar o `*_table.dart` de outra para **ler** ◇. Para escrever, a única via é **service → service**, e existem exatamente **duas** em todo o sistema — ambas coincidentes com os dois triggers do banco. Uma terceira é sinal de recorte errado, e se discute antes de implementar.

### 4.4 Dentro de uma feature do app

Aqui as subpastas existem, e por um motivo diferente: cada uma é uma **camada com tecnologia própria**, não um papel de arquivo.

```
screens/ ──▶ state/ ──▶ data/ ──▶ core/network/ + shared/lib/dtos/
    │                                    │
    │                                    └──▶ shared/lib/erros/
    └──▶ widgets/ + core/design_system/components/
```

| Pasta | Pergunta que ela responde |
|---|---|
| `data/` | Como esse dado chega do backend? |
| `state/` | Em qual dos cinco estados ele está agora? |
| `screens/` | Como cada um dos cinco estados aparece? |
| `widgets/` | Que pedaço de tela só esta feature usa? |

**A tela nunca chama `data/` direto ◇.** Se chamasse, pularia o `AsyncState` e perderia os cinco estados que a RNF-04 exige nas 60 telas — resolvido uma vez em `core/`, ou 60 vezes à mão.

**Composição entre features acontece em `core/routing/`, nunca entre features.** Cinco das oito abas compõem mais de uma feature, e o `Detalhe do aluno` do Professor atravessa quatro numa tela só. Uma feature **não** importa as `screens/` de outra: o shell parametrizado é que as reúne. Componente que passe a ser usado por mais de uma feature sobe para `core/design_system/components/`.

### 4.5 Uma fatia rastreada — `exercicios` / F-21

A fatia completa mais simples do projeto: uma tabela (`exercicio`), uma feature dona, nenhuma leitura cruzada e nenhuma das duas escritas entre features. Os sete passos da §5, com o caminho real de cada arquivo.

| # | Arquivo | O que entra nele |
|---|---|---|
| 1 | `shared/lib/dtos/⟨a especificar⟩.dart` | Os campos que atravessam a fronteira: `id_exercicio`, `nome`, `instrucoes`, `descricao`, `dificuldade`. `id_admin_criador` é escrita do servidor, não entrada do cliente |
| 2 | `backend/lib/features/exercicios/exercicio_table.dart` | As colunas de `exercicio`, **todas declaradas `NOT NULL` onde o banco assim as define** — o Drift só enxerga o que a classe declara, e omitir coluna obrigatória falha em runtime com `23502` |
| 3 | `backend/lib/features/exercicios/exercicio_repository.dart` | Select e insert tipados sobre `GraziDatabase`. É aqui que `uq_exercicio_nome` e `ck_exercicio_dificuldade` aparecem — logo, teste de integração contra Postgres real, nunca mock |
| 4 | `backend/lib/features/exercicios/exercicio_service.dart` | Regra de negócio e as duas perguntas de autorização contra `shared/autorizacao/`. Preenche `id_admin_criador` a partir da identidade que o middleware injetou |
| 5 | `backend/lib/features/exercicios/exercicio_controller.dart` | Só forma e DTO. A rota entra em `lib/router.dart` |
| 6 | `app/lib/features/exercicios/data/` | HTTP e parse do DTO do passo 1 |
| 7 | `app/lib/features/exercicios/state/` | Provider Riverpod devolvendo `AsyncState` |
| 8 | `app/lib/features/exercicios/screens/` | Os cinco estados |

**Como o endpoint se chama ainda não está especificado** — proponha por feature e submeta antes de implementar (§6).

**O erro, ponta a ponta.** Cadastrar exercício com nome repetido levanta `23505` com `constraintName = uq_exercicio_nome`. O repository **não traduz**: quem traduz é `backend/lib/shared/erros/`, para o envelope `{ codigo, mensagem, campo? }`, e a tela escolhe o texto **pelo código**, jamais pela mensagem do Postgres.

**◻ Pendente — `uq_exercicio_nome` não tem código.** O mapa de `docs/arquitetura.md` §7.1 cobre nove constraints, e esta não está entre elas. O código é `⟨a especificar⟩` e precisa entrar no mapa antes da S5.

**◻ Pendente — a ordem de `auth` × `pessoas`.** Duas regras firmadas colidem, e a colisão cai na primeira fatia da Fase 4:

- `auth` é a primeira feature construída (§2 e §3) e **não possui tabela nenhuma**: resolve identidade lendo `aluno`, `professor` e `admin`.
- Essas três tabelas pertencem a `pessoas` (`docs/arquitetura.md` §3.2), que só nasce na S2.

Quem declara `aluno_table.dart` quando `auth` precisar ler `senha_hash` antes de `pessoas` existir? Ler tabela alheia é livre (R3), mas ainda não há tabela alheia declarada. **Não resolva isso dentro do código** — é exatamente o gatilho da §11.

---

## 5. A ordem dentro de uma fatia

| # | Passo | Onde | Por que nesta posição |
|---|---|---|---|
| 1 | **DTO** | `shared/lib/dtos/` | Único artefato que os dois lados compartilham. Definido primeiro, impede que backend e app divirjam |
| 2 | **Repository** | `backend/lib/features/<feature>/<dominio>_repository.dart` | É onde constraint e trigger aparecem. Teste de integração contra **Postgres real** — mock aqui não prova nada |
| 3 | **Service** | `backend/lib/features/<feature>/<dominio>_service.dart` | Regra de negócio e escopo de autorização. Teste unitário com repository falso |
| 4 | **Controller + rota** | `backend/lib/features/<feature>/<dominio>_controller.dart` | Só forma e DTO. Nenhuma regra, nenhuma permissão |
| 5 | **`data/`** | `app/lib/features/<feature>/data/` | Chamada HTTP e parse do DTO |
| 6 | **`state/`** | `app/lib/features/<feature>/state/` | Provider Riverpod devolvendo `AsyncState` |
| 7 | **`screens/`** | `app/lib/features/<feature>/screens/` | Os cinco estados obrigatórios |

Isso responde à dúvida mais comum: **não se começa pela camada de negócio nem pela tela — começa-se pelo contrato.**

O layout de pasta de cada lado — e a razão de o backend ser flat enquanto o app tem quatro subpastas — está na §4.3 e na §4.4.

---

## 6. Comunicação entre app e backend

- **REST sobre HTTPS, JSON.** O contrato é sempre um DTO de `shared/`. Nenhum lado serializa mapa solto: se o app precisa de um campo, ele nasce no DTO.
- **Endpoints derivam das jornadas**, não de CRUD genérico, e pertencem à feature dona da tabela. A lista de endpoints **ainda não está especificada** — proponha por feature e submeta antes de implementar.
- **Erro:** toda resposta de erro usa `{ codigo, mensagem, campo? }`. O app escolhe o texto **pelo código**, jamais pela mensagem.
- **Autorização:** o app **nunca** decide permissão. Pode ocultar o que o papel não usa, mas quem nega é o backend. Tela que some não é segurança.
- **Estado:** toda chamada devolve `AsyncState`. Nenhuma tela sem os cinco estados — RNF-04 vale para as 60.
- **Sem persistência local.** O app é 100% online (Restr. 3). Não introduza cache em disco nem banco local.
- **Sem polling global.** Só Agenda, Detalhe da aula e Chamada atualizam periodicamente; o resto atualiza ao focar a tela e após cada ação.

---

## 7. Definição de pronto de uma fatia vertical

- [ ] A jornada F-xx completa, do toque à gravação
- [ ] Constraint e trigger relevantes traduzidos em código de erro e mensagem ao usuário
- [ ] Os cinco estados na tela
- [ ] RBAC testado nos **três** perfis, incluindo o que deve ser negado
- [ ] Nenhuma escrita em tabela de outra feature
- [ ] Teste de integração contra Postgres real
- [ ] Nenhuma regra de negócio no Controller nem na tela

---

## 8. Antipadrões — a lista que evita furo de lógica

| Antipadrão | Consequência |
|---|---|
| Construir horizontalmente | Erro de contrato só aparece na integração final |
| Recalcular no app o que o banco calcula | IMC divergente entre tela e banco (RF-03) |
| Comparar texto de mensagem de erro | Quebra na primeira mudança de versão do Postgres ou de idioma |
| Botão escondido como mecanismo de permissão | Vazamento por chamada direta à API |
| Deixar a tela decidir regra de negócio | A mesma regra passa a existir em três telas com três resultados |
| Endpoint CRUD genérico | A regra da jornada — janela de 2h, vagas — fica sem dono |
| Mockar o banco em teste de repository | Trigger e constraint nunca são exercitados |
| Inventar campo que "faltou" | Diverge do schema, que é autoridade acima do código |

---

## 9. Convenções de nomenclatura

| Elemento | Convenção | Exemplo |
|---|---|---|
| Tabelas e colunas | pt-BR, `snake_case`, espelhando o banco | `vinculo_professor_aluno`, `id_aluno` |
| Classes de domínio | pt-BR, `PascalCase` | `Aluno`, `Aula`, `Agendamento` |
| Camadas e pastas técnicas | inglês | `features/`, `repository`, `service` |
| Arquivos | domínio pt-BR + papel em inglês | `aluno_repository.dart` |

Com 14 tabelas, a convenção precisa estar escrita antes da primeira classe — não descoberta na terceira sprint.

---

## 10. Fronteiras de import

Verificáveis em lint, a partir da Fase 3:

- `backend/` nunca importa `package:flutter`.
- `app/` nunca importa `shelf` nem `drift_postgres`.
- `shared/` não importa nenhum dos dois.

---

## 11. Quando parar e perguntar

Pare imediatamente, em vez de decidir, se:

- este documento divergir de `docs/arquitetura.md` ou do schema
- surgir necessidade de tabela, coluna ou regra que não existe no schema
- uma tarefa exigir saber **quem** marcou presença, confirmou execução ou registrou avaliação — o schema não registra o autor dessas três ações, embora mais de um perfil possa executá-las
- parecer necessário antecipar uma fase para que a estrutura "funcione"

O projeto tem 67 decisões registradas justamente para que nenhuma seja tomada dentro do código. Pergunta sem resposta registrada é **escopo novo** — e escopo novo não se resolve implementando. Toda alteração estrutural nasce como change em `openspec/changes/`, com `proposal.md`, `design.md` e `tasks.md`.

---

## 12. Comandos do dia a dia

Não há npm, Makefile nem gerenciador de SDK neste repositório. Dependências de Dart e Flutter são baixadas exclusivamente pelo **`pub`**, e cada pacote resolve as suas: `backend/` com `dart pub`, `app/` com `flutter pub`. `shared/` ainda não tem `pubspec.yaml` — é da Fase 3.

Os comandos abaixo são os que funcionam **hoje**. Comando de fase futura está marcado como tal e não deve ser inventado antes da hora.

### 12.1 Preparar o repositório do zero

| # | Comando | O que faz |
|---|---|---|
| 1 | `cp .env.example .env` | Cria o ambiente local. Preencher **`POSTGRES_PASSWORD`** e **`DATABASE_URL`** — nenhuma das duas tem default |
| 2 | `docker compose up -d` | Sobe o PostgreSQL 18 (serviço `banco`, container `grazifit-db`) |
| 3 | `bash database/aplicar.sh` | Aplica schema e migrations, em ordem e de forma idempotente |
| 4 | `cd backend && dart pub get` | Baixa as dependências do backend |
| 5 | `cd app && flutter pub get` | Baixa as dependências do app |

**Porta ocupada.** Se a máquina já tiver um PostgreSQL nativo na 5432, o container não sobe — ou pior, o Dart conecta no servidor errado e o erro aparece como corrupção de protocolo. Defina `POSTGRES_PORT=5433` no `.env` e reflita a mesma porta na `DATABASE_URL`. Dentro da rede do compose a porta continua sendo 5432.

**Windows.** `database/aplicar.sh` é bash — rode pelo Git Bash. Sem `psql` no host, o script usa o `psql` de dentro do próprio container automaticamente.

### 12.2 Dependências

| Comando | Onde | O que faz |
|---|---|---|
| `dart pub get` | `backend/` | Instala o que está no `pubspec.lock` |
| `flutter pub get` | `app/` | Idem, para o app |
| `dart pub outdated` | `backend/` | Lista o que tem versão mais nova — **só relata, não altera** |
| `flutter pub outdated` | `app/` | Idem |
| `dart pub deps` | qualquer um | Mostra a árvore de dependências resolvida |

**`pub upgrade` não é rotina aqui.** As dependências do backend estão **fixadas em versão exata** de propósito (`drift 2.34.4`, `drift_postgres 1.3.1`, `postgres 3.5.12`, `drift_dev 2.34.6`), verificadas contra este schema em PostgreSQL 18 — `dart pub upgrade` não move nenhuma delas, e é assim que deve ser. Acrescentar, remover ou trocar dependência em qualquer `pubspec.yaml` é **alteração estrutural**: propõe-se antes, não se executa (§11). Se o resolvedor trouxer algo diferente e quebrar, **reporte antes de contornar**.

### 12.3 Código gerado pelo Drift

`backend/lib/database/database.g.dart` é gerado a partir do schema. Regere sempre que `database.dart` ou o SQL mudar:

```bash
cd backend
dart run build_runner build --delete-conflicting-outputs
```

`dart run build_runner watch` regenera continuamente durante uma sessão de trabalho. O gerado nunca se edita à mão — o arquivo em `database/schema/` é a fonte de verdade.

### 12.4 Rodar

| Alvo | Comando | Estado |
|---|---|---|
| Banco | `docker compose up -d` | Disponível |
| Banco — logs | `docker compose logs -f banco` | Disponível |
| Banco — parar | `docker compose down` | Disponível |
| App no Chrome | `cd app && flutter run -d chrome` | Disponível |
| App no Android | `cd app && flutter run -d <id>` (`flutter devices` lista os ids) | Disponível |
| Servidor backend | `dart run bin/server.dart` | **Fase 3** — `backend/bin/` só tem `.gitkeep`; o servidor, o `shelf` e o serviço de backend no compose ainda não existem |

**`docker compose down -v` apaga o volume `grazifit-data`** e com ele todos os dados. Depois disso, `bash database/aplicar.sh` precisa rodar de novo. Use apenas quando o objetivo for justamente zerar o banco.

### 12.5 Testar e analisar

| Comando | Onde | Observação |
|---|---|---|
| `dart test` | `backend/` | Exige o banco **de pé** e `DATABASE_URL` **no ambiente do processo** — o Dart não lê o `.env` enquanto o `config.dart` da Fase 3 não existir |
| `flutter test` | `app/` | Não depende do banco |
| `dart analyze` / `flutter analyze` | respectivo | Lints de `analysis_options.yaml` |
| `dart format .` | qualquer um | Formatação padrão do Dart |

No Git Bash, a variável vai na frente do comando:

```bash
cd backend
DATABASE_URL='postgresql://usuario:senha@localhost:5433/grazifit?sslmode=disable' dart test
```

No PowerShell, define-se antes:

```powershell
cd backend
$env:DATABASE_URL = 'postgresql://usuario:senha@localhost:5433/grazifit?sslmode=disable'
dart test
```

Caractere especial na senha precisa ser percent-encoded: `@` vira `%40`, `:` vira `%3A`, `/` vira `%2F`.

---

## Rastreabilidade

`database/schema/grazi_db_init_schema.sql` — 14 tabelas, 2 funções, 2 triggers, 2 views · `docs/arquitetura.md` §1 (fonte de verdade do schema), §2 (camadas), §3 (recorte de features), §4 (árvore do monorepo e fronteiras de import), §5 (autorização), §7 (contrato de erro), §8 (estado e roteamento), §11 (testes), §12 (convenções de nomenclatura) · `openspec/project.md` — contexto permanente e ordem de autoridade.
