# `cronogramas` — backend

Feature de domínio do GraziFit. Recorte, dependências e propriedade de tabela em `docs/arquitetura.md` §3; ordem e método de construção em `docs/guia-desenvolvimento.md`.

## Jornadas

F-18, F-19

## CRUD implementado

Todas as rotas exigem sessao autenticada de administrador. O criador e obtido
da identidade autenticada, nunca do corpo enviado pelo cliente.

| Metodo | Rota | Resposta |
| --- | --- | --- |
| POST | `/cronogramas` | 201 com o cronograma e seus dias |
| GET | `/cronogramas?limit=20&offset=0&status=true` | 200 com `{itens,total,limit,offset}` |
| GET | `/cronogramas/{id}` | 200 ou 404 |
| PATCH | `/cronogramas/{id}` | 200; aceita somente os campos enviados |
| DELETE | `/cronogramas/{id}` | 204; 409 se houver aulas vinculadas |

Exemplo de criacao:

```json
{
  "id_professor": 1,
  "categoria": "pilates",
  "hora_inicio": "08:00",
  "hora_fim": "09:00",
  "data_inicio": "2026-11-18",
  "data_fim": null,
  "vagas_maxima": 10,
  "dias_semana": [1, 3, 5]
}
```

- Professor existente e ativo; categorias iguais as do schema.
- Datas civis estritas `AAAA-MM-DD`; data final opcional e nao anterior a inicial.
- Horarios `HH:MM`, com final posterior ao inicial; vagas inteiras positivas.
- Dias entre 0 (domingo) e 6 (sabado), pelo menos um, sem repeticao.
- `status` opcional na criacao, padrao true. Inativar: `PATCH` com `{"status":false}`.
- `data_fim: null` no PATCH remove o fim da vigencia. Corpo vazio/chaves desconhecidas sao rejeitados.
- Lista ordenada por data inicial decrescente e ID decrescente; limit 1..100,
  offset nao negativo; filtro status opcional.
- Cronogramas com aulas vinculadas permitem somente PATCH de status. Outras
  alteracoes ou exclusao retornam 409 `REGISTRO_EM_USO`, incluindo aulas canceladas.
- Inativar nao cancela nem altera aulas existentes. Geracao de aulas e uma
  etapa separada, ainda nao implementada nesta feature.
- Cronograma e dias sao gravados na mesma transacao. Atualizacoes e exclusoes
  bloqueiam a linha do cronograma; listagem usa snapshot consistente.
- Listagem em lote: tres SELECTs por pagina com itens (contagem, cronogramas,
  dias); pagina vazia usa dois. Nao executa consultas adicionais por item.

Validacao Q6 em PostgreSQL local isolado, com 100 itens e cinco amostras apos
aquecimento: 202 -> 3 SELECTs; mediana de 907,645 ms -> 26,618 ms, incluindo
a transacao. Medicao informativa deste ambiente, nao garantia de latencia.
O teste compara o conteudo anterior/novo e verifica a contagem de consultas.

Nao foram alterados frontend, schema inicial ou dependencias. Os DTOs desta
etapa permanecem locais ao backend. Testes em PostgreSQL descartavel:

```sh
dart run tool/test_auth_isolated.dart test/cronograma_integration_test.dart
```

Execute em `backend` com DATABASE_URL definida. O helper cria e remove apenas
o banco temporario de testes, sem aplicar migrations no banco de origem.

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
