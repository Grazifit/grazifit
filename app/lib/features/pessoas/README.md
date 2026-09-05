# `pessoas` — app

Espelho de `backend/lib/features/pessoas/`. As dez features existem dos dois lados com o mesmo nome; feature que exista só em um lado é erro.

## Jornadas

F-02, F-09, F-16, F-23

## Tabelas da feature no backend

`aluno` · `professor` · `admin` · `endereco`

## Views lidas

—

## Nota

`endereco` não é feature: é sub-form opcional de aluno e professor (**D18**). A unicidade de e-mail entre `admin`, `professor` e `aluno` é validação desta feature (**D61**) — o banco só tem `uq_*_email` por tabela.

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
