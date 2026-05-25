# Merge backend + Open WebUI into one Railway service

Date: 2026-05-25

## Problem

On Railway, LAMB was split into 4 services (backend, owi, kb, frontend). The
LAMB backend reads OWI's `webui.db` **directly from the filesystem**
(`OwiDatabaseManager`, instantiated unconditionally at import in
`creator_interface/assistant_router.py` and `lamb/owi_bridge/owi_router.py`, plus
12+ call sites). It blocks at startup waiting for `OWI_PATH/webui.db`.

Railway volumes cannot be shared between services, so a standalone backend can
never see OWI's `webui.db` → the backend never becomes healthy.

## Decision

Run **OWI + LAMB backend + Caddy in one container** (reusing the existing
`k4j-edu-backend` service and its volume), so both apps share one `webui.db`.
This mirrors the docker-compose design (shared `LAMB_PROJECT_PATH`). Fresh start —
no migration of the old `k4j-edu-owi` volume.

## Architecture

One image, three processes, one volume (mounted at `/opt/lamb`):

- **Caddy** listens on Railway's `$PORT` (the only public entrypoint), routes by
  Host header: `k4j-edu-owi.up.railway.app` → OWI (`localhost:8080`); everything
  else (api domain + Railway healthcheck) → backend (`localhost:9099`).
- **OWI** on `:8080`, `DATA_DIR=/opt/lamb/owi-data` → writes `webui.db` there.
- **backend** on `:9099`, `OWI_PATH=/opt/lamb/owi-data` → reads the same `webui.db`.
  Its startup wait-loop naturally blocks until OWI creates the file, then serves.

Build: `FROM ghcr.io/open-webui/open-webui:v0.8.10`, add Caddy binary (from the
`caddy:2` image), apply the OWI branding patch, install the LAMB backend into an
isolated venv (`/lamb/venv`) to avoid dependency conflicts, then run all three via
`start-merged.sh`. Build context stays `backend/`.

## Files

- `backend/Dockerfile.merged` — the merged image
- `backend/Caddyfile` — host-based reverse proxy
- `backend/start-merged.sh` — launches OWI, backend, Caddy; exits if any dies
- `backend/deploy/patch-openwebui.sh` — copy of the OWI patch (build-context local)
- `backend/railway.toml` — `dockerfilePath=backend/Dockerfile.merged`, no
  startCommand, `healthcheckPath=/docs`, `healthcheckTimeout=300`

## Env var changes (k4j-edu-backend service)

- `OWI_BASE_URL=http://localhost:8080` (backend→OWI now in-container)
- `OWI_PUBLIC_BASE_URL=https://k4j-edu-owi.up.railway.app` (browser redirects)
- `DATA_DIR=/opt/lamb/owi-data` (OWI data on shared volume)
- `WEBUI_URL=https://k4j-edu-owi.up.railway.app` (OWI's own URL)
- `WEBUI_SECRET_KEY=<same value used for LAMB JWT>` (token interop)
- unchanged: `LAMB_*`, `OPENAI_*`, `OWI_ADMIN_*`, `OWI_PATH`, `LAMB_DB_PATH`

## Railway dashboard actions (manual)

1. Move the `k4j-edu-owi` public domain onto the `k4j-edu-backend` service.
2. Stop/delete the standalone `k4j-edu-owi` service.
3. Set the env vars above; redeploy backend.

## Out of scope

Refactoring the OWI bridge to use OWI's HTTP API instead of direct DB access
(the proper long-term decoupling) — tracked separately.
