# `vinculos` — backend

Feature de domínio do GraziFit. Recorte, dependências e propriedade de tabela em `docs/arquitetura.md` §3; ordem e método de construção em `docs/guia-desenvolvimento.md`.

## Jornadas

F-13, F-17

## Tabelas que possui

`vinculo_professor_aluno`

## Views lidas

—

## Nota

É o resolvedor de escopo do sistema: `treinos`, `avaliacoes`, `pessoas`/inativos e `agendamentos` perguntam a ela se um professor pode agir sobre um aluno. Uma operação de escopo, consumida por todas.

## Arquivos

A partir da Fase 4, direto nesta pasta e sem subpastas: `*_table.dart` · `*_repository.dart` · `*_service.dart` · `*_controller.dart`, com o nome de domínio em pt-BR e o papel em inglês (**D67**).

## Regra de propriedade

Uma tabela, um dono. Só o repository desta feature escreve nas tabelas acima. Ler tabela ou view de outra feature é livre; escrever em tabela alheia acontece só **service → service**, e existem exatamente duas escritas assim em todo o sistema.
