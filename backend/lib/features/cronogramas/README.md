# `cronogramas` — backend

Feature de domínio do GraziFit. Recorte, dependências e propriedade de tabela em `docs/arquitetura.md` §3; ordem e método de construção em `docs/guia-desenvolvimento.md`.

## Jornadas

F-18, F-19

## Tabelas que possui

`cronograma` · `cronograma_dia`

## Views lidas

—

## Nota

Escrita entre features: `CronogramaService.gerarAulas` → `AulaService.criarEmLote` (F-19, **D8**). É uma das duas únicas do sistema e coincide com `trg_valida_aula_cronograma`.

## Arquivos

A partir da Fase 4, direto nesta pasta e sem subpastas: `*_table.dart` · `*_repository.dart` · `*_service.dart` · `*_controller.dart`, com o nome de domínio em pt-BR e o papel em inglês (**D67**).

## Regra de propriedade

Uma tabela, um dono. Só o repository desta feature escreve nas tabelas acima. Ler tabela ou view de outra feature é livre; escrever em tabela alheia acontece só **service → service**, e existem exatamente duas escritas assim em todo o sistema.
