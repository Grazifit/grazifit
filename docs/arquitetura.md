# Arquitetura — GraziFit (Flutter + Backend Dart + PostgreSQL)

**Versão 2 · 03/09/2026** — substitui a versão 1, que descrevia um padrão genérico ilustrado com `tasks`/`users`. Esta versão é a **instância do GraziFit**: features, tabelas e fronteiras reais, derivadas das 24 jornadas e das 14 tabelas do schema.

**Contexto:** app mobile Android, 100% online, sem requisito offline (Restr. 3, RNF-04). Single-tenant (RNF-05). Três perfis com RBAC — Aluno, Professor, Admin.

---

## 0. Como ler este documento

Cada item é marcado com seu estatuto. A confusão entre padrão ilustrativo e decisão vigente foi o defeito da versão 1 e não deve se repetir.

| Marca | Significado |
|---|---|
| **✔ Firmada** | Decisão aprovada. Vale como regra. Alterar exige nova aprovação. |
| **◻ Pendente** | Ainda não decidida. A recomendação está escrita, mas **não** é a decisão. Nada deve ser implementado sobre um item pendente. |

Nomes de pastas, features e arquivos neste documento são **reais**, não exemplos.

---

## 1. Fonte de verdade do schema — ✔ Firmada (D58)

**O SQL é a fonte de verdade. O Dart orquestra, não define o banco.**

Isso confirma a ordem de autoridade de `openspec/project.md`, onde `database/` está acima das specs.

```
database/
├── schema/       # estado atual do schema (grazi_db_init_schema.sql)
└── migrations/   # migrations SQL numeradas, aplicadas em ordem
```

**Regras:**

1. Nenhuma alteração de schema nasce em Dart. Toda mudança é uma migration SQL numerada em `database/migrations/`.
2. O Drift entra como **camada de acesso tipada**, gerada a partir do schema existente. As classes Dart descrevem o subconjunto necessário para consultas tipadas — elas não criam, não versionam e não governam o banco.
3. O fluxo `make-migrations` / `schemaVersion` / `stepByStep` do Drift **não é usado** neste projeto.

**Por que:** o schema usa construções que não têm representação em classes Dart e que sustentam requisitos verificados na Definição de Pronto:

| Construção | Onde | Requisito que sustenta |
|---|---|---|
| `GENERATED ALWAYS AS ... STORED` | `avaliacao.imc` | RF-03 — a interface **lê** o IMC, não calcula (DoD S6) |
| `fn_valida_vagas_aula` + `FOR UPDATE` | trigger em `agendamento` | Teste crítico de concorrência (DoD S4) |
| `fn_valida_aula_cronograma` | trigger em `aula` | Coerência aula × cronograma (DoD S3) |
| `CREATE DOMAIN` | `dom_cpf`, `dom_email` | Validação de formato na borda do dado |
| `IDENTITY` | todas as PKs | — |
| `vw_aluno_medida_atual`, `vw_aula_ocupacao` | views | Evolução física (S6) e `Início` do Admin (**D45**) |

### 1.1 Verificado — ✔ Firmada

Spike executado contra PostgreSQL 18 com `drift` 2.34.4, `drift_postgres` 1.3.1 e `postgres` 3.5.12. O Drift opera sobre este schema sem exceção:

| Construção | Resultado |
|---|---|
| `IDENTITY` | select e insert tipados funcionam |
| `DOMAIN` (`dom_cpf`, `dom_email`) | lidos como texto, transparentes |
| `GENERATED ... STORED` (`avaliacao.imc`) | lido do banco: **22.86** |
| Views | `vw_aula_ocupacao` lida normalmente |
| SQLSTATE do trigger | **`GF001` visível em `ServerException.code`** |
| Constraint | `23505` com `constraintName` preenchido |

O item mais importante é o penúltimo: **o contrato de erro de §7 é implementável** — o código do trigger chega ao Dart.

**Três regras que decorrem do spike:**

1. **`NUMERIC` chega como `String`**, não `double`. Peso, altura e IMC são texto. A conversão é explícita no DTO — nunca implícita, e nunca recalculando o que o banco já calculou (RF-03).
2. **Coluna `DATE` exige `customType(PgTypes.date)`.** `dateTime()` **quebra**: o Drift a trata como inteiro, e falha na leitura com `FormatException` e na escrita com `42804 ... is of type date but expression is of type bigint`. Atinge oito colunas do schema. `TIMESTAMPTZ` usa `dateTime()` normalmente.
3. **Declarar toda coluna `NOT NULL`.** O Drift só enxerga o que a classe Dart declara; omitir uma coluna obrigatória faz o insert falhar em runtime com `23502`.

`MigrationStrategy` com `onCreate` e `onUpgrade` vazios é o que mantém o Drift fora da criação do schema.

---

## 2. Camadas — ✔ Firmada

```
Controller (HTTP + DTO) → Service (regra de negócio) → Repository (Drift/SQL) → PostgreSQL
```

| Camada | Responsabilidade | O que nunca faz |
|---|---|---|
| Controller | Entrada HTTP, valida forma, monta DTO de resposta | Regra de negócio; decisão de permissão |
| Service | Regra de negócio; escopo de autorização | Falar com o banco diretamente |
| Repository | Única camada que conversa com Drift/Postgres | Conhecer HTTP ou perfil de usuário |

---

## 3. Recorte de features — ✔ Firmada

### 3.1 As três regras do recorte

**R1 — Feature é domínio, nunca perfil.** Nove telas são compartilhadas entre perfis com variação declarada (**D35**). Recortar por perfil as triplicaria e espalharia **D21** por três lugares. Perfil é parâmetro; domínio é fronteira.

**R2 — Uma tabela, um dono.** Só o repository da feature dona escreve na tabela.

**R3 — Leitura atravessa, escrita não.** Ler tabela ou view de outra feature é livre. Escrever em tabela alheia só **service → service**.

### 3.2 As 10 features

| Feature | Jornadas | Tabelas que possui |
|---|---|---|
| `auth` | F-01, F-24 | — (ver §6) |
| `pessoas` | F-02, F-09, F-16, F-23 | `aluno`, `professor`, `admin`, `endereco` |
| `vinculos` | F-13, F-17 | `vinculo_professor_aluno` |
| `avaliacoes` | F-08, F-15 | `avaliacao` |
| `cronogramas` | F-18, F-19 | `cronograma`, `cronograma_dia` |
| `aulas` | F-10, F-12, F-20 | `aula` |
| `agendamentos` | F-03, F-04, F-05, F-11 | `agendamento` |
| `exercicios` | F-21 | `exercicio` |
| `treinos` | F-06, F-07, F-14, F-22 | `treino`, `treino_exercicio`, `historico_treino` |
| `inicio` | — (**D45**) | nenhuma — só compõe |

Cobertura fechada: **24 de 24 jornadas, 14 de 14 tabelas**, sem sobreposição e sem órfão.

**Views (leitura compartilhada):** `vw_aluno_medida_atual` → `avaliacoes`. `vw_aula_ocupacao` → lida por `aulas`, `agendamentos` e `inicio`.

### 3.3 Fusões deliberadas

- **`avaliacoes` é uma só, com três portas de entrada** — aluno auto-declarando (**D4**), professor pelo `Detalhe do aluno`, admin pelo `Form aluno` (**D37**). Mesma regra **D6** de sobrescrita do dia. Três telas, uma regra, uma feature.
- **`treino` livre e personalizado não se separam** — `ck_treino_origem` é um XOR na mesma tabela.
- **`historico_treino` fica dentro de `treinos`** — **D29** amarra as duas: a confirmação de execução é o que gera o histórico. A feature atravessa S5 e S6, e isso é esperado (§3.7).
- **`Chamada` (F-11) fica em `agendamentos`, não em `aulas`** — escreve `agendamento.status` e `data_presenca`. Quem escreve, possui.
- **`endereco` não é feature** — nenhuma jornada é sobre endereço; é sub-form opcional de aluno e professor (**D18**).

### 3.4 Dependências

```
auth ──▶ (todas)

pessoas ──▶ vinculos ──▶ treinos (D16)
   │            ├──▶ avaliacoes (escopo Professor)
   │            └──▶ pessoas/inativos (escopo Professor)
   │
   └──▶ cronogramas ──▶ aulas ──▶ agendamentos

exercicios ──▶ treinos ──▶ treinos/historico

inicio ◀── aulas + pessoas   (somente leitura)
```

### 3.5 As duas únicas escritas entre features

| Origem | Destino | Jornada | O que protege |
|---|---|---|---|
| `CronogramaService.gerarAulas` | `AulaService.criarEmLote` | F-19 (**D8**) | `trg_valida_aula_cronograma`, `uq_aula_professor_horario` |
| `AulaService.cancelar` | `AgendamentoService.cancelarEmCascata` | F-12 (**D9**) | coerência de `ck_aula_cancelamento` com os agendamentos |

Em todo o sistema existem **duas** escritas entre features, e ambas coincidem com os dois triggers do banco. O domínio é naturalmente pouco acoplado — a arquitetura só precisa não estragar isso. Qualquer terceira escrita entre features é sinal de recorte errado e deve ser discutida antes de implementada.

### 3.6 `vinculos` é o resolvedor de escopo

Quatro features precisam da resposta *"este professor pode agir sobre este aluno?"*: `treinos` (**D16**), `avaliacoes`, `pessoas`/inativos e `agendamentos` (`R*` vinculados).

`VinculoService` expõe **uma** operação de escopo, consumida por todas. Sem isso, `uq_vinculo_aluno_ativo` vira quatro interpretações.

### 3.7 Feature não coincide com sprint

| Sprint | Abre | Fecha |
|---|---|---|
| S1 | `auth` (F-01), shell + rotas, `inicio` (stub) | — |
| S2 | `pessoas`, `vinculos` | `auth` (F-24), `vinculos` |
| S3 | `cronogramas`, `aulas` | `cronogramas` |
| S4 | `agendamentos` (F-03/04/05) | `aulas` |
| S5 | `exercicios`, `treinos` (F-14/22), `agendamentos` (F-11) | `agendamentos`, `exercicios` |
| S6 | `treinos` (F-06/07), `avaliacoes` | `treinos`, `avaliacoes`, `inicio` |
| S7 | nenhuma — sprint de entrega | — |

`auth`, `agendamentos` e `treinos` atravessam duas sprints cada. Isso é sadio, mas precisa estar visível: sprint com feature aberta **não** é sprint com pendência, desde que a coluna "Fecha" seja respeitada.

**Atenção — `Início` do Admin:** a DoD da S1 exige que os três perfis caiam na própria tela-raiz, e a raiz do Admin é `Início`, que lê `vw_aula_ocupacao` (**D45**). Não existe `aula` antes da S3 nem painel de inativos antes da S2. `inicio` nasce na S1 **como stub com empty state declarado** — nunca como tela vazia — e só fecha na S6.

### 3.8 Aba compõe feature; não a espelha

| Perfil | Aba | Features que compõe |
|---|---|---|
| Aluno | Agenda ⇄ Meus agendamentos | `agendamentos` (lê `aulas`) |
| Aluno | Treinos · Evolução · Perfil | `treinos` · `avaliacoes` · `pessoas` |
| Professor | Agenda | `aulas` (lê `agendamentos`) |
| Professor | Alunos | `vinculos` + `pessoas` + `treinos` + `avaliacoes` |
| Admin | Início | `inicio` |
| Admin | Pessoas | `pessoas` + `vinculos` |
| Admin | Aulas | `aulas` + `cronogramas` |
| Admin | Treinos | `treinos` + `exercicios` |

Cinco das oito abas compõem mais de uma feature — e o `Detalhe do aluno` do Professor atravessa quatro numa tela só. Por isso shell e roteamento vivem em `core/`, fora de `features/`.

---

## 4. Estrutura do monorepo — ✔ Firmada

```
grazifit/
├── database/
│   ├── schema/
│   └── migrations/
│
├── shared/                       # Dart puro — sem Flutter, sem shelf
│   └── lib/
│       ├── dtos/                 # contrato único backend ⇄ app
│       └── erros/                # códigos de erro (§7)
│
├── backend/
│   ├── bin/server.dart
│   ├── lib/
│   │   ├── database/             # acesso Drift gerado a partir do schema
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── pessoas/
│   │   │   ├── vinculos/
│   │   │   ├── avaliacoes/
│   │   │   ├── cronogramas/
│   │   │   ├── aulas/
│   │   │   ├── agendamentos/
│   │   │   ├── exercicios/
│   │   │   ├── treinos/
│   │   │   └── inicio/
│   │   ├── shared/
│   │   │   ├── autorizacao/      # ponto único de RBAC (§5)
│   │   │   ├── erros/
│   │   │   └── middleware/
│   │   └── router.dart
│   └── test/
│
└── app/
    └── lib/
        ├── core/
        │   ├── design_system/
        │   │   ├── tokens/       # 48 variáveis, 8 estilos de texto, 3 elevações
        │   │   └── components/   # os 21 conjuntos portados do Figma
        │   ├── state/            # AsyncState<T> (§8)
        │   ├── routing/          # rotas guardadas por papel + os 3 shells (D34)
        │   └── network/
        └── features/             # as mesmas 10, espelhadas
```

**Cada feature do backend contém:** `*_table.dart` (quando aplicável) · `*_repository.dart` · `*_service.dart` · `*_controller.dart`.

**Cada feature do app contém:** `data/` · `state/` · `screens/` · `widgets/`.

**Regras de fronteira — ✔ Firmada:**

- `backend/` nunca importa `package:flutter`.
- `app/` nunca importa `shelf` nem `drift_postgres`.
- `shared/` não importa nenhum dos dois.
- `features/` tem o mesmo nome dos dois lados. Uma feature que existe só em um lado é sinal de recorte errado.

---

## 5. Autorização — ✔ Firmada (D63)

Dois pontos, e só eles.

| Ponto | Pergunta que responde | O que nunca faz |
|---|---|---|
| Middleware | *Quem é e qual o papel?* | Decidir permissão |
| Service | *Pode esta operação?* e *sobre este registro?* | Conhecer HTTP |

O middleware autentica, resolve o papel e injeta a identidade no contexto da requisição. O Service decide, e em **duas perguntas separadas**:

1. **Este perfil pode esta operação?** — resolvido contra a matriz RBAC (`01-mapeamento` §5) escrita como tabela declarativa, não como `if` espalhado.
2. **Sobre este registro?** — escopo `próprio` / `vinculado` / `total`. Escopo vinculado sempre via `VinculoService` (§3.6).

Nenhuma decisão de permissão em Controller.

### 5.1 D21 não é regra de tela

A DoD da S2 exige que a tela **declare a ausência, não esconda o campo**. Logo `restricao_medica` e `observacao_saude` **não podem existir no payload** destinado ao admin: um campo que chega ao cliente e é ocultado na renderização já vazou.

Consequência: **DTOs distintos por perfil**, não um DTO comum com campos anulados.

### 5.2 A matriz vira teste

As 15 entidades × 3 perfis da matriz RBAC são cobertas por teste automatizado. O roadmap classifica o vazamento de dado clínico como incidente de LGPD, não como defeito de interface — checklist não é garantia suficiente.

---

## 6. Autenticação e identidade

### 6.1 Hash de senha — ✔ Firmada (D59)

**Argon2id, com pepper de aplicação. Não existe coluna `salt`.**

`senha_hash VARCHAR(255)` guarda a **string PHC completa** — algoritmo, parâmetros, salt e hash, cerca de 100 caracteres:

```
$argon2id$v=19$m=65536,t=3,p=4$<salt>$<hash>
```

O salt é sorteado pelo Argon2id a cada senha e vive dentro dessa string; a verificação o extrai de lá. Uma coluna separada guardaria o mesmo valor num segundo lugar e, se as duas cópias divergissem, o login falharia silenciosamente — o sistema diria "senha incorreta", não "salt divergente".

**Hash é via de mão única.** Nada no sistema descriptografa uma senha, com ou sem salt. É por isso que **F-24** é *redefinição* pelo admin e **D20** não prevê recuperação: a senha antiga é irrecuperável por construção, e é isso que sustenta **RNF-08** — nunca exibida, nunca reexibida.

**Pepper.** Segredo único da aplicação, em `SENHA_PEPPER`, **fora do banco**. Construção: `Argon2id(HMAC-SHA256(senha, pepper))` — o HMAC vincula o pepper criptograficamente e neutraliza limite de comprimento da senha.

| Regra do pepper | |
|---|---|
| Geração | 32 bytes aleatórios em base64, sorteado **uma vez** na vida do projeto |
| Onde vive | `.env` e gerenciador de segredos. Nunca no repositório, nunca no banco |
| Ausência | O backend **não sobe** — fail fast (**D65**) |
| Seed do admin | Usa o mesmo pepper (**D60**), senão a conta semeada não autentica |
| Perda ou troca | **Invalida todas as senhas de uma vez**, sem conserto além de redefinir todos. Risco assumido explicitamente |

### 6.2 Seed do admin — ✔ Firmada (D60)

Não existe tela de criação de admin (**D32**). A conta é semeada por script versionado, executado **ao final da S1**, como serviço one-shot — nunca no boot do backend.

**O seed é um programa Dart, não um arquivo `.sql`.** `pgcrypto` oferece bcrypt via `crypt()`, mas não oferece Argon2; com **D59** exigindo `Argon2id(HMAC-SHA256(senha, pepper))`, o hash só pode ser calculado em código. Senha e pepper vêm do ambiente.

### 6.3 Resolução de identidade — ✔ Firmada (D61)

`admin`, `professor` e `aluno` são três tabelas com `senha_hash` próprio, e `uq_*_email` é **por tabela** — nada no banco impede o mesmo e-mail existir em duas delas. Como **D19** tornou o e-mail a credencial de login:

**O e-mail é único entre as três tabelas somadas.** A verificação pertence à feature `pessoas`, no cadastro (F-16), e ocorre antes do erro do banco. O login tem sempre uma resposta única — um e-mail, um perfil — e nenhuma tela é acrescentada ao protótipo.

**Consequência aceita:** a mesma pessoa não pode ser professor e aluno com o mesmo e-mail. Coerente com single-tenant (RNF-05).

**Nota para a S2 — ◻ Pendente:** essa unicidade cruzada não existe no schema; não há constraint que a garanta. Enquanto for validação de aplicação, dois cadastros simultâneos podem furá-la. Se isso for considerado risco, o reforço é uma constraint no banco — decisão separada, sem impacto no fluxo de login.

---

## 7. Contrato de erro — ✔ Firmada (D64)

Envelope `{ codigo, mensagem, campo? }`, com `codigo` legível por máquina. Um tradutor único no `error_handler` mapeia a falha do banco para o código; nenhuma feature traduz por conta própria.

**A UI escolhe o texto pelo código, jamais pela string de mensagem do Postgres.** Quatro Definições de Pronto exigem "mensagem e não exceção crua"; sem contrato, cada sprint reinventa o mapeamento.

### 7.1 Mapa de códigos

| Origem no banco | SQLSTATE | Código | Jornada |
|---|---|---|---|
| `fn_valida_vagas_aula` — sem vagas | `GF001` | `AULA_SEM_VAGAS` | F-04 (DoD S4) |
| `fn_valida_vagas_aula` — aula inativa | `GF002` | `AULA_INATIVA` | F-04 |
| `fn_valida_aula_cronograma` — categoria | `GF003` | `AULA_CATEGORIA_DIVERGENTE` | F-19 (DoD S3) |
| `fn_valida_aula_cronograma` — professor | `GF004` | `AULA_PROFESSOR_DIVERGENTE` | F-19 |
| `uq_agendamento_aluno_aula` | `23505` | `AGENDAMENTO_DUPLICADO` | F-04 |
| `uq_aula_professor_horario` | `23505` | `HORARIO_CONFLITANTE` | F-20 (DoD S3) |
| `uq_vinculo_aluno_ativo` | `23505` | `VINCULO_JA_ATIVO` | F-17 (DoD S2) |
| `uq_avaliacao_aluno_data` | `23505` | `AVALIACAO_JA_REGISTRADA` | F-15 (**D6**) |
| `uq_aluno_cpf` / `uq_aluno_email` | `23505` | `CPF_EM_USO` / `EMAIL_EM_USO` | F-16 (DoD S2) |

Violação de constraint chega com SQLSTATE `23505` e **nome da constraint** — o nome é a chave do mapeamento, e é estável.

### 7.2 Os triggers precisavam de `ERRCODE` próprio

As duas funções plpgsql levantavam exceção sem cláusula `ERRCODE`, e portanto todas retornavam o mesmo `P0001`: *sem vagas*, *aula inativa*, *categoria divergente* e *professor divergente* eram indistinguíveis exceto pelo texto da mensagem. O contrato obrigaria exatamente o que ele proíbe.

**Corrigido e verificado** contra PostgreSQL 18. A alteração entrou em `database/grazi_db_init_schema.sql`, no corpo das duas funções — não como migration, porque o sistema não está implantado e não há base a migrar. Apenas o corpo mudou: nenhuma tabela, constraint, índice ou trigger foi alterado, e a lógica permanece idêntica, incluindo o `FOR UPDATE`.

Antes da correção os quatro erros retornavam `P0001`; agora retornam `GF001`–`GF004`. A classe `GF` não é usada pelo padrão SQL nem pelo PostgreSQL, e o código chega ao Dart em `ServerException.code` (§1.1).

### 7.3 Violação de domínio

Verificado: CPF ou e-mail fora do formato não chega como `23505`, e sim como **`23514`** com nome de constraint `dom_cpf_check` ou `dom_email_check`. São os `CREATE DOMAIN` do schema, e entram no mapa como `CPF_INVALIDO` e `EMAIL_INVALIDO`.

### 7.4 O trigger de vagas mascara a duplicidade

Verificado: `trg_valida_vagas_aula` é `BEFORE INSERT` e dispara **antes** de `uq_agendamento_aluno_aula` ser avaliada. Um aluno que tenta reagendar uma aula **lotada** recebe `AULA_SEM_VAGAS`, não `AGENDAMENTO_DUPLICADO`. Em aula com vaga livre, a constraint responde corretamente.

A DoD da S4 exige "lotada" distinguível dos demais bloqueios. Portanto o `AgendamentoService` **verifica agendamento existente antes do insert** — mesmo padrão que a S2 usa para `uq_aluno_cpf`. O banco continua sendo a última linha de defesa, não a primeira mensagem.

---

## 8. Estado e roteamento do app — ✔ Firmada (D62)

**Riverpod** para gerência de estado. **`go_router`** para roteamento, com guard por papel.

`AsyncState<T>` vive em `core/state/` e tem cinco estados — `carregando`, `vazio`, `erro`, `sem conexão`, `dados`. O `AsyncValue` do Riverpod já cobre carregando/erro/dados; `vazio` e `sem conexão` são a extensão deste projeto.

RNF-04 exige estado sem conexão em **toda** tela que carrega dados. São 60 telas: resolvido uma vez em `core/`, ou 60 vezes à mão.

O guard do `go_router` lê o papel resolvido por `auth` (§6) e é o que sustenta a DoD da S1 — os três perfis caindo cada um na própria tela-raiz, com os três shells parametrizados (**D34**).

---

## 9. Sincronização entre usuários

### 9.1 Decisão vigente — ✔ Firmada (versão 1)

Polling: o cliente repete a chamada HTTP em intervalo curto (5–10s).

### 9.2 Revisão proposta — ◻ Pendente

Polling **por tela**, não global:

| Tela | Intervalo | Por quê |
|---|---|---|
| Agenda (Aluno), Detalhe da aula | ~20s | ocupação muda entre usuários |
| Chamada | ~15s enquanto aberta | dois perfis marcam presença (**D5**) |
| Todas as demais | nenhum | atualiza ao focar a tela e após cada ação |

Concorrência de vaga é resolvida pelo trigger com `FOR UPDATE`, **não** por polling. Das 60 telas, três se beneficiam de atualização periódica; aplicar 5–10s às outras 57 é carga sem contrapartida.

---

## 10. Configuração e execução — ✔ Firmada (D65)

Fecha o M2.4 do roadmap.

**`docker-compose.yml`** — Postgres 18 + backend. O Postgres tem healthcheck e o backend só sobe depois dele. A inicialização aplica `database/schema/` e em seguida `database/migrations/` em ordem numérica — nunca schema gerado por código (**D58**).

**O seed do admin (D60) é serviço one-shot separado**, jamais executado no boot do backend: no boot, reexecutaria a cada restart e viraria caminho silencioso de criação de conta privilegiada.

**`config.dart`** — variáveis de ambiente tipadas com *fail fast*: falta variável, o processo não sobe. Nenhum default silencioso para segredo. `.env.example` versionado; `.env` nunca.

**Pool de conexões** — declarado em config, não fixado em código. Ponto de partida de 10 por instância, contra o `max_connections` padrão de 100 do Postgres. A regra que importa é a negativa: **nunca uma conexão por requisição**.

**`/health`** verifica a conexão com o banco, não apenas se o processo está vivo — a S7 depende disso para a hospedagem. **Log estruturado** com id de requisição propagado desde o middleware.

---

## 11. Testes — ✔ Firmada (D66)

Três níveis:

| Nível | Contra o quê | Cobre |
|---|---|---|
| Unitário | Service com repository falso | Regra de negócio pura — janela de 2h (**D2**), **D16** |
| Integração | **Postgres real em container, do mesmo SQL de `database/`** | Constraints, triggers, views, coluna gerada |
| Concorrência | Postgres real, clientes paralelos | Teste crítico da S4 |

O container de teste sobe do mesmo schema de produção — é a única forma de o teste enxergar `trg_valida_vagas_aula` e `avaliacao.imc`. É o que **D58** paga.

Testes rodam em transação com rollback, **exceto** os de concorrência, que precisam de commits reais para o `FOR UPDATE` significar alguma coisa.

**O teste da S4:** N clientes disputando a última vaga em paralelo resultam em exatamente uma reserva; as demais falham com `GF001` traduzido em `AULA_SEM_VAGAS` (§7).

CI roda build, lint e testes a cada push, desde a S1.

---

## 12. Convenções de nomenclatura — ✔ Firmada (D67)

| Elemento | Convenção | Exemplo |
|---|---|---|
| Tabelas e colunas | pt-BR, `snake_case` — espelha o banco | `vinculo_professor_aluno`, `id_aluno` |
| Classes de domínio | pt-BR, `PascalCase` | `Aluno`, `Aula`, `Agendamento` |
| Camadas e pastas técnicas | inglês | `features/`, `repository`, `service` |
| Arquivos | domínio pt-BR + papel em inglês | `aluno_repository.dart` |

Com 14 tabelas, a convenção precisa estar escrita antes da primeira classe — não descoberta na terceira sprint.

---

## 13. Decisões pendentes — consolidado

| § | Item | Bloqueia |
|---|---|---|
| 6.3 | Reforço da unicidade cruzada de e-mail no banco | S2 — opcional, não bloqueia F-01 |
| — | Demais correções de schema — ver `openspec/changes/08-arquitetura-tecnica/auditoria-schema.md` §6 | S2 a S5, por prioridade |
| 9.2 | Polling por tela | S4 |

---

## Rastreabilidade

`openspec/project.md` (ordem de autoridade) · `database/grazi_db_init_schema.sql` (14 tabelas, 2 views, 2 triggers) · `01-mapeamento/design.md` §5 (RBAC), §6 (F-01 a F-24) · `02-arquitetura/design.md` §2–4 (árvores), §5 (**D35**), §7 (jornadas) · `docs/roadmap-desenvolvimento.md` (7 sprints).

Decisões novas introduzidas por este documento: **D58** (SQL como fonte de verdade), **D59** (Argon2id com pepper), **D60** (seed do admin), **D61** (e-mail único entre as três tabelas), **D62** (Riverpod + `go_router`), **D63** (autorização em dois pontos, DTO por perfil), **D64** (contrato de erro com código e `ERRCODE` próprio nos triggers), **D65** (configuração e execução), **D66** (testes contra Postgres real), **D67** (convenções de nomenclatura).

Registradas em `openspec/changes/08-arquitetura-tecnica/design.md`.
