#!/usr/bin/env bash
#
# ============================================================
# GraziFit — aplicacao do schema e das migrations
#
# Ordem (prompt-fase-2 secao 7.3):
#   1. aguarda o banco aceitar CONEXAO REAL, em laco com limite
#   2. cria schema_migracao se nao existir
#   3. aplica schema/grazi_db_init_schema.sql se ainda nao registrado
#   4. aplica migrations/NNN_*.sql em ordem, os ainda nao registrados
#   5. registra cada aplicacao
#
# Cada arquivo roda em UMA transacao. Falha aborta tudo e sai != 0.
# Idempotente: rodar duas vezes seguidas nao altera nada na segunda.
#
# D58: este script APLICA o SQL. Ele nunca gera, deduz ou corrige
# schema. O arquivo em schema/ e a fonte de verdade.
# ============================================================

set -Eeuo pipefail

log()  { printf '  %s\n' "$*"; }
erro() { printf 'ERRO: %s\n' "$*" >&2; }

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARQUIVO_SCHEMA="schema/grazi_db_init_schema.sql"
SERVICO_COMPOSE="banco"
TENTATIVAS_MAX="${TENTATIVAS_MAX:-30}"
INTERVALO_SEG="${INTERVALO_SEG:-2}"

# Carrega .env, se existir. Valores ja no ambiente tem precedencia.
if [[ -f "$RAIZ/../.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$RAIZ/../.env"
  set +a
fi

# Nomes ditados pela imagem oficial do PostgreSQL, os mesmos que o
# docker-compose.yml consome. A aplicacao Dart usa DATABASE_URL; este
# script fala com o psql, que le as partes separadas.
POSTGRES_USER="${POSTGRES_USER:-grazifit}"
POSTGRES_DB="${POSTGRES_DB:-grazifit}"

# POSTGRES_PASSWORD NAO TEM DEFAULT, de proposito (D65): nenhum default
# silencioso para segredo. Falha aqui e melhor que aplicar o schema num
# banco cuja senha qualquer um conhece.
if [[ -z "${POSTGRES_PASSWORD:-}" ]]; then
  erro "POSTGRES_PASSWORD nao esta definida."
  erro "defina no .env da raiz (veja .env.example) ou exporte no ambiente."
  exit 1
fi
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"


# ------------------------------------------------------------
# Como falar com o Postgres.
#
# Se houver psql no host, usa. Se nao houver — caso comum em
# Windows —, usa o psql de dentro do proprio container.
# ------------------------------------------------------------
if command -v psql >/dev/null 2>&1; then
  MODO="host"
  psql_exec() {
    PGPASSWORD="$POSTGRES_PASSWORD" psql \
      -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" \
      -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
      -v ON_ERROR_STOP=1 --no-psqlrc "$@"
  }
else
  MODO="container"
  psql_exec() {
    docker compose exec -T \
      -e PGPASSWORD="$POSTGRES_PASSWORD" \
      "$SERVICO_COMPOSE" \
      psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
      -v ON_ERROR_STOP=1 --no-psqlrc "$@"
  }
fi

# Retorna valor unico, sem cabecalho nem alinhamento.
consultar() { psql_exec -tA -c "$1"; }

# ------------------------------------------------------------
# 1. Aguarda CONEXAO REAL
#
# Nao usa pg_isready de proposito: durante o initdb a imagem sobe
# um servidor temporario e o derruba em seguida, e o pg_isready
# responde "pronto" nele. So um SELECT que retorna prova que o
# servidor definitivo esta no ar.
# ------------------------------------------------------------
aguardar_banco() {
  log "aguardando o banco aceitar conexao (modo: $MODO)..."
  local tentativa=1
  while (( tentativa <= TENTATIVAS_MAX )); do
    if consultar "SELECT 1;" >/dev/null 2>&1; then
      log "banco respondeu na tentativa $tentativa."
      return 0
    fi
    sleep "$INTERVALO_SEG"
    (( tentativa++ ))
  done
  erro "banco nao respondeu apos $TENTATIVAS_MAX tentativas."
  erro "o container esta de pe? tente: docker compose up -d"
  return 1
}

# ------------------------------------------------------------
# 2. Tabela de controle
#
# Unico objeto que este projeto acrescenta ao schema especificado.
# E infraestrutura, nao dominio — por isso vive aqui e NAO em
# schema/grazi_db_init_schema.sql (prompt-fase-2 secao 7.2).
# ------------------------------------------------------------
criar_controle() {
  psql_exec -q -c "
    CREATE TABLE IF NOT EXISTS schema_migracao (
        arquivo      VARCHAR(200) PRIMARY KEY,
        aplicado_em  TIMESTAMPTZ NOT NULL DEFAULT now()
    );"
  log "schema_migracao pronta."
}

ja_aplicado() {
  local arquivo="$1" resposta
  resposta="$(consultar \
    "SELECT 1 FROM schema_migracao WHERE arquivo = '${arquivo}';")"
  [[ -n "${resposta//[[:space:]]/}" ]]
}

# ------------------------------------------------------------
# 3-5. Aplicacao de um arquivo, em UMA transacao
#
# O schema traz o proprio BEGIN/COMMIT. Migrations podem nao trazer.
# Envolvemos so quem precisa — envolver duas vezes faria o psql
# reclamar de transacao ja aberta.
#
# ON_ERROR_STOP=1 garante que o INSERT de registro so e alcancado
# se o arquivo inteiro passou.
# ------------------------------------------------------------
aplicar_arquivo() {
  local relativo="$1"
  local caminho="$RAIZ/$relativo"

  [[ -f "$caminho" ]] || { erro "arquivo nao encontrado: $relativo"; return 1; }

  if ja_aplicado "$relativo"; then
    log "ja aplicado, pulando: $relativo"
    return 0
  fi

  log "aplicando: $relativo"

  local registro="INSERT INTO schema_migracao (arquivo) VALUES ('${relativo}');"

  if grep -qiE '^[[:space:]]*BEGIN[[:space:]]*;' "$caminho"; then
    # Arquivo gerencia a propria transacao.
    { cat "$caminho"; printf '\n%s\n' "$registro"; } | psql_exec -q -f -
  else
    # Arquivo + registro na MESMA transacao.
    { printf 'BEGIN;\n'; cat "$caminho"; printf '\n%s\nCOMMIT;\n' "$registro"; } \
      | psql_exec -q -f -
  fi

  log "registrado: $relativo"
}

aplicar_migrations() {
  local encontrou=0
  # sort -V ordena 002 antes de 010, ao contrario da ordem de shell.
  while IFS= read -r caminho; do
    [[ -n "$caminho" ]] || continue
    encontrou=1
    aplicar_arquivo "migrations/$(basename "$caminho")"
  done < <(find "$RAIZ/migrations" -maxdepth 1 -name '*.sql' -type f 2>/dev/null | sort -V)

  (( encontrou )) || log "nenhuma migration a aplicar."
}

# ------------------------------------------------------------

main() {
  printf '\n== GraziFit: aplicando banco ==\n'
  aguardar_banco
  criar_controle
  aplicar_arquivo "$ARQUIVO_SCHEMA"
  aplicar_migrations

  local total
  total="$(consultar "
    SELECT count(*) FROM information_schema.tables
     WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
       AND table_name <> 'schema_migracao';")"
  printf '\n== concluido: %s tabelas de dominio ==\n\n' "${total//[[:space:]]/}"
}

main "$@"
