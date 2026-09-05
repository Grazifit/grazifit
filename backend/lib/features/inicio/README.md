# `inicio` — backend

Feature de domínio do GraziFit. Recorte, dependências e propriedade de tabela em `docs/arquitetura.md` §3; ordem e método de construção em `docs/guia-desenvolvimento.md`.

## Jornadas

— (**D45**)

## Tabelas que possui

Nenhuma — só compõe leitura do que as outras produzem.

## Views lidas

`vw_aula_ocupacao`

## Nota

Não possui tabela e não escreve. Nasce na S1 como stub com empty state declarado — nunca como tela vazia — e só fecha na S6.

## Arquivos

A partir da Fase 4, direto nesta pasta e sem subpastas: `inicio_repository.dart` · `inicio_service.dart` · `inicio_controller.dart`. Sem `*_table.dart` — a feature não possui tabela.

## Regra de propriedade

Uma tabela, um dono. Só o repository desta feature escreve nas tabelas acima. Ler tabela ou view de outra feature é livre; escrever em tabela alheia acontece só **service → service**, e existem exatamente duas escritas assim em todo o sistema.
