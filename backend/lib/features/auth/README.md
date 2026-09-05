# `auth` — backend

Feature de domínio do GraziFit. Recorte, dependências e propriedade de tabela em `docs/arquitetura.md` §3; ordem e método de construção em `docs/guia-desenvolvimento.md`.

## Jornadas

F-01, F-24

## Tabelas que possui

Nenhuma — resolve identidade sobre `admin`, `professor` e `aluno`.

## Views lidas

—

## Nota

Identidade resolvida sobre as três tabelas de pessoa; o e-mail é único entre elas somadas (**D61**), e a verificação cruzada pertence a `pessoas`. Sem tabela própria, esta feature não escreve em lugar nenhum.

## Arquivos

A partir da Fase 4, direto nesta pasta e sem subpastas: `auth_repository.dart` · `auth_service.dart` · `auth_controller.dart`. Sem `*_table.dart` — a feature não possui tabela.

## Regra de propriedade

Uma tabela, um dono. Só o repository desta feature escreve nas tabelas acima. Ler tabela ou view de outra feature é livre; escrever em tabela alheia acontece só **service → service**, e existem exatamente duas escritas assim em todo o sistema.
