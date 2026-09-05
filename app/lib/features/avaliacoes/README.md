# `avaliacoes` — app

Espelho de `backend/lib/features/avaliacoes/`. As dez features existem dos dois lados com o mesmo nome; feature que exista só em um lado é erro.

## Jornadas

F-08, F-15

## Tabelas da feature no backend

`avaliacao`

## Views lidas

`vw_aluno_medida_atual`

## Nota

`avaliacao.imc` é coluna `GENERATED STORED`: a aplicação **lê**, nunca calcula (RF-03). Uma feature com três portas de entrada — aluno (**D4**), professor e admin (**D37**) — e a mesma regra **D6** de sobrescrita do dia.

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
