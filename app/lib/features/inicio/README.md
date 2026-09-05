# `inicio` — app

Espelho de `backend/lib/features/inicio/`. As dez features existem dos dois lados com o mesmo nome; feature que exista só em um lado é erro.

## Jornadas

— (**D45**)

## Tabelas da feature no backend

Nenhuma — só compõe leitura do que as outras produzem.

## Views lidas

`vw_aula_ocupacao`

## Nota

Não possui tabela e não escreve. Nasce na S1 como stub com empty state declarado — nunca como tela vazia — e só fecha na S6.

## Subpastas

| Pasta | Conteúdo |
|---|---|
| `data/` | Chamada HTTP e parse do DTO de `shared/` |
| `state/` | Provider Riverpod devolvendo `AsyncState` |
| `screens/` | Telas, cada uma com os cinco estados obrigatórios (RNF-04) |
| `widgets/` | Componentes locais desta feature |

## Regras do lado do app

- O app **nunca** decide permissão. Pode ocultar o que o papel não usa, mas quem nega é o backend — tela que some não é segurança.
- Nenhuma regra de negócio na tela.
- Nada é recalculado no app se o banco já calculou.
- Sem persistência local: o app é 100% online.
- Componentes compartilhados e tokens vivem em `app/lib/core/design_system/`, não aqui.
