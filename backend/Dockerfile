# syntax=docker/dockerfile:1
#
# Backend do GraziFit para DESENVOLVIMENTO: `dart run` (JIT), sem AOT.
# Contexto de build = raiz do repositorio, porque o backend depende de
# ../shared (path dependency). O .dockerignore da raiz mantem .env e .git
# fora do contexto. Nenhum segredo entra na imagem: DATABASE_URL e
# SENHA_PEPPER chegam so em runtime, pelo environment do compose.

# Versao fixa vinda do .env (DART_VERSION), repassada pelo compose.
ARG DART_VERSION

# ------------------------------------------------------------
# base: SDK + usuario sem privilegio
# ------------------------------------------------------------
FROM dart:${DART_VERSION} AS base

RUN useradd --create-home --uid 10001 --shell /usr/sbin/nologin grazifit \
    && mkdir -p /app/backend /app/shared \
    && chown -R grazifit:grazifit /app

USER grazifit
ENV PUB_CACHE=/home/grazifit/.pub-cache
WORKDIR /app/backend

# ------------------------------------------------------------
# dependencias: so os pubspecs. Esta camada so e refeita quando um
# pubspec/lock muda. --enforce-lockfile falha se o lock divergir.
# ------------------------------------------------------------
FROM base AS dependencias

COPY --chown=grazifit:grazifit shared/pubspec.yaml shared/pubspec.lock /app/shared/
COPY --chown=grazifit:grazifit backend/pubspec.yaml backend/pubspec.lock /app/backend/
RUN dart pub get --enforce-lockfile

# ------------------------------------------------------------
# desenvolvimento: codigo-fonte por cima das dependencias ja baixadas.
# O pub get --offline so religa o package_config ao codigo copiado.
# ------------------------------------------------------------
FROM dependencias AS desenvolvimento

COPY --chown=grazifit:grazifit shared/ /app/shared/
COPY --chown=grazifit:grazifit backend/ /app/backend/
RUN dart pub get --enforce-lockfile --offline

# A porta de escuta vem de SERVER_PORT (config.dart); o compose a publica.
CMD ["dart", "run", "bin/server.dart"]
