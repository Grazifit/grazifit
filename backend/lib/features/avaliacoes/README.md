# `avaliacoes` — backend

Feature de domínio do GraziFit. Recorte, dependências e propriedade de tabela em `docs/arquitetura.md` §3; ordem e método de construção em `docs/guia-desenvolvimento.md`.

## Jornadas

F-08, F-15

## Tabelas que possui

`avaliacao`

## Views lidas

`vw_aluno_medida_atual`

## Nota

`avaliacao.imc` é coluna `GENERATED STORED`: a aplicação **lê**, nunca calcula (RF-03). Uma feature com três portas de entrada — aluno (**D4**), professor e admin (**D37**) — e a mesma regra **D6** de sobrescrita do dia.

## Arquivos

A partir da Fase 4, direto nesta pasta e sem subpastas: `*_table.dart` · `*_repository.dart` · `*_service.dart` · `*_controller.dart`, com o nome de domínio em pt-BR e o papel em inglês (**D67**).

## Regra de propriedade

Uma tabela, um dono. Só o repository desta feature escreve nas tabelas acima. Ler tabela ou view de outra feature é livre; escrever em tabela alheia acontece só **service → service**, e existem exatamente duas escritas assim em todo o sistema.
