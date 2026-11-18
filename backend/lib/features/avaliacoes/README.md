# `avaliacoes` — backend

Feature de domínio do GraziFit. Recorte, dependências e propriedade de tabela em `docs/arquitetura.md` §3; ordem e método de construção em `docs/guia-desenvolvimento.md`.

## Jornadas

F-08, F-15

## Tabelas que possui

`avaliacao`

## Views lidas

Nesta primeira etapa, a avaliação atual é consultada diretamente em `avaliacao`,
ordenada por data decrescente. A view `vw_aluno_medida_atual` permanece disponível
para as próximas integrações.

## Nota

`avaliacao.imc` é coluna `GENERATED STORED`: a aplicação **lê**, nunca calcula (RF-03). Uma feature com três portas de entrada — aluno (**D4**), professor e admin (**D37**) — e a mesma regra **D6** de sobrescrita do dia.

## Arquivos

A partir da Fase 4, direto nesta pasta e sem subpastas: `*_table.dart` · `*_repository.dart` · `*_service.dart` · `*_controller.dart`, com o nome de domínio em pt-BR e o papel em inglês (**D67**).

## Regra de propriedade

Uma tabela, um dono. Só o repository desta feature escreve nas tabelas acima. Ler tabela ou view de outra feature é livre; escrever em tabela alheia acontece só **service → service**, e existem exatamente duas escritas assim em todo o sistema.

## Primeira etapa implementada

Todas as rotas exigem Bearer válido. Admin pode acessar qualquer aluno;
aluno acessa somente seus próprios dados. Professor recebe 403 nesta etapa,
até a integração com o resolvedor de vínculos.

| Método | Rota | Resultado |
| --- | --- | --- |
| POST | `/aluno/{id}/avaliacoes/hoje` | 200: cria ou sobrescreve a avaliação do dia |
| GET | `/aluno/{id}/avaliacoes?limit=20&offset=0` | 200: `{itens, limit, offset, total}`, da mais recente à mais antiga |
| GET | `/aluno/{id}/avaliacoes/atual` | 200: última avaliação; 204 se não houver |

Corpo do POST: `{"peso":70,"altura":1.75,"observacao":"Opcional"}`.
Peso em kg e altura em metros: ambos positivos, até duas casas decimais,
peso menor que 500 e altura menor que 3. Observação tem até 2000 caracteres;
é aparada e texto vazio vira null. O POST substitui a observação: omiti-la a limpa.
IMC e data não são aceitos no corpo. O banco gera o IMC; combinações que
excedam a capacidade de sua coluna recebem 400 sem persistência.

A data do dia usa `America/Sao_Paulo` no PostgreSQL. O upsert usa a restrição
única existente para preservar uma única avaliação por aluno/dia, inclusive
com gravações simultâneas. No mesmo dia, a última gravação prevalece; em dias
diferentes, o POST cria outro registro e preserva os anteriores. O histórico usa uma
transação com snapshot consistente entre contagem e itens.

Paginação: `limit` entre 1 e 100 e `offset` não negativo. Aluno inexistente
retorna 404. Aluno inativo não recebe novas medidas (403); admin pode consultar
seu histórico. Não há exclusão nem edição de datas anteriores nesta etapa.

SQL parametrizado via Drift preserva a coluna gerada existente, sem migration
ou alteração do schema inicial. Nenhuma tela do frontend foi modificada.

Testes: `test/avaliacao_integration_test.dart`, executados contra PostgreSQL
descartável por `dart run tool/test_auth_isolated.dart test/avaliacao_integration_test.dart`.
Execute a partir de `backend`, com `DATABASE_URL` definida e PostgreSQL ativo.
