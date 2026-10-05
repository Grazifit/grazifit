# Formato de data no contrato REST — D68

> Aprovada pelo usuário em 2026-09-13, na fatia `aluno` / F-16 (GRAZ-37).
> Escopo reduzido na aprovação: **apenas colunas `DATE`**. `TIMESTAMPTZ` fica
> sem formato definido, porque nenhum endpoint a expõe hoje.

## Decisão — D68

Coluna `DATE` trafega no JSON como string **`AAAA-MM-DD`**, estrita: sem hora,
sem fuso, sem forma compacta, nas duas direções — requisição e resposta.

Uma data que não case exatamente com essa forma, ou que não exista no
calendário, é recusada **antes** de chegar ao service.

## Por que existir

A regra não existia. Até esta change, nenhum documento do repositório definia
formato de data no fio: nem `arquitetura.md`, nem `guia-desenvolvimento.md`,
nem o schema, nem D1–D67. O `aluno_controller.dart` foi escrito com
`DateTime.tryParse` e uma mensagem de erro afirmando `AAAA-MM-DD` — uma
invenção, contrária à regra `nao-inventar`. Esta change corrige a origem, não
o sintoma.

Três defeitos concretos, todos verificados contra o código em execução:

**1. A mensagem contradiz o comportamento.** `DateTime.tryParse` aceita muito
mais do que a API afirma exigir:

| Entrada | `tryParse` |
|---|---|
| `1995-03-20` | aceita |
| `19950320` | aceita |
| `1995-03-20T10:30:00Z` | aceita |
| `1995-03-20 10:30:00` | aceita |
| `1995-3-20` | rejeita |
| `20/03/1995` | rejeita |

**2. Offset desloca o dia gravado.** `PgDate.fromDateTime` lê `.year/.month/.day`
do `DateTime` já convertido para UTC:

```
enviado 1995-03-20T02:00:00+05:00  ->  gravado 1995-03-19
enviado 1995-03-20T22:00:00-05:00  ->  gravado 1995-03-21
```

Sem erro, sem aviso. E é o caminho provável: `DateTime.toIso8601String()` no
Flutter emite offset.

**3. Data inexistente sofre rollover em vez de ser recusada.** Este é o pior,
porque nenhum regex sozinho o pega:

```
2025-02-30  ->  2025-03-02
2025-13-01  ->  2026-01-01
2025-04-31  ->  2025-05-01
2025-00-10  ->  2024-12-10
```

Um cadastro com 30 de fevereiro grava 2 de março e responde `201`.

Data de nascimento é **data civil, não instante**. Não tem fuso. Aceitar um só
cria a chance de errar o dia.

**4. O dia deslocava na gravação, mesmo com a string correta.** Descoberto ao
verificar a implementação: enviando `1995-03-20`, o banco guardava
`1995-03-21`. A fronteira é exatamente o epoch do tipo `date` do Postgres:

```
enviado 1999-12-30  ->  gravado 1999-12-31   deslocou
enviado 1999-12-31  ->  gravado 2000-01-01   deslocou
enviado 2000-01-01  ->  gravado 2000-01-01   ok
```

O encoder de `date` do `drift_postgres` ignora os campos `year/month/day` do
`PgDate` e serializa `toDateTime()`, contando dias desde 2000-01-01. Num fuso a
oeste de UTC, meia-noite local carrega resto de +3h; para data anterior ao
epoch a contagem é negativa e o truncamento vai em direção ao zero, somando um
dia. Como `data_nascimento` de adulto é quase sempre anterior a 2000, **a
maioria dos cadastros gravava a data errada** — em silêncio, porque a data
deslocada continua válida e passa por `ck_aluno_nascimento`.

Este defeito não é de formato de fio, mas sem corrigi-lo D68 não significaria
nada: o contrato diria `1995-03-20` e o banco guardaria outro dia. Corrigido em
`AlunoRepository`, construindo o instante em UTC.

## Alcance

Hoje só `aluno.data_nascimento` exercita a regra — foi o argumento do usuário
para dispensar a metade `TIMESTAMPTZ`. Mas o schema tem **10 colunas `DATE`**
espalhadas por 9 tabelas: `admin.data_cadastro`, `aluno.data_nascimento`,
`aluno.data_cadastro`, `avaliacao.data_avaliacao`,
`vinculo_professor_aluno.data_inicio` e `.data_fim`, `cronograma.data_inicio`,
`aula.data`, `agendamento.data_agendamento`, `historico_treino.data_execucao`.
Definir agora custa uma linha; definir depois custa retrabalho em nove fatias.

## Efeito no banco

**Nenhum.** Nenhuma tabela, coluna, constraint, índice, view, função ou trigger
muda. `ck_aluno_nascimento` (`data_nascimento < CURRENT_DATE`) segue intacta
como última linha de defesa. D58 preservada: a mudança é de camada de
transporte, e o SQL continua sendo a autoridade sobre o domínio de dados.

## Fora do escopo

- **`TIMESTAMPTZ`** — 4 colunas (`aluno.data_ultimo_acesso`,
  `aula.data_cancelamento`, `agendamento.data_presenca` e `.data_cancelamento`).
  Sem formato definido, sem endpoint que as exponha. Quando a primeira for
  exposta, nasce uma change nova.
- **Código de erro para formato malformado.** A recusa continua saindo como
  erro de forma `{"erro": "..."}`, sem `codigo`, porque `arquitetura.md` §7.1
  não tem entrada para isso — mesma lacuna já registrada para senha, nome e
  telefone. Fechá-la é decisão separada.
