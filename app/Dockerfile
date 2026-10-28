# syntax=docker/dockerfile:1
#
# App Flutter (Web) para DESENVOLVIMENTO: `flutter run -d web-server`,
# com hot reload acionado pelo compose watch (SIGUSR1 via --pid-file).
# Sem nginx e sem build estatico: isso so faz sentido quando houver deploy.
#
# Contexto de build = raiz do repositorio (mesmo .dockerignore do backend).
# CUSTO: o SDK do Flutter deixa a imagem com ~2 a ~3 GB e o primeiro build
# leva ~15 a ~20 min (depende da rede; ver docs/guia-desenvolvimento.md
# secao 12.6). E pago uma vez por maquina e so por quem usa
# COMPOSE_PROFILES=web; trocar FLUTTER_VERSION ou limpar o cache do Docker
# repete o custo.

# Versoes fixas vindas do .env, repassadas pelo compose.
ARG DART_VERSION

# ------------------------------------------------------------
# sdk: Flutter clonado pela tag exata + artefatos web pre-baixados.
# Base = a mesma imagem oficial do Dart usada pelo backend (ja traz git,
# curl e unzip), para nao depender de imagem de terceiros.
# ------------------------------------------------------------
FROM dart:${DART_VERSION} AS sdk

ARG FLUTTER_VERSION

RUN useradd --create-home --uid 10001 --shell /usr/sbin/nologin grazifit \
    && mkdir -p /opt/flutter /app/app \
    && chown -R grazifit:grazifit /opt/flutter /app

USER grazifit
ENV PUB_CACHE=/home/grazifit/.pub-cache \
    PATH=/opt/flutter/bin:${PATH}
# Diretorio do proprio usuario: o diretorio herdado da imagem base (/root)
# e ilegivel para ele, e o bootstrap do Flutter (find) falha nele.
WORKDIR /app/app

RUN test -n "${FLUTTER_VERSION}" \
    && git clone --depth 1 --branch "${FLUTTER_VERSION}" \
       https://github.com/flutter/flutter.git /opt/flutter

RUN flutter config --no-analytics --no-cli-animations \
    && flutter precache --web \
    && flutter --version

# ------------------------------------------------------------
# dependencias: so os pubspecs. --enforce-lockfile falha se o lock divergir.
# ------------------------------------------------------------
FROM sdk AS dependencias

# `shared/` entra aqui porque o app o referencia por path (../shared).
COPY --chown=grazifit:grazifit shared/ /app/shared/
COPY --chown=grazifit:grazifit app/pubspec.yaml app/pubspec.lock ./
RUN flutter pub get --enforce-lockfile

# ------------------------------------------------------------
# desenvolvimento: codigo-fonte por cima das dependencias ja baixadas.
# O comando (porta, --pid-file, API_BASE_URL) fica no docker-compose.yml,
# porque depende de valores do .env.
# ------------------------------------------------------------
FROM dependencias AS desenvolvimento

COPY --chown=grazifit:grazifit app/ ./
RUN flutter pub get --enforce-lockfile --offline
