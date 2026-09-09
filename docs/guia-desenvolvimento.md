# Guia de Desenvolvimento — GraziFit

**Como se constrói uma feature neste repositório: em que ordem, em qual pasta e com qual critério de pronto.**

Este documento não decide nada. Ele registra decisões já tomadas em `docs/arquitetura.md` e no prompt de implementação, expandidas com os caminhos reais criados na Fase 1. Se algo aqui divergir do schema ou de `docs/arquitetura.md`, **eles vencem** — e a divergência é para ser reportada, não interpretada.

**Subir o banco, baixar dependências, rodar e testar: §11.**

## Ordem de autoridade

1. Instrução explícita do usuário
2. `database/schema/grazi_db_init_schema.sql` — o domínio de dados (**D58**)
3. `docs/arquitetura.md` — as decisões de arquitetura
4. Este documento — a ordem e o método de construção

Em conflito entre fontes, **pare e pergunte**. Nunca escolha uma interpretação por conta própria.

---

## 1. Fatias verticais, nunca camadas horizontais

**Não** construa todos os repositories, depois todos os services, depois todos os controllers. Construa **uma feature de ponta a ponta** antes de começar a próxima.

A razão é prática, não estética:

- Horizontal só entrega valor no fim, e empurra todo erro de contrato para a integração final.
- Vertical entrega uma jornada funcionando por vez — que é exatamente como o roadmap está cortado, cada sprint fechando jornadas — e faz o erro de contrato aparecer na primeira fatia, quando ainda custa barato.

Uma fatia vertical vai do DTO em `shared/lib/dtos/` até a tela em `app/lib/features/<feature>/screens/`, passando por repository, service e controller. Ela termina quando a jornada F-xx funciona do toque à gravação — ver §6.

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
| `inicio` | — (**D45**) | nenhuma — só compõe leitura |

**Uma tabela, um dono.** Só o repository da feature dona escreve na tabela. Ler tabela ou view de outra feature é livre; escrever em tabela alheia acontece só **service → service**, e existem exatamente duas escritas assim em todo o sistema — ambas coincidentes com os dois triggers do banco. Uma terceira é sinal de recorte errado e se discute antes de implementar.

---

## 3. Sim, autenticação primeiro — pela razão certa

Não porque "é a base", mas porque **toda feature seguinte precisa da identidade e do papel para decidir escopo**. Sem `auth` não há como testar RBAC, e RBAC é onde **D21** vive — o item que o roadmap classifica como risco de LGPD, não como defeito de interface.

Junto de `auth` nascem duas peças que não moram dentro da feature:

| Peça | Onde vive |
|---|---|
| Middleware de identidade (backend) | `backend/lib/shared/middleware/` |
| Guard de rota por papel (app) | `app/lib/core/routing/` |

`auth` fica **incompleta até a S2**, quando F-24 fecha.

---

## 4. A ordem dentro de uma fatia

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

No backend, os arquivos de uma feature ficam **direto na pasta dela**, sem subpastas. No app, cada feature tem as quatro subpastas `data/`, `state/`, `screens/` e `widgets/`.

### 4.1 Onde ficam as peças que atravessam features

| Peça | Caminho |
|---|---|
| DTOs — contrato único backend ⇄ app | `shared/lib/dtos/` |
| Códigos de erro do contrato | `shared/lib/erros/` |
| Acesso Drift gerado a partir do schema | `backend/lib/database/` |
| Ponto único de RBAC | `backend/lib/shared/autorizacao/` |
| Tradutor de erro do banco para código | `backend/lib/shared/erros/` |
| Middleware de identidade e log de requisição | `backend/lib/shared/middleware/` |
| `AsyncState<T>` e seus cinco estados | `app/lib/core/state/` |
| Rotas guardadas por papel e os três shells | `app/lib/core/routing/` |
| Cliente HTTP | `app/lib/core/network/` |
| Tokens do design system | `app/lib/core/design_system/tokens/` |
| Componentes portados do protótipo | `app/lib/core/design_system/components/` |

Shell e roteamento vivem em `core/`, fora de `features/`, porque cinco das oito abas compõem mais de uma feature — e o `Detalhe do aluno` do Professor atravessa quatro numa tela só.

---

## 5. Comunicação entre app e backend

- **REST sobre HTTPS, JSON.** O contrato é sempre um DTO de `shared/`. Nenhum lado serializa mapa solto: se o app precisa de um campo, ele nasce no DTO.
- **Endpoints derivam das jornadas**, não de CRUD genérico, e pertencem à feature dona da tabela. A lista de endpoints **ainda não está especificada** — proponha por feature e submeta antes de implementar.
- **Erro:** toda resposta de erro usa `{ codigo, mensagem, campo? }` (**D64**). O app escolhe o texto **pelo código**, jamais pela mensagem.
- **Autorização:** o app **nunca** decide permissão. Pode ocultar o que o papel não usa, mas quem nega é o backend. Tela que some não é segurança.
- **Estado:** toda chamada devolve `AsyncState`. Nenhuma tela sem os cinco estados — RNF-04 vale para as 60.
- **Sem persistência local.** O app é 100% online (Restr. 3). Não introduza cache em disco nem banco local.
- **Sem polling global.** Só Agenda, Detalhe da aula e Chamada atualizam periodicamente; o resto atualiza ao focar a tela e após cada ação.

---

## 6. Definição de pronto de uma fatia vertical

- [ ] A jornada F-xx completa, do toque à gravação
- [ ] Constraint e trigger relevantes traduzidos em código de erro e mensagem ao usuário
- [ ] Os cinco estados na tela
- [ ] RBAC testado nos **três** perfis, incluindo o que deve ser negado
- [ ] Nenhuma escrita em tabela de outra feature
- [ ] Teste de integração contra Postgres real
- [ ] Nenhuma regra de negócio no Controller nem na tela

---

## 7. Antipadrões — a lista que evita furo de lógica

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

## 8. Convenções de nomenclatura (**D67**)

| Elemento | Convenção | Exemplo |
|---|---|---|
| Tabelas e colunas | pt-BR, `snake_case`, espelhando o banco | `vinculo_professor_aluno`, `id_aluno` |
| Classes de domínio | pt-BR, `PascalCase` | `Aluno`, `Aula`, `Agendamento` |
| Camadas e pastas técnicas | inglês | `features/`, `repository`, `service` |
| Arquivos | domínio pt-BR + papel em inglês | `aluno_repository.dart` |

Com 14 tabelas, a convenção precisa estar escrita antes da primeira classe — não descoberta na terceira sprint.

---

## 9. Fronteiras de import

Verificáveis em lint, a partir da Fase 3:

- `backend/` nunca importa `package:flutter`.
- `app/` nunca importa `shelf` nem `drift_postgres`.
- `shared/` não importa nenhum dos dois.

---

## 10. Quando parar e perguntar

Pare imediatamente, em vez de decidir, se:

- este documento divergir de `docs/arquitetura.md` ou do schema
- surgir necessidade de tabela, coluna ou regra que não existe no schema
- uma tarefa exigir saber **quem** marcou presença, confirmou execução ou registrou avaliação — o schema não registra o autor dessas três ações, embora mais de um perfil possa executá-las
- parecer necessário antecipar uma fase para que a estrutura "funcione"

O projeto tem 67 decisões registradas justamente para que nenhuma seja tomada dentro do código. Pergunta sem resposta registrada é **escopo novo** — e escopo novo não se resolve implementando. Toda alteração estrutural nasce como change em `openspec/changes/`, com `proposal.md`, `design.md` e `tasks.md`; decisões novas continuam a numeração a partir de **D68**.

---

## 11. Comandos do dia a dia

Não há npm, Makefile nem gerenciador de SDK neste repositório. Dependências de Dart e Flutter são baixadas exclusivamente pelo **`pub`**, e cada pacote resolve as suas: `backend/` com `dart pub`, `app/` com `flutter pub`. `shared/` ainda não tem `pubspec.yaml` — é da Fase 3.

Os comandos abaixo são os que funcionam **hoje**. Comando de fase futura está marcado como tal e não deve ser inventado antes da hora.

### 11.1 Preparar o repositório do zero

| # | Comando | O que faz |
|---|---|---|
| 1 | `cp .env.example .env` | Cria o ambiente local. Preencher **`POSTGRES_PASSWORD`** e **`DATABASE_URL`** — nenhuma das duas tem default (**D65**) |
| 2 | `docker compose up -d` | Sobe o PostgreSQL 18 (serviço `banco`, container `grazifit-db`) |
| 3 | `bash database/aplicar.sh` | Aplica schema e migrations, em ordem e de forma idempotente |
| 4 | `cd backend && dart pub get` | Baixa as dependências do backend |
| 5 | `cd app && flutter pub get` | Baixa as dependências do app |

**Porta ocupada.** Se a máquina já tiver um PostgreSQL nativo na 5432, o container não sobe — ou pior, o Dart conecta no servidor errado e o erro aparece como corrupção de protocolo. Defina `POSTGRES_PORT=5433` no `.env` e reflita a mesma porta na `DATABASE_URL`. Dentro da rede do compose a porta continua sendo 5432.

**Windows.** `database/aplicar.sh` é bash — rode pelo Git Bash. Sem `psql` no host, o script usa o `psql` de dentro do próprio container automaticamente.

### 11.2 Dependências

| Comando | Onde | O que faz |
|---|---|---|
| `dart pub get` | `backend/` | Instala o que está no `pubspec.lock` |
| `flutter pub get` | `app/` | Idem, para o app |
| `dart pub outdated` | `backend/` | Lista o que tem versão mais nova — **só relata, não altera** |
| `flutter pub outdated` | `app/` | Idem |
| `dart pub deps` | qualquer um | Mostra a árvore de dependências resolvida |

**`pub upgrade` não é rotina aqui.** As dependências do backend estão **fixadas em versão exata** de propósito (`drift 2.34.4`, `drift_postgres 1.3.1`, `postgres 3.5.12`, `drift_dev 2.34.6`), verificadas contra este schema em PostgreSQL 18 — `dart pub upgrade` não move nenhuma delas, e é assim que deve ser. Acrescentar, remover ou trocar dependência em qualquer `pubspec.yaml` é **alteração estrutural**: propõe-se antes, não se executa (§10). Se o resolvedor trouxer algo diferente e quebrar, **reporte antes de contornar**.

### 11.3 Código gerado pelo Drift

`backend/lib/database/database.g.dart` é gerado a partir do schema. Regere sempre que `database.dart` ou o SQL mudar:

```bash
cd backend
dart run build_runner build --delete-conflicting-outputs
```

`dart run build_runner watch` regenera continuamente durante uma sessão de trabalho. O gerado nunca se edita à mão — o arquivo em `database/schema/` é a fonte de verdade (**D58**).

### 11.4 Rodar

| Alvo | Comando | Estado |
|---|---|---|
| Banco | `docker compose up -d` | Disponível |
| Banco — logs | `docker compose logs -f banco` | Disponível |
| Banco — parar | `docker compose down` | Disponível |
| App no Chrome | `cd app && flutter run -d chrome` | Disponível |
| App no Android | `cd app && flutter run -d <id>` (`flutter devices` lista os ids) | Disponível |
| Servidor backend | `dart run bin/server.dart` | **Fase 3** — `backend/bin/` só tem `.gitkeep`; o servidor, o `shelf` e o serviço de backend no compose ainda não existem |

**`docker compose down -v` apaga o volume `grazifit-data`** e com ele todos os dados. Depois disso, `bash database/aplicar.sh` precisa rodar de novo. Use apenas quando o objetivo for justamente zerar o banco.

### 11.5 Testar e analisar

| Comando | Onde | Observação |
|---|---|---|
| `dart test` | `backend/` | Exige o banco **de pé** e `DATABASE_URL` **no ambiente do processo** — o Dart não lê o `.env` enquanto o `config.dart` da Fase 3 não existir (**D65**) |
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

`database/schema/grazi_db_init_schema.sql` — 14 tabelas, 2 funções, 2 triggers, 2 views · `docs/arquitetura.md` §1 (**D58**), §3 (recorte de features), §5 (**D63**), §7 (**D64**), §8 (**D62**), §11 (**D66**), §12 (**D67**) · `openspec/project.md` — contexto permanente e ordem de autoridade.
