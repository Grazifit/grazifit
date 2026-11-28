# GraziFit
 
Aplicativo mobile (Flutter, foco em Android) para gestão de uma academia: alunos, professores, aulas, treinos, avaliações físicas e administração.
 
O sistema é **single-tenant**, **100% online** (sem requisito offline) e tem três perfis com controle de acesso por papel (RBAC): **Aluno**, **Professor** e **Admin**.
 
---
 
## Sumário
 
- [O que o sistema faz](#o-que-o-sistema-faz)
- [Stack](#stack)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Como rodar](#como-rodar)
- [Variáveis de ambiente](#variáveis-de-ambiente)
- [Seed do admin](#seed-do-admin)
- [Testes e análise estática](#testes-e-análise-estática)
- [API](#api)
- [Arquitetura em resumo](#arquitetura-em-resumo)
- [Estado atual das features](#estado-atual-das-features)
- [Fora de escopo](#fora-de-escopo)
- [Contribuindo](#contribuindo)
- [Documentação](#documentação)
---
 
## O que o sistema faz
 
| Perfil | O que consegue fazer |
|---|---|
| **Aluno** | Ver a agenda e agendar/cancelar aulas (com antecedência mínima de 2h), acompanhar treinos, registrar medidas e ver a evolução física, editar o perfil |
| **Professor** | Ver a própria agenda e o detalhe das aulas, fazer a chamada, acompanhar seus alunos, montar treinos e registrar avaliações |
| **Admin** | Gerenciar pessoas (alunos, professores), aulas, cronogramas, biblioteca de exercícios, treinos livres e acompanhar o painel de início |
 
Dado clínico do aluno (`restricao_medica`, `observacao_saude`) **nunca** chega ao payload do admin: cada perfil recebe um DTO próprio.
 
## Stack
 
| Camada | Tecnologia |
|---|---|
| App | Flutter / Dart, Riverpod (estado), go_router (rotas com guard por papel), `http` |
| Backend | Dart, shelf + shelf_router, Drift + drift_postgres |
| Banco | PostgreSQL 18 (SQL puro é a fonte de verdade do schema) |
| Autenticação | JWT (HS256, 1 h) com sessão persistida no banco; senhas com Argon2id + pepper |
| Infra de dev | Docker Compose |
| Processo | OpenSpec (changes versionadas), Jira (chave `GRAZ`), Figma |
 
## Estrutura do repositório
 
Monorepo com quatro raízes irmãs:
 
```
grazifit/
├── database/      # SQL puro: schema, migrations e aplicar.sh
│   ├── schema/        # grazi_db_init_schema.sql (estado atual do schema)
│   └── migrations/    # migrations numeradas (001, 002, 003...)
├── shared/        # Dart puro: DTOs e códigos de erro compartilhados
│   └── lib/{dtos,erros}/
├── backend/       # API HTTP em Dart
│   ├── bin/           # server.dart e seed_admin.dart
│   ├── lib/
│   │   ├── config/        # variáveis de ambiente tipadas (fail fast)
│   │   ├── database/      # conexão Drift (não é camada de repositório)
│   │   ├── features/      # as 10 features
│   │   └── shared/        # autorização, erros, middleware, limitador
│   └── test/
├── app/           # Aplicativo Flutter
│   └── lib/
│       ├── core/          # design system, rotas, estado, rede, utilitários
│       ├── features/      # as mesmas 10 features, espelhadas
│       └── dev/           # menu "Telas (DEV)"
├── docs/          # arquitetura, guia de desenvolvimento, coleção da API
├── openspec/      # contexto permanente e changes
└── docker-compose.yml
```
 
**Fronteiras de import** (verificáveis em lint):
 
- `backend/` nunca importa `package:flutter`
- `app/` nunca importa `shelf` nem `drift_postgres`
- `shared/` não importa nenhum dos dois
### As 10 features
 
`auth` · `pessoas` · `vinculos` · `avaliacoes` · `cronogramas` · `aulas` · `agendamentos` · `exercicios` · `treinos` · `inicio`
 
Elas existem com o **mesmo nome** no `backend/` e no `app/`. Feature é domínio, não perfil. Cada tabela tem um único dono: só o repository da feature dona escreve nela.
 
## Como rodar
 
### Pré-requisitos
 
- [Docker](https://docs.docker.com/get-docker/) com Docker Compose
- Para rodar backend/app **fora** do Docker: Dart SDK `^3.13` e Flutter correspondente
### Caminho padrão (Docker)
 
```bash
# 1. Criar o ambiente local e preencher as variáveis obrigatórias
cp .env.example .env
 
# 2. Subir tudo (banco + migrations + backend) e recompilar a cada alteração
docker compose up --build --watch
```
 
O compose sobe, nesta ordem:
 
| Serviço | O que faz | Porta no host |
|---|---|---|
| `banco` | PostgreSQL 18 (volume `grazifit-data`) | `127.0.0.1:${POSTGRES_PORT}` |
| `migrate` | Aplica schema e migrations (`database/aplicar.sh`) e termina; é idempotente | — |
| `backend` | API Dart; só sobe depois das migrations; healthcheck em `GET /health` | `127.0.0.1:${BACKEND_PUBLIC_PORT}` |
| `app-web` | Flutter Web, **opcional** (apenas com `COMPOSE_PROFILES=web`) | `127.0.0.1:${WEB_PORT}` |
 
Todas as portas são publicadas apenas em `127.0.0.1`.
 
Para subir o app web junto, defina `COMPOSE_PROFILES=web` no `.env`. Deixe vazio para subir só banco, migrations e backend.
 
> **Atenção:** o primeiro build do `app-web` baixa o SDK do Flutter (imagem de ~2 a 3 GB, 15 a 20 min). O custo é pago uma vez por máquina.
 
### Parar e zerar
 
```bash
docker compose down        # para tudo e mantém os dados
docker compose down -v     # para tudo e APAGA o volume do banco
```
 
### Rodando fora do Docker
 
```bash
docker compose up -d banco       # só o PostgreSQL
bash database/aplicar.sh         # schema + migrations (no Windows, use o Git Bash)
 
# Backend (precisa de DATABASE_URL, SENHA_PEPPER, TOKEN_SIGNING_KEY e CORS_ORIGIN no ambiente)
cd backend
dart pub get
dart run bin/server.dart
 
# App
cd app
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
# ou, em um dispositivo Android: flutter run -d <id> --dart-define=API_BASE_URL=...
```
 
**Porta 5432 ocupada?** Defina `POSTGRES_PORT=5433` no `.env` e use a mesma porta na `DATABASE_URL`.
 
**CORS:** o backend só aceita a origem exata de `CORS_ORIGIN`. Abra o app pela mesma origem (`http://localhost:8081` e `http://127.0.0.1:8081` são origens diferentes).
 
### Código gerado pelo Drift
 
Sempre que `backend/lib/database/database.dart` ou o schema mudarem:
 
```bash
cd backend
dart run build_runner build --delete-conflicting-outputs
```
 
## Variáveis de ambiente
 
Veja o `.env.example` para o modelo completo. As principais:
 
| Variável | Para que serve |
|---|---|
| `POSTGRES_PASSWORD`, `POSTGRES_USER`, `POSTGRES_DB`, `POSTGRES_PORT` | Imagem do PostgreSQL |
| `DATABASE_URL` | Conexão do backend quando roda no host |
| `DATABASE_URL_DOCKER` | Mesma URL, mas com host `banco` e porta `5432` (backend dentro do compose) |
| `SENHA_PEPPER` | Segredo da aplicação para o hash de senha (32 bytes em Base64). **Gerado uma única vez**; perdê-lo ou trocá-lo invalida todas as senhas |
| `TOKEN_SIGNING_KEY` | Chave de assinatura dos tokens (≥ 32 bytes em Base64), independente do pepper |
| `CORS_ORIGIN` | Única origem aceita pelo backend |
| `DART_VERSION`, `FLUTTER_VERSION` | Versões usadas nas imagens do compose |
| `BACKEND_PUBLIC_PORT`, `WEB_PORT`, `API_BASE_URL` | Portas e URL da API para o app web |
| `COMPOSE_PROFILES` | `web` sobe também o app web |
 
Sem `DATABASE_URL`, `SENHA_PEPPER` ou `TOKEN_SIGNING_KEY` o backend **não inicia** (fail fast). Nunca versione o `.env`.
 
Se a senha do banco tiver caracteres especiais, faça o percent-encoding na URL (`@` → `%40`, `:` → `%3A`, `/` → `%2F`).
 
## Seed do admin
 
Não existe tela de criação de admin. A conta inicial é criada por um programa one-shot, **nunca** no boot do backend:
 
```bash
cd backend
# com as variáveis carregadas no ambiente:
# DATABASE_URL, SENHA_PEPPER (o mesmo do backend), SEED_ADMIN_NOME,
# SEED_ADMIN_CPF, SEED_ADMIN_EMAIL, SEED_ADMIN_SENHA
dart run bin/seed_admin.dart
```
 
É idempotente: se o e-mail já existir em qualquer das três tabelas de pessoas, sai sem alterar nada. Não use essas credenciais fora de desenvolvimento.
 
## Testes e análise estática
 
```bash
# Backend (exige o banco de pé e DATABASE_URL no ambiente do processo)
cd backend
DATABASE_URL='postgresql://usuario:senha@localhost:5433/grazifit?sslmode=disable' dart test
 
# Validação isolada (cria um banco temporário, aplica schema + migrations e roda a suíte)
dart run tool/test_auth_isolated.dart
 
# Análise estática e formatação
dart analyze && dart format .         # em backend/ e shared/
flutter analyze                        # em app/
```
 
A suíte do backend roda contra **PostgreSQL real**, do mesmo SQL de `database/`, para exercitar constraints, triggers, views e a coluna gerada. Há testes de concorrência (disputa pela última vaga de uma aula, cancelamento de aula) e testes de segurança (RBAC, limitador de login, CORS, limite de corpo).
 
## API
 
REST sobre JSON. Toda rota (exceto `/health` e o login) exige `Authorization: Bearer <token>`.
 
| Área | Rotas |
|---|---|
| Infra | `GET /health` |
| Auth | `POST /auth/login`, `POST /auth/logout` |
| Admin | `POST /admin`, `GET/PATCH/DELETE /admin/<id>` |
| Aluno | `POST /aluno`, `GET /aluno`, `GET/PATCH/DELETE /aluno/<id>`, `PATCH /aluno/<id>/status` |
| Professor | `POST /professor`, `GET/PATCH/DELETE /professor/<id>` |
| Aulas | `POST/GET /aulas`, `GET/PATCH /aulas/<id>`, `POST /aulas/<id>/cancelar`, `GET /aulas/<id>/agendamentos`, `PATCH /aulas/<id>/chamada` |
| Agendamentos | `POST/GET /agendamentos`, `PATCH /agendamentos/<id>` |
| Avaliações | `POST /aluno/<id>/avaliacoes/hoje`, `GET /aluno/<id>/avaliacoes`, `GET /aluno/<id>/avaliacoes/atual` |
| Início (admin) | `GET /inicio` |
| Treinos | `GET /treinos/livres` |
 
Convenções do contrato:
 
- **Erros:** envelope `{ "codigo", "mensagem", "campo?" }`. A interface escolhe o texto pelo `codigo`, nunca pela `mensagem`.
- **Datas:** `AAAA-MM-DD`, estrito. **Horas:** `HH:MM`, estrito.
- **Listas:** paginadas por `?limit=&offset=` (padrão `20` e `0`; `limit` de 1 a 100) e respondem `{ itens, limit, offset, total }`.
- **Login:** limitado por IP e por e-mail, com bloqueio progressivo (`429` + `Retry-After`).

### Swagger / OpenAPI

Com o backend em execução, abra [Swagger UI](http://localhost:8080/swagger). Se a porta publicada for diferente, use o valor de `BACKEND_PUBLIC_PORT`. A interface carrega seus arquivos do jsDelivr e precisa de acesso à internet para funcionar.

1. Abra `POST /auth/login`, clique em **Try it out** e envie o e-mail e a senha de uma conta do seu ambiente.
2. Copie o valor de `access_token`, clique em **Authorize** e cole o token sem o prefixo `Bearer`.
3. Use **Try it out** nas operações permitidas para o perfil da conta.

A interface e o [JSON OpenAPI](http://localhost:8080/swagger.json) são públicos. O contrato está em [`backend/lib/shared/http/openapi.json`](backend/lib/shared/http/openapi.json). Atualize esse arquivo junto com alterações de rotas, parâmetros ou respostas.

A coleção do Insomnia está em [`docs/api/grazifit.insomnia.json`](docs/api/grazifit.insomnia.json).
 
## Arquitetura em resumo
 
```
Controller (HTTP + DTO) → Service (regra de negócio) → Repository (Drift/SQL) → PostgreSQL
```
 
- **O SQL é a fonte de verdade do schema.** Nenhuma alteração de schema nasce em Dart: toda mudança é uma migration SQL numerada. O Drift é só camada de acesso tipada.
- **Autorização em dois pontos:** o middleware responde *quem é*; o service responde *pode esta operação, sobre este registro?* O app nunca decide permissão.
- **Regras críticas ficam no banco:** triggers com `ERRCODE` próprio (`GF001` a `GF004`) garantem vagas e coerência aula × cronograma, e o IMC é coluna gerada (o app lê, não recalcula).
- **App:** cada feature tem `data/` → `state/` → `screens/` → `widgets/`. Toda tela trata cinco estados: carregando, vazio, erro, sem conexão e dados.
- **Fatias verticais:** uma feature de ponta a ponta (DTO → repository → service → controller → data → state → screen) antes da próxima.
Detalhes e justificativas em [`docs/arquitetura.md`](docs/arquitetura.md).
 
## Estado atual das features
 
| Feature | Backend | App |
|---|---|---|
| `auth` | Login, logout, sessão e limitador | Tela de login e guard por papel |
| `pessoas` | CRUD de admin, aluno e professor | Telas de perfil e cadastro |
| `agendamentos` | Reservar, listar, cancelar | Agenda e "Meus agendamentos" do aluno, chamada |
| `aulas` | CRUD, cancelamento em cascata, chamada | Telas de aula (aluno, professor e admin) |
| `avaliacoes` | Registrar medida do dia, histórico e atual | Registrar medida e evolução |
| `inicio` | `GET /inicio` | Painel inicial do admin |
| `treinos` | Parcial (`GET /treinos/livres`) | Telas de treinos |
| `vinculos` | Pendente | Telas prontas |
| `cronogramas` | Pendente | Telas prontas |
| `exercicios` | Pendente | Telas prontas |
 
Onde o endpoint ainda não existe, o repositório do app lança `ApiException.pendente()` e a tela exibe o estado de erro. Quando o backend entregar a rota, só a implementação `*_http.dart` muda. Procure por `TODO(backend)` em `app/lib` para ver os pontos de integração.
 
O menu **Telas (DEV)** (`app/lib/dev/menu_dev_screen.dart`) lista as telas disponíveis para navegação durante o desenvolvimento.
 
## Fora de escopo
 
Por decisão de produto, **não existem** e não devem ser adicionados: pagamentos e mensalidades, chat, notificações push, gamificação, feed social, ranking, carteira digital, integração com wearables, upload de imagem e seletor de academia/unidade.
 
## Contribuindo
 
1. **Uma tarefa, um card Jira.** A chave (`GRAZ-123`) deve estar no nome da branch **e** no título do PR.
2. **Nome da branch** pelo tipo de mudança: `feature/*`, `fix/*`, `hotfix/*`, `bugfix/*`, `test/*`, `refactor/*`, `docs/*` ou `chore/*`.
3. **Abra o PR** com o template em `.github/pull_request_template.md`.
4. **Definição de pronto:**
   - testes passam;
   - análise estática limpa;
   - sem alteração estrutural fora de escopo aprovado (schema, dependências, contratos, fases);
   - `database/schema/grazi_db_init_schema.sql` intocado, salvo migration aprovada;
   - nenhum segredo versionado.
5. **Alteração estrutural** (novo pacote, tabela, contrato, fase) nasce como *change* em `openspec/changes/`, com `proposal.md`, `design.md` e `tasks.md`.
6. **Em dúvida entre duas fontes, pare e pergunte.** A ordem de autoridade é: instrução explícita → schema SQL → `docs/arquitetura.md` → `docs/guia-desenvolvimento.md`.
As dependências do backend estão **fixadas em versão exata** de propósito (`drift`, `drift_postgres`, `postgres`, `drift_dev`), verificadas contra o schema em PostgreSQL 18. Não rode `pub upgrade` como rotina.
 
## Documentação
 
| Documento | Conteúdo |
|---|---|
| [`docs/arquitetura.md`](docs/arquitetura.md) | Decisões de arquitetura, contrato de erro, autenticação, testes |
| [`docs/guia-desenvolvimento.md`](docs/guia-desenvolvimento.md) | Como construir uma feature, mapa de pastas, comandos do dia a dia |
| [`docs/handoff-front-professor.md`](docs/handoff-front-professor.md) | Mapa das telas do professor e lacunas de integração |
| [`database/migrations/README.md`](database/migrations/README.md) | Convenção e formato das migrations |
| [`openspec/project.md`](openspec/project.md) | Contexto permanente e ordem de autoridade |
| `docs/superpowers/` | Planos e specs de integração (login, remediação de segurança) |
 
