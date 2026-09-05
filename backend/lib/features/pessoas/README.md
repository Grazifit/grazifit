# `pessoas` — backend

Feature de domínio do GraziFit. Recorte, dependências e propriedade de tabela em `docs/arquitetura.md` §3; ordem e método de construção em `docs/guia-desenvolvimento.md`.

## Jornadas

F-02, F-09, F-16, F-23

## Tabelas que possui

`aluno` · `professor` · `admin` · `endereco`

## Views lidas

—

## Nota

`endereco` não é feature: é sub-form opcional de aluno e professor (**D18**). A unicidade de e-mail entre `admin`, `professor` e `aluno` é validação desta feature (**D61**) — o banco só tem `uq_*_email` por tabela.

## Arquivos

A partir da Fase 4, direto nesta pasta e sem subpastas: `*_table.dart` · `*_repository.dart` · `*_service.dart` · `*_controller.dart`, com o nome de domínio em pt-BR e o papel em inglês (**D67**).

## Regra de propriedade

Uma tabela, um dono. Só o repository desta feature escreve nas tabelas acima. Ler tabela ou view de outra feature é livre; escrever em tabela alheia acontece só **service → service**, e existem exatamente duas escritas assim em todo o sistema.
