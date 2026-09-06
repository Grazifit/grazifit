# Migrations

## A convenção (D58)

`schema/grazi_db_init_schema.sql` é o **estado atual** do schema. Ele é a
fonte de verdade — não o Dart, não o Drift, não as specs.

**Enquanto o sistema não estiver implantado**, correção de schema é edição
naquele arquivo. Não se cria migration para consertar algo que ninguém
ainda tem em produção.

**A partir da primeira implantação**, esta pasta passa a valer: toda
alteração vira um arquivo aqui, e `schema/grazi_db_init_schema.sql` deixa
de ser editado.

Hoje esta pasta está vazia de propósito. Isso não é pendência.

---

## Formato

```
NNN_descricao_em_snake_case.sql
```

`NNN` é sequencial com três dígitos, começando em `001`. A ordem de
aplicação é a ordem numérica — `002` roda antes de `010`.

```
001_adiciona_telefone_secundario.sql
002_indice_agendamento_data.sql
```

---

## As três regras

**1. Arquivo aplicado nunca é editado.** Ele já rodou em algum banco. Mudar
o conteúdo faria as bases divergirem em silêncio, com o mesmo nome
registrado. Errou? Novo arquivo, com a correção.

**2. Um arquivo, uma transação.** Escreva `BEGIN;` na primeira linha e
`COMMIT;` na última, como faz o arquivo de schema. Se o arquivo não trouxer
a própria transação, `aplicar.sh` o envolve — mas ser explícito é melhor.

**3. Nada nasce em Dart.** Nenhuma tabela, coluna, constraint, índice, view
ou função vem do Drift. O Drift é camada de acesso, não de definição.

---

## Como aplicar

```bash
docker compose up -d
./database/aplicar.sh
```

O script:

1. aguarda o banco aceitar **conexão real**, em laço com limite
2. cria `schema_migracao` se não existir
3. aplica o schema, se ainda não registrado
4. aplica as migrations pendentes, em ordem numérica
5. registra cada aplicação

É **idempotente**: rodar duas vezes seguidas não altera nada na segunda.
Qualquer falha aborta e sai com código diferente de zero.

### A tabela de controle

```sql
CREATE TABLE schema_migracao (
    arquivo      VARCHAR(200) PRIMARY KEY,
    aplicado_em  TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

É o único objeto que este projeto acrescenta ao schema especificado. É
infraestrutura, não domínio — por isso vive em `aplicar.sh` e **não** em
`schema/grazi_db_init_schema.sql`.

Para ver o que já foi aplicado:

```sql
SELECT * FROM schema_migracao ORDER BY aplicado_em;
```

### Um caso de borda que vale conhecer

Um arquivo que traz o próprio `COMMIT;` é confirmado antes do registro em
`schema_migracao`. Se o processo for morto exatamente nessa fresta, o
arquivo estará aplicado sem estar registrado, e a próxima execução tentará
reaplicá-lo — falhando em `CREATE TABLE` já existente. A recuperação é
registrar à mão o que de fato foi aplicado:

```sql
INSERT INTO schema_migracao (arquivo) VALUES ('migrations/00N_....sql');
```

---

## Quando parar e perguntar

O schema tem 14 tabelas, 2 funções, 2 triggers e 2 views, e foi auditado.
Se ele parecer errado, **reporte — não conserte** (prompt-fase-2, R6).

Necessidade de nova tabela, coluna ou regra é **escopo novo**, e escopo
novo se propõe, não se implementa.
