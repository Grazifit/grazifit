# `treinos` — backend

Feature de domínio do GraziFit. Recorte, dependências e propriedade de tabela em `docs/arquitetura.md` §3; ordem e método de construção em `docs/guia-desenvolvimento.md`.

## Jornadas

F-06, F-07, F-14, F-22

## Tabelas que possui

`treino` · `treino_exercicio` · `historico_treino`

## Views lidas

—

## Nota

Livre e personalizado não se separam: `ck_treino_origem` é um XOR na mesma tabela. `historico_treino` fica aqui porque **D29** amarra a confirmação de execução à geração do histórico. Treino personalizado exige vínculo **ativo** (**D16**) — nenhuma constraint garante isso.

## Arquivos

A partir da Fase 4, direto nesta pasta e sem subpastas: `*_table.dart` · `*_repository.dart` · `*_service.dart` · `*_controller.dart`, com o nome de domínio em pt-BR e o papel em inglês (**D67**).

## Regra de propriedade

Uma tabela, um dono. Só o repository desta feature escreve nas tabelas acima. Ler tabela ou view de outra feature é livre; escrever em tabela alheia acontece só **service → service**, e existem exatamente duas escritas assim em todo o sistema.
