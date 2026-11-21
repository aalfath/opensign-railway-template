# Changelog

Breaking changes are listed first in each entry. Deployers get an "update available" notice on Railway when `main` changes; read the entry before you apply it.

## v3.2.0-railway.1 (2026-11-21)

- First release of the template: OpenSign v3.2.0 (commit `f430730`), built from source because upstream publishes only moving `main`/`staging` image tags.
- Services: `opensign` (web app + `/api` gateway on Caddy 2.11.9), `opensign-api` (Parse server, Node 22.14.0, LibreOffice for DOCX) with a `/data` volume, and Railway's MongoDB.
- The first administrator is created from `OPENSIGN_ADMIN_EMAIL` / `OPENSIGN_ADMIN_PASSWORD` after the database migrations finish; the public `addadmin` call is closed.
- A self-signed document-signing certificate is generated once and kept on the volume, unless you supply `PFX_BASE64`.
