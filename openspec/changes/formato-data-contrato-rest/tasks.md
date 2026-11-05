# Tarefas — D68, formato de data no contrato REST

Ordem obrigatória: documentação antes do código, como em
`DATA_NASCIMENTO_INVALIDA`.

## Documentação

- [x] `openspec/changes/formato-data-contrato-rest/` — `proposal.md`,
      `design.md`, `tasks.md`
- [x] `docs/guia-desenvolvimento.md` §6 — bullet normativo citando **D68**

## Código

- [x] `backend/lib/features/pessoas/aluno/aluno_controller.dart` — `_dataCivil`
      com as três portas (regex, parse, round-trip), substituindo o
      `DateTime.tryParse` solto
- [x] Mensagem de erro alinhada ao que é de fato aceito
- [x] `backend/lib/features/pessoas/aluno/aluno_repository.dart` — `_comoDataCivil`
      constrói o instante em UTC antes do `PgDate`, matando o deslocamento de
      um dia em toda data anterior a 2000-01-01

## Teste

- [x] `backend/test/aluno_controller_test.dart` — primeiro teste de controller
      do projeto. Cobre: forma aceita, formas recusadas (compacta, com hora,
      com offset), rollover (`2025-02-30`, `2025-13-01`) e os demais erros de
      forma que já existiam
- [x] `backend/test/aluno_repository_test.dart` — **primeiro teste de integração
      de repository do projeto** (guia §11 nível 2, D66). Cobre a fronteira do
      epoch (`1999-12-31` / `2000-01-01`), datas antigas, ano bissexto, e que o
      repository não traduz erro de constraint

## Artefato de apoio

- [x] `docs/grazifit-insomnia-collection.json` — descrição da requisição 9
      corrigida; requisições novas para os casos que passam a ser 400

## Verificação

- [x] `dart analyze` limpo em `lib`, `bin`, `test`
- [x] Suíte completa passando, incluindo integração contra Postgres real
- [x] Collection reexecutada ponta a ponta contra o servidor

## Fica em aberto

- [ ] Código de contrato para "formato malformado" — hoje a recusa sai como
      `{"erro": "..."}`, fora do envelope D64. Mesma lacuna de senha, nome e
      telefone. Exige entrada nova em `arquitetura.md` §7.1
- [ ] Formato de `TIMESTAMPTZ` — 4 colunas, nenhuma exposta. Nasce como change
      própria quando a primeira for
