# Deploy and Host OpenSign on Railway

OpenSign is an open-source e-signature platform and a self-hosted alternative to DocuSign. You upload a PDF, place signature, initials, date and text fields, and send it to signers by e-mail or link. Completed documents are digitally signed and come with a completion certificate and an audit trail of who signed, when and from where.

## About Hosting OpenSign

OpenSign has three parts: a React web app, a Node.js API built on Parse Server, and MongoDB. This template builds OpenSign v3.2.0 from its pinned release commit, because upstream only publishes moving `main` and `staging` image tags. Railway's edge gives you HTTPS. A small Caddy server in the `opensign` service serves the web app and forwards `/api` to the API over the private network, the job upstream's Caddy container does. Uploaded and signed documents and the signing certificate are kept on a volume, and MongoDB has its own volume. The first administrator is created from deploy variables, so nobody can claim a fresh URL before you.

## Common Use Cases

* Send contracts, NDAs, offer letters and invoices for signature without a per-envelope subscription
* Keep signed documents and their audit trails on infrastructure you control
* Reusable templates and public signing links for forms that many people sign

## Dependencies for OpenSign Hosting

* MongoDB (Railway service from the official `mongo:7.0.48` image, with its own volume)
* A volume on the API service for documents and the signing certificate (included)

### Deployment Dependencies

* OpenSign source and releases: https://github.com/OpenSignLabs/OpenSign (v3.2.0)
* Self-hosting guide: https://docs.opensignlabs.com/docs/self-host/intro
* Template repository: https://github.com/aalfath/opensign-railway-template

### Implementation Details

Services:

* `opensign`: the public web app on Caddy 2.11.9. Serves the single-page app, forwards `/api/*` to `opensign-api`, health check `/healthz`.
* `opensign-api`: OpenSign's Parse Server API (Node 22.14.0, LibreOffice for DOCX to PDF), volume at `/data`, health check `/app/health`. It waits for MongoDB, runs upstream's database migrations, then creates the administrator.
* `MongoDB`: `mongo:7.0.48`, volume at `/data/db`, user and password generated at deploy.

After deploy:

1. Open the `opensign` service's URL and sign in with `OPENSIGN_ADMIN_EMAIL` and the password in `OPENSIGN_ADMIN_PASSWORD` (generated unless you set your own; read it in the `opensign-api` service's Variables tab). Change it under your profile.
2. Invite more people from Settings, Users. There is no public sign-up for a new organisation.
3. To send signing invitations by e-mail, add SMTP settings to `opensign-api`: `SMTP_ENABLE=true`, `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASS` and `SMTP_USER_EMAIL` (the sender). Without them you can still sign yourself and share signing links.
4. Documents are signed with a self-signed certificate made at first start (`/data/certs/opensign.pfx`, protected by `PASS_PHRASE`). To use a certificate from a trusted authority, set `PFX_BASE64` (the base64 of your `.pfx`) and `PASS_PHRASE` on `opensign-api`.

Updates: the services build from `aalfath/opensign-railway-template`. When it moves to a new OpenSign release, Railway shows you an update notice; read `CHANGELOG.md` first, then apply it.

## Why Deploy OpenSign on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying OpenSign on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
