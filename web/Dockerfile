# OpenSign web: the React single-page app, built from the pinned v3.2.0 commit,
# served by Caddy, which also forwards /api/* to the API service over Railway's
# private network (this replaces upstream's Caddy + client containers).
# Upstream only publishes moving `main`/`staging` image tags, so we build from source.
FROM node:22.14.0-bookworm@sha256:e5ddf893cc6aeab0e5126e4edae35aa43893e2836d1d246140167ccc2616f5d7 AS build
ARG OPENSIGN_VERSION=v3.2.0
ARG OPENSIGN_COMMIT=f430730903ce988d98fec1f407321cbefa2ed9e8
ARG NODE_HEAP_MB=6144
WORKDIR /src
RUN git init -q && git remote add origin https://github.com/OpenSignLabs/OpenSign.git \
 && git fetch -q --depth 1 origin "$OPENSIGN_COMMIT" && git checkout -q FETCH_HEAD
WORKDIR /src/apps/OpenSign
RUN npm ci --no-audit --no-fund --loglevel=error
# Same steps as upstream's apps/OpenSign/Dockerhubfile, without the GitHub API call in `npm run version`.
RUN printf '%s\n' "$OPENSIGN_VERSION" > public/version.txt \
 && NODE_ENV=production GENERATE_SOURCEMAP=false NODE_OPTIONS=--max-old-space-size=$NODE_HEAP_MB npx vite build \
 && sed -i '/<head>/a\<script src="/env.js"></script>' build/index.html \
 && sh ./entrypoint.sh true \
 && test -s build/env.js && test -s build/index.html

FROM caddy:2.11.9-alpine@sha256:003a97808e781aa9f7e75cc2f43d34d461099031faf5e20faefb9f61126836f0
COPY --from=build /src/apps/OpenSign/build /srv
COPY Caddyfile /etc/caddy/Caddyfile
ENV PORT=8080
EXPOSE 8080
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
