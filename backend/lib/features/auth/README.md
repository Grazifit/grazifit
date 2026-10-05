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

F-01: `POST /auth/login` recebe e-mail e senha e devolve token Bearer de 1 hora e `{id, papel, nome}`. O middleware valida o token e reconsulta status/existência da conta antes de injetar a identidade. A autorização de cada operação permanece no Service. Contrato detalhado em `docs/arquitetura.md` §6.4.

`protecao_login.dart` aplica limites por IP e por conta, espera progressiva e teto de verificações simultâneas antes do Argon2id. O IP tem janela de 15 minutos, bloqueios de 15/30/45/60/75/90 minutos após infrações sucessivas e bloqueio até o reinício na sétima. Responde `429` com `Retry-After` nos bloqueios temporários. O estado é local ao processo; múltiplas réplicas exigem limitador compartilhado e proteção na borda.

## Arquivos

A partir da Fase 4, direto nesta pasta e sem subpastas: `auth_repository.dart` · `auth_service.dart` · `auth_controller.dart` · `token_service.dart` · `protecao_login.dart`. Sem `*_table.dart` — a feature não possui tabela.

## Regra de propriedade

Uma tabela, um dono. Só o repository desta feature escreve nas tabelas acima. Ler tabela ou view de outra feature é livre; escrever em tabela alheia acontece só **service → service**, e existem exatamente duas escritas assim em todo o sistema.
