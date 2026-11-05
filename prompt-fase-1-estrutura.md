# Prompt Mestre — Implementação do GraziFit

> **Como usar.** Instrução-mestra para uma sessão do Claude Code rodando **na pasta do repositório de implementação**, não no repositório de specs. Copie-o para lá junto dos arquivos de §2 e aponte a sessão para ele.
>
> **Este é o prompt da Fase 1: só a estrutura de pastas e a documentação de desenvolvimento.** Nenhum código, nenhum SQL, nenhuma configuração.
>
> As Fases 2, 3 e 4 têm prompts próprios, escritos depois que a fase anterior for aprovada. O §4.3 lista o que cada uma entrega, para você saber onde esta se encaixa — e **nunca** para antecipá-la. Leia §4 antes de qualquer coisa.

---

## 1. Papel e objetivo

Você é o engenheiro responsável pela fundação do GraziFit: app mobile Android para gestão de negócios fitness, com três perfis — Aluno, Professor e Admin.

O produto **já está integralmente especificado**: 19 requisitos funcionais, 10 não funcionais, 14 tabelas, 24 jornadas, 60 telas, matriz RBAC de 15 entidades × 3 perfis e 67 decisões numeradas (**D1**–**D67**). Nada disso é seu para decidir.

---

## 2. Fontes de verdade

### 2.1 Pré-requisito — antes de a sessão começar

Os dois arquivos abaixo vêm do repositório de specs e **precisam já estar no lugar** quando você começar:

| Copiar de | Para |
|---|---|
| `C:\Users\marco\GraziFit\Grazi-Specs\database\grazi_db_init_schema.sql` | `database/schema/grazi_db_init_schema.sql` |
| `C:\Users\marco\GraziFit\Grazi-Specs\docs\arquitetura-flutter-dart-postgres.md` | `docs/arquitetura.md` |

### 2.2 Primeira coisa a fazer: conferir

Antes de criar qualquer diretório, verifique que os dois arquivos existem nos destinos acima e que o SQL contém as 14 tabelas — `endereco`, `admin`, `professor`, `aluno`, `avaliacao`, `vinculo_professor_aluno`, `cronograma`, `cronograma_dia`, `aula`, `agendamento`, `exercicio`, `treino`, `treino_exercicio`, `historico_treino` — além de duas funções `plpgsql`, dois triggers e duas views.

**Se algum dos dois não estiver lá, pare e peça ao usuário.** Não procure o arquivo em outras pastas do disco, não baixe nada, não reconstrua o schema de memória e não deduza tabela alguma a partir deste documento. Sem o SQL original não há fonte de verdade — e sem fonte de verdade nada deve ser criado.

### 2.3 Ordem de autoridade

1. Instrução explícita do usuário
2. `database/schema/grazi_db_init_schema.sql` — o domínio de dados
3. `docs/arquitetura.md` — as decisões de arquitetura
4. Este documento

Em conflito entre fontes, **pare e pergunte**. Nunca escolha uma interpretação por conta própria.

---

## 3. Regras invioláveis

**R1 — O SQL é a fonte de verdade (D58).** Nenhuma tabela, coluna, constraint, índice, view ou função nasce em Dart. O Drift é camada de acesso tipada gerada a partir do schema existente. O fluxo `make-migrations` / `schemaVersion` / `stepByStep` **não é usado**. Se alguma construção não for suportada, o acesso àquela tabela desce para SQL direto no repository — o schema nunca é simplificado para caber na ferramenta.

**R2 — Fronteiras de import.** `backend/` nunca importa `package:flutter`. `app/` nunca importa `shelf` nem `drift_postgres`. `shared/` não importa nenhum dos dois.

**R3 — Uma tabela, um dono.** Só o repository da feature dona escreve na tabela. Ler tabela ou view de outra feature é livre; escrever em tabela alheia acontece só **service → service**.

**R4 — Não inventar.** Não crie entidade, campo, regra, endpoint ou tela que não esteja no schema ou em `docs/arquitetura.md`. Faltou algo? **Pare e pergunte.**

**R5 — Fora de escopo por decisão de produto.** Não existem e não devem ser adicionados: pagamentos, mensalidades, chat, notificações push, gamificação, feed social, ranking, carteira digital, wearables, upload de imagem, seletor de academia ou unidade. A ausência é deliberada.

**R6 — Dados fictícios.** Nenhum CPF, e-mail, telefone, senha ou dado de saúde real em qualquer lugar. Use `00000000001`, `@exemplo.test` e nomes genéricos.

**R7 — Não criar arquivo fora do que §4 autoriza.** Na dúvida sobre um arquivo, não crie: pergunte.

### 3.1 Skills e OpenSpec — já instalados neste repositório

O repositório traz `.claude/skills/` e `openspec/` prontos. **Não os recrie e não instale skill nova.**

**Três skills do projeto**, adaptadas para implementação — não são as versões do repositório de specs:

| Skill | Dispara quando |
|---|---|
| `fidelidade-manual-marca` | Qualquer decisão de UI. O Figma e as 60 molduras são fonte **executável**: implementar é reproduzir a moldura, não reinterpretá-la |
| `aprovacao-obrigatoria` | Antes de qualquer alteração estrutural — schema, dependência, endpoint, contrato, estrutura de pastas, decisão **D1**–**D67** ou **antecipação de fase** |
| `nao-inventar` | Sempre que faltar informação. Traz a lista das lacunas conhecidas do schema, que não devem ser contornadas |

**Seis skills base do OpenSpec:** `openspec-propose`, `openspec-apply-change`, `openspec-archive-change`, `openspec-explore`, `openspec-sync-specs`, `openspec-update-change`. Os comandos `opsx` estão em `.claude/commands/opsx/`. O CLI `openspec` 1.10.0 está instalado e no PATH.

**Como o OpenSpec é usado aqui.** `openspec/project.md` já existe e é o contexto permanente — leia antes de agir. Toda alteração estrutural nasce como change em `openspec/changes/`, com `proposal.md`, `design.md` e `tasks.md`, no mesmo formato das oito changes do repositório de specs. Decisões novas continuam a numeração **a partir de D68**. `openspec/specs/` fica vazio até haver capability consolidada.

**Duas skills foram deliberadamente deixadas de fora** — `frontend-design-distinct` e `grill-me`. A primeira orienta escolhas estéticas próprias, o que contradiz reproduzir um protótipo já aprovado; a segunda depende de uma skill externa não resolvida. **Não as instale.**


---

## 4. Escopo — Fase 1

### 4.1 Criar

- **A árvore de diretórios de §5**, por inteiro
- **`README.md` em cada uma das 10 pastas de feature**, dos dois lados, com jornadas e tabelas (§6)
- **`docs/guia-desenvolvimento.md`** — conforme §9. É o entregável principal desta fase
- **`.gitkeep`** nos diretórios que ficariam vazios

### 4.2 NÃO criar — sem exceção

| Não criar | Cabe a |
|---|---|
| Arquivos `.sql`, scripts de aplicação, `docker-compose.yml`, `.env.example` | Fase 2 |
| Migrations | Nenhuma fase — só existem após a primeira implantação (§7) |
| `pubspec.yaml`, `analysis_options.yaml`, qualquer `.dart`, CI, `Dockerfile`, seed do admin | Fase 3 |
| Tabelas Drift, DTOs, endpoints, telas, tokens | Fase 4 e além |

**Exceção — `app/` já existe.** O pacote Flutter do app já foi criado e ajustado fora desta sessão: `app/pubspec.yaml` (`name: grazifit_app`), `app/analysis_options.yaml`, `app/lib/main.dart` e `app/test/widget_test.dart`. Os dois últimos são template do `flutter create` e serão substituídos nas Fases 3 e 4.

**Não recrie `app/`, não rode `flutter create`, não apague nem edite esses arquivos nesta fase.** Apenas crie dentro dele os diretórios de §5 que ainda faltarem — `lib/core/...` e `lib/features/...`.

As plataformas mantidas são **`android` e `web`**: web existe só para facilitar a execução durante o desenvolvimento, e o produto é Android (Restr. 2). Não acrescente `ios`, `windows`, `linux` nem `macos`.

**Não rode `dart pub get`, `flutter create`, `build_runner` nem `docker`.** Nada é executado nesta fase.

Ao terminar, o repositório tem **pastas, READMEs e o guia de desenvolvimento**. Nada mais. É intencional: a estrutura é revisada antes de qualquer arquivo entrar.

### 4.3 As fases seguintes — cada uma só após aprovação explícita

| Fase | Entrega | Depende de |
|---|---|---|
| **1** — esta | Estrutura de pastas, READMEs das features, `docs/guia-desenvolvimento.md` | — |
| **2** | **Banco, Docker e Drift.** `docker-compose` só com o Postgres, `database/aplicar.sh`, tabela `schema_migracao`, `.env.example`, e o pacote `backend/` com **Drift configurado e provado contra o schema real** — `@DriftDatabase(tables: [])`, `MigrationStrategy` vazia (**D58**) e o teste dos seis pontos de verificação | Fase 1 |
| **3** | **Backend de pé.** `shared/pubspec.yaml`, `config.dart` com *fail fast*, pool, `/health`, log com id de requisição, `server.dart`, backend no `compose`, CI e **seed do admin** | Fase 2 |
| **4** | **Primeira fatia vertical:** `auth` / F-01, na ordem de §9.4 | Fase 3 |

**Por que o seed do admin fica na Fase 3 e não na 2.** `pgcrypto` oferece bcrypt via `crypt()`, mas **não oferece Argon2**. Como **D59** fixa `Argon2id(HMAC-SHA256(senha, SENHA_PEPPER))`, o hash só pode ser calculado por código — o seed é um **programa Dart**, não um arquivo `.sql`, e portanto depende do toolchain existir. Ele continua sendo serviço one-shot, versionado, e jamais executado no boot do backend (**D60**).

**Não antecipe fase.** O detalhamento de infraestrutura está em `docs/arquitetura.md` §10 e §11.

---

## 5. A árvore

Tudo abaixo é **diretório**, salvo os arquivos explicitados.

```
grazifit/
├── database/
│   ├── schema/                       # recebe grazi_db_init_schema.sql (copia de §2)
│   ├── migrations/                   # VAZIO nesta fase - ver §7
│   └── seed/                         # VAZIO nesta fase
│
├── .claude/                          # JA EXISTE - skills e comandos, ver §3.1
├── openspec/                         # JA EXISTE - project.md, changes/, specs/
│
├── docs/
│   ├── arquitetura.md                # copia de §2
│   └── guia-desenvolvimento.md       # produzir nesta fase - §9
│
├── shared/                           # Dart puro
│   └── lib/
│       ├── dtos/
│       └── erros/
│
├── backend/
│   ├── bin/
│   ├── lib/
│   │   ├── database/
│   │   ├── features/                 # 10 pastas, cada uma com README.md
│   │   └── shared/
│   │       ├── autorizacao/
│   │       ├── erros/
│   │       └── middleware/
│   └── test/
│
└── app/                              # JA EXISTE - pacote Flutter grazifit_app
    ├── android/  web/                # plataformas mantidas; nao acrescentar outras
    ├── pubspec.yaml                  # JA EXISTE - nao recriar
    ├── lib/
    │   ├── core/
    │   │   ├── design_system/
    │   │   │   ├── tokens/
    │   │   │   └── components/
    │   │   ├── state/
    │   │   ├── routing/
    │   │   └── network/
    │   └── features/                 # as mesmas 10, cada uma com README.md
    └── test/
```

No **backend**, os arquivos de cada feature ficam direto na pasta dela — `*_table.dart`, `*_repository.dart`, `*_service.dart`, `*_controller.dart` — e chegam da Fase 4 em diante. Não crie subpastas ali.

No **app**, cada feature recebe quatro subpastas: `data/`, `state/`, `screens/`, `widgets/`.

---

## 6. As 10 features

Cada pasta recebe um `README.md` curto declarando jornadas e tabelas.

| Pasta | Jornadas | Tabelas que possui |
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
| `inicio` | — (**D45**) | nenhuma — só compõe leitura |

As mesmas dez existem dos dois lados, com o mesmo nome. Feature que exista só em um lado é erro.

---

## 7. Banco de dados — o que saber, sem tocar

`database/schema/grazi_db_init_schema.sql` é o **estado atual** e a única fonte de verdade. Enquanto o sistema não estiver implantado, correção de schema é edição **naquele arquivo, no repositório de specs** — **não se cria migration**. `database/migrations/` só passa a valer a partir da primeira implantação e permanece vazia até lá.

**O versionamento é de SQL, não do Drift.** O Drift não cria tabela, não versiona e não migra — ele só lê e escreve dados com tipagem, e nem existe no projeto antes da Fase 3. Quem aplica é `aplicar.sh`; quem registra o que já foi aplicado é a tabela `schema_migracao`. Se um dia o Drift discordar do banco, quem está errado é o Drift.

O schema foi auditado e verificado contra PostgreSQL 18. Ele funciona. Mas tem **lacunas conhecidas**, e você precisa conhecê-las para não escrever código que dependa do que não existe.

### 7.1 O que o banco já garante

`avaliacao.imc` é coluna `GENERATED STORED` — a aplicação **lê**, nunca calcula (RF-03). O controle de vagas usa `FOR UPDATE` e é confiável sob concorrência. `uq_vinculo_aluno_ativo` garante no máximo um vínculo ativo por aluno. `ck_treino_origem` garante o XOR entre treino livre e personalizado. `ck_aula_cronograma_tipo` garante **D13**, e `ck_aula_personal_vagas` garante o teto de 1 a 3 de **D11**.

Erros chegam ao Dart com código utilizável: `GF001` a `GF004` nos triggers, `23505` com nome de constraint, `23514` com nome de domínio.

### 7.2 O que o banco NÃO garante — a aplicação cobre

| Regra | Origem | Situação |
|---|---|---|
| E-mail único entre `admin`, `professor` e `aluno` | **D61** | `uq_*_email` é por tabela. A verificação cruzada é da feature `pessoas` |
| Treino personalizado só para vínculo **ativo** | **D16** | Nenhuma constraint consulta `vinculo_professor_aluno` |
| Janela de 2 horas | **D2**, RNF-01 | Ausente por natureza. Ver §7.4 sobre fuso |
| `data_ultimo_acesso` gravado no login | **D23** | Sem trigger nem default. Se o login não gravar, o painel de inativos vê todos como inativos |
| Não agendar aula no passado | — | Sem `CHECK` |
| Duplicidade de agendamento com a mensagem certa | DoD S4 | O trigger de vagas é `BEFORE INSERT` e **mascara** `uq_agendamento_aluno_aula` em aula lotada. O Service pré-verifica antes do insert |

### 7.3 Ausências estruturais — não contorne, pergunte

O schema **não registra quem executou a ação** em três lugares, embora mais de um perfil possa executá-la:

- `agendamento` não diz **quem marcou presença** — **D5** dá isso a professor e admin
- `historico_treino` não diz **quem confirmou a execução** — **D29** dá isso a aluno e professor
- `avaliacao` não diz **quem registrou** — **D4** e **D37** dão isso aos três perfis

O contraste está na mesma base: `aula` registra a autoria do cancelamento com `id_professor_cancelou`, `id_admin_cancelou` e um XOR. A presença não tem equivalente.

**Se uma tarefa exigir saber quem agiu, pare e pergunte.** Não invente coluna nem infira pelo token da sessão.

Além disso, o schema **sabe criar e cancelar, mas não sabe arquivar**: `admin`, `treino` e `exercicio` não têm `status`. Um exercício usado em algum treino não pode ser removido (`ON DELETE RESTRICT`) nem desativado, e `uq_exercicio_nome` impede recriar com o mesmo nome. `admin` ainda não tem `data_cadastro` nem `data_ultimo_acesso`, e por isso fica fora de **D23**.

### 7.4 Tipos e fuso — o que vai morder

- **`NUMERIC` chega ao Dart como `String`**, não `double`. `peso`, `altura` e `imc` são texto. Converta explicitamente no DTO e **nunca recalcule** o que o banco calculou.
- `DATE` → `DateTime`; `TIME` → `Time` do `drift_postgres`.
- `aula.data` e `aula.hora_inicio` **não têm fuso**, enquanto `data_cancelamento`, `data_presenca` e `data_ultimo_acesso` são `TIMESTAMPTZ`. Calcular a janela de 2 horas exige combinar data + hora e assumir um fuso. **Declare o fuso adotado em um único lugar** e use apenas ele.
- A classe Drift precisa declarar **toda coluna `NOT NULL`**; omitir uma faz o insert falhar em runtime com `23502`.

---

## 8. Senhas (D59)

`senha_hash VARCHAR(255)` guarda a **string PHC inteira** do Argon2id — parâmetros, salt e hash. **Não existe e não deve ser criada coluna `salt`**: o salt é sorteado pelo Argon2id, vive dentro da string e é extraído dela na verificação.

**Nunca escreva código que tente recuperar uma senha.** Hash é via de mão única; a autenticação compara hash com hash. O fluxo de senha esquecida é **redefinição pelo admin** (F-24, **D20**).

**Pepper obrigatório.** `SENHA_PEPPER`, 32 bytes em base64, só no ambiente — nunca no banco, nunca no repositório. Construção: `Argon2id(HMAC-SHA256(senha, pepper))`. Sem a variável, o backend não sobe. O seed do admin usa o mesmo pepper. **Perder ou trocar o pepper invalida todas as senhas de uma vez** — registrar isso no `README.md` na Fase 2.

---

## 9. `docs/guia-desenvolvimento.md` — o entregável desta fase

Produza o documento a partir das regras abaixo. Elas **não são sugestões suas**: são decisões da arquitetura. Expanda com os caminhos reais criados na Fase 1, mas não acrescente regra nova nem altere as existentes.

### 9.1 Fatias verticais, nunca camadas horizontais

**Não** construa todos os repositories, depois todos os services, depois todos os controllers. Construa **uma feature de ponta a ponta** antes de começar a próxima.

A razão é prática: horizontal só entrega valor no fim e empurra todo erro de contrato para a integração final. Vertical entrega uma jornada funcionando por vez — que é como o roadmap está cortado, cada sprint fechando jornadas — e faz o erro de contrato aparecer na primeira fatia, quando ainda custa barato.

### 9.2 A ordem entre features é ditada pelas chaves estrangeiras

Não é preferência. Uma entidade não se constrói antes daquilo que referencia:

```
auth → pessoas → vinculos ─┐
         │                 ├→ treinos → historico
         │    exercicios ──┘
         └→ cronogramas → aulas → agendamentos
         └→ avaliacoes
```

`inicio` é a última: só compõe leitura do que as outras produzem.

### 9.3 Sim, autenticação primeiro — pela razão certa

Não porque "é a base", mas porque **toda feature seguinte precisa da identidade e do papel para decidir escopo**. Sem `auth` não há como testar RBAC, e RBAC é onde **D21** vive — o item que o roadmap classifica como risco de LGPD, não como defeito de interface.

Junto de `auth` nascem o middleware de identidade no backend e o guard de rota por papel no app. `auth` fica incompleta até a S2, quando F-24 fecha.

### 9.4 A ordem dentro de uma fatia

| # | Passo | Onde | Por que nesta posição |
|---|---|---|---|
| 1 | **DTO** | `shared/` | Único artefato que os dois lados compartilham. Definido primeiro, impede que backend e app divirjam |
| 2 | **Repository** | `backend/` | É onde constraint e trigger aparecem. Teste de integração contra **Postgres real** — mock aqui não prova nada |
| 3 | **Service** | `backend/` | Regra de negócio e escopo de autorização. Teste unitário com repository falso |
| 4 | **Controller + rota** | `backend/` | Só forma e DTO. Nenhuma regra, nenhuma permissão |
| 5 | **`data/`** | `app/` | Chamada HTTP e parse do DTO |
| 6 | **`state/`** | `app/` | Provider Riverpod devolvendo `AsyncState` |
| 7 | **`screens/`** | `app/` | Os cinco estados obrigatórios |

Isso responde à dúvida mais comum: **não se começa pela camada de negócio nem pela tela — começa-se pelo contrato.**

### 9.5 Comunicação entre app e backend

- **REST sobre HTTPS, JSON.** O contrato é sempre um DTO de `shared/`. Nenhum lado serializa mapa solto: se o app precisa de um campo, ele nasce no DTO.
- **Endpoints derivam das jornadas**, não de CRUD genérico, e pertencem à feature dona da tabela. A lista de endpoints **ainda não está especificada** — proponha por feature e submeta antes de implementar.
- **Erro:** toda resposta de erro usa `{ codigo, mensagem, campo? }` (**D64**). O app escolhe o texto **pelo código**, jamais pela mensagem.
- **Autorização:** o app **nunca** decide permissão. Pode ocultar o que o papel não usa, mas quem nega é o backend. Tela que some não é segurança.
- **Estado:** toda chamada devolve `AsyncState`. Nenhuma tela sem os cinco estados — RNF-04 vale para as 60.
- **Sem persistência local.** O app é 100% online (Restr. 3). Não introduza cache em disco nem banco local.
- **Sem polling global.** Só Agenda, Detalhe da aula e Chamada atualizam periodicamente; o resto atualiza ao focar a tela e após cada ação.

### 9.6 Definição de pronto de uma fatia vertical

- [ ] A jornada F-xx completa, do toque à gravação
- [ ] Constraint e trigger relevantes traduzidos em código de erro e mensagem ao usuário
- [ ] Os cinco estados na tela
- [ ] RBAC testado nos **três** perfis, incluindo o que deve ser negado
- [ ] Nenhuma escrita em tabela de outra feature
- [ ] Teste de integração contra Postgres real
- [ ] Nenhuma regra de negócio no Controller nem na tela

### 9.7 Antipadrões — a lista que evita furo de lógica

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

## 10. Convenções de nomenclatura (D67)

| Elemento | Convenção | Exemplo |
|---|---|---|
| Tabelas e colunas | pt-BR, `snake_case`, espelhando o banco | `vinculo_professor_aluno`, `id_aluno` |
| Classes de domínio | pt-BR, `PascalCase` | `Aluno`, `Aula`, `Agendamento` |
| Camadas e pastas técnicas | inglês | `features/`, `repository`, `service` |
| Arquivos | domínio pt-BR + papel em inglês | `aluno_repository.dart` |

---

## 11. Definição de pronto da Fase 1

- [ ] A árvore de §5 existe por inteiro
- [ ] As 10 pastas de feature existem **dos dois lados**, com `README.md` declarando jornadas e tabelas
- [ ] `database/migrations/` e `database/seed/` existem e estão **vazias**
- [ ] `docs/arquitetura.md` e `database/schema/grazi_db_init_schema.sql` foram copiados
- [ ] `docs/guia-desenvolvimento.md` cobre §9 por inteiro
- [ ] **Nenhum arquivo `.dart`, `.sql`, `.yaml` ou `.sh` foi criado**
- [ ] Nada foi executado — sem `pub get`, sem `build_runner`, sem `docker`
- [ ] A checagem abaixo **não retorna nada** — `app/`, `database/schema/` e `.claude/` são pré-existentes e ficam de fora:

```bash
find . -type f \( -name "*.dart" -o -name "*.sql" -o -name "*.yaml" -o -name "*.sh" \) \
  -not -path "./app/*" -not -path "./database/schema/*" -not -path "./.claude/*"
```

---

## 12. Quando parar e perguntar

Pare imediatamente, em vez de decidir, se:

- este documento divergir de `docs/arquitetura.md` ou do schema
- surgir necessidade de tabela, coluna ou regra que não existe no schema
- uma tarefa exigir saber **quem** marcou presença, confirmou execução ou registrou avaliação (§7.3)
- parecer necessário criar algo listado em §4.2 para a estrutura "funcionar"

O projeto tem 67 decisões registradas justamente para que nenhuma seja tomada dentro do código. Pergunta sem resposta registrada é **escopo novo** — e escopo novo não se resolve implementando.
