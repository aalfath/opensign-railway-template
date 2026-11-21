# OpenSign API: the Parse-based Node server from the pinned v3.2.0 commit.
# Upstream only publishes moving `main`/`staging` image tags, so we build from source.
FROM node:22.14.0-bookworm-slim@sha256:1c18d9ab3af4585870b92e4dbc5cac5a0dc77dd13df1a5905cea89fc720eb05b
ARG OPENSIGN_VERSION=v3.2.0
ARG OPENSIGN_COMMIT=f430730903ce988d98fec1f407321cbefa2ed9e8
# LibreOffice Writer (headless) converts DOCX uploads to PDF; openssl makes the signing certificate.
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates git openssl procps \
      libreoffice-writer-nogui fonts-dejavu-core fonts-liberation \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /usr/src/app
RUN git init -q /tmp/os && cd /tmp/os \
 && git remote add origin https://github.com/OpenSignLabs/OpenSign.git \
 && git fetch -q --depth 1 origin "$OPENSIGN_COMMIT" && git checkout -q FETCH_HEAD \
 && cp -a apps/OpenSignServer/. /usr/src/app/ && rm -r /tmp/os
RUN npm ci --omit=dev --no-audit --no-fund --loglevel=error && npm cache clean --force
COPY patch.sh bootstrap-admin.mjs wait-for-mongo.mjs start.sh /opt/railway/
RUN sh /opt/railway/patch.sh && chmod 755 /opt/railway/start.sh
ENV NODE_ENV=production OPENSIGN_VERSION=$OPENSIGN_VERSION
EXPOSE 8080
CMD ["/opt/railway/start.sh"]
