# GraziFit — Contexto Permanente do Repositório de Implementação

> Este é o repositório de **implementação**. O repositório de **specs** — requisitos, design system, protótipo e as decisões **D1**–**D67** — vive em `C:\Users\marco\GraziFit\Grazi-Specs` e é a fonte de tudo o que aqui é construído.

## Produto

**GraziFit**: app mobile (Flutter/Dart, foco Android) para gestão de negócios fitness — alunos, professores, aulas, treinos, avaliações físicas e administração. Três perfis com RBAC: **Aluno**, **Professor**, **Admin**. Single-tenant, 100% online, sem requisito offline.

O produto **já está integralmente especificado**: 19 RF, 10 RNF, 14 tabelas, 24 jornadas, 60 telas, matriz RBAC de 15 entidades × 3 perfis e 67 decisões numeradas. Nada disso se decide aqui.

## Ordem de autoridade das fontes

1. **Instruções explícitas do usuário**
2. **`database/schema/grazi_db_init_schema.sql`** — fonte de verdade do domínio de dados (**D58**)
3. **`docs/arquitetura.md`** — decisões de arquitetura de aplicação
4. **`docs/guia-desenvolvimento.md`** — ordem e método de construção
5. **`prompt-mestre-implementacao.md`** — escopo por fase

Em conflito entre fontes, **nunca escolher automaticamente uma interpretação**. Ver `nao-inventar`.

## Estrutura

Monorepo com quatro raízes irmãs: `database/`, `shared/`, `backend/` e `app/`.

**Fronteiras de import, verificáveis em lint:** `backend/` nunca importa `package:flutter`; `app/` nunca importa `shelf` nem `drift_postgres`; `shared/` não importa nenhum dos dois.

## As 10 features

`auth` · `pessoas` · `vinculos` · `avaliacoes` · `cronogramas` · `aulas` · `agendamentos` · `exercicios` · `treinos` · `inicio`

Derivadas das 24 jornadas cruzadas com as 14 tabelas: cobertura fechada, sem sobreposição e sem órfão. Existem com o mesmo nome no `backend/` e no `app/`.

**Uma tabela, um dono.** Só o repository da feature dona escreve na tabela. Leitura atravessa features; escrita só **service → service**. Existem exatamente **duas** escritas entre features em todo o sistema, e ambas coincidem com os dois triggers do banco.

## Fases

| Fase | Entrega |
|---|---|
| 1 | Estrutura de pastas, READMEs das features, guia de desenvolvimento |
| 2 | Banco: aplicação e versionamento — SQL e Docker, sem Dart |
| 3 | Projeto Dart: pubspecs, lint das fronteiras, config, CI, seed do admin |
| 4 | Primeira fatia vertical: `auth` / F-01 |

**Cada fase é uma aprovação separada.** Antecipar fase é alteração estrutural — ver `aprovacao-obrigatoria`.

## Princípio de construção

**Fatias verticais, nunca camadas horizontais.** Uma feature de ponta a ponta antes da próxima, na ordem: DTO → repository → service → controller → data → state → screen. Não se começa pela camada de negócio nem pela tela: começa-se pelo contrato.

A ordem entre features é ditada pelas chaves estrangeiras, não por preferência.

## Fora de escopo por decisão de produto

Não existem e não devem ser adicionados: pagamentos, mensalidades, chat, notificações push, gamificação, feed social, ranking, carteira digital, wearables, upload de imagem, seletor de academia ou unidade. A ausência é deliberada e foi verificada na auditoria da Etapa 8.

## Uso do OpenSpec

Toda alteração estrutural nasce como change em `openspec/changes/`, com `proposal.md`, `design.md` e `tasks.md` — o mesmo formato das oito changes do repositório de specs. Decisões novas continuam a numeração a partir de **D68**.

`openspec/specs/` permanece vazio até que haja capability consolidada a declarar.
