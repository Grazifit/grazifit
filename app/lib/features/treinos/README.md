# `treinos` — app

Espelho de `backend/lib/features/treinos/`. As dez features existem dos dois lados com o mesmo nome; feature que exista só em um lado é erro.

## Jornadas

F-06, F-07, F-14, F-22

## Tabelas da feature no backend

`treino` · `treino_exercicio` · `historico_treino`

## Views lidas

—

## Nota

Livre e personalizado não se separam: `ck_treino_origem` é um XOR na mesma tabela. `historico_treino` fica aqui porque **D29** amarra a confirmação de execução à geração do histórico. Treino personalizado exige vínculo **ativo** (**D16**) — nenhuma constraint garante isso.

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
