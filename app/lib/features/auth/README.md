# `auth` — app

Espelho de `backend/lib/features/auth/`. As dez features existem dos dois lados com o mesmo nome; feature que exista só em um lado é erro.

## Jornadas

F-01, F-24

## Tabelas da feature no backend

Nenhuma — resolve identidade sobre `admin`, `professor` e `aluno`.

## Views lidas

—

## Nota

Identidade resolvida sobre as três tabelas de pessoa; o e-mail é único entre elas somadas (**D61**), e a verificação cruzada pertence a `pessoas`. Sem tabela própria, esta feature não escreve em lugar nenhum.

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
