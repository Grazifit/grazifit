# `agendamentos` — backend

Feature de domínio do GraziFit. Recorte, dependências e propriedade de tabela em `docs/arquitetura.md` §3; ordem e método de construção em `docs/guia-desenvolvimento.md`.

## Jornadas

F-03, F-04, F-05, F-11

## Tabelas que possui

`agendamento`

## Views lidas

`vw_aula_ocupacao`

## Nota

`Chamada` (F-11) vive aqui, não em `aulas`: escreve `agendamento.status` e `data_presenca` — quem escreve, possui. O trigger de vagas é `BEFORE INSERT` e mascara `uq_agendamento_aluno_aula` em aula lotada, então o Service pré-verifica antes do insert.

## Arquivos

A partir da Fase 4, direto nesta pasta e sem subpastas: `*_table.dart` · `*_repository.dart` · `*_service.dart` · `*_controller.dart`, com o nome de domínio em pt-BR e o papel em inglês (**D67**).

## Regra de propriedade

Uma tabela, um dono. Só o repository desta feature escreve nas tabelas acima. Ler tabela ou view de outra feature é livre; escrever em tabela alheia acontece só **service → service**, e existem exatamente duas escritas assim em todo o sistema.
