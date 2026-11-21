#!/bin/sh
# Start script for the OpenSign API on Railway.
set -eu
cd /usr/src/app

DATA_DIR="${DATA_DIR:-/data}"
export PORT=8080            # the server calls itself on http://localhost:8080/app (hardcoded upstream)
export PARSE_MOUNT=/app     # upstream: "Do not change this"
export USE_LOCAL="${USE_LOCAL:-true}"
export APP_ID="${APP_ID:-opensign}"

if [ -z "${MASTER_KEY:-}" ]; then
  echo "[railway] MASTER_KEY is empty: set it (the template generates one)." >&2; exit 1
fi
if [ -z "${MONGODB_URI:-}" ]; then
  echo "[railway] MONGODB_URI is empty: point it at the MongoDB service." >&2; exit 1
fi

# Uploaded and signed documents live on the volume. Parse's file adapter writes to ./files/files;
# ./files itself holds upstream's e-mail templates, so only the subfolder is linked.
mkdir -p "$DATA_DIR/files" "$DATA_DIR/certs" exports
if [ ! -L files/files ]; then
  if [ -d files/files ]; then cp -a files/files/. "$DATA_DIR/files/" && rm -r files/files; fi
  ln -s "$DATA_DIR/files" files/files
fi

# Document-signing certificate. Use the deployer's own PKCS#12 (PFX_BASE64 + PASS_PHRASE) if given,
# otherwise a self-signed one generated once and kept on the volume.
if [ -z "${PFX_BASE64:-}" ]; then
  PFX="$DATA_DIR/certs/opensign.pfx"
  : "${PASS_PHRASE:?PASS_PHRASE is empty: the template generates one}"
  if [ -s "$PFX" ] && ! openssl pkcs12 -in "$PFX" -passin env:PASS_PHRASE -noout 2>/dev/null; then
    echo "[railway] existing signing certificate doesn't open with PASS_PHRASE; making a new one"
    mv "$PFX" "$PFX.unreadable.$(date +%s)"
  fi
  if [ ! -s "$PFX" ]; then
    echo "[railway] generating a self-signed document-signing certificate (10 years)"
    tmp=$(mktemp -d)
    openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 3650 \
      -subj "/CN=${OPENSIGN_CERT_NAME:-OpenSign self-hosted}/O=OpenSign" \
      -keyout "$tmp/key.pem" -out "$tmp/cert.pem" 2>/dev/null
    # 3DES/SHA1 PKCS#12: the format node-forge (used by OpenSign's signer) can read.
    openssl pkcs12 -export -inkey "$tmp/key.pem" -in "$tmp/cert.pem" -name opensign \
      -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1 \
      -passout env:PASS_PHRASE -out "$PFX"
    rm -r "$tmp"
    chmod 600 "$PFX"
  fi
  PFX_BASE64=$(base64 -w0 "$PFX")
  export PFX_BASE64
fi

node /opt/railway/wait-for-mongo.mjs

# Create the first administrator from the deploy variables once the API answers.
node /opt/railway/bootstrap-admin.mjs &

echo "[railway] starting OpenSign API ${OPENSIGN_VERSION:-}"
exec node index.js
