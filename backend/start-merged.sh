#!/usr/bin/env bash
# Entrypoint for the merged Railway service: runs Open WebUI, the LAMB backend
# and Caddy in one container so the backend can read OWI's webui.db from the
# shared volume (Railway volumes cannot be shared across services).
set -m

echo "[merged] starting Open WebUI on :8080 (DATA_DIR=${DATA_DIR:-/opt/lamb/owi-data})"
# Scope PORT=8080 to OWI only; Caddy keeps Railway's $PORT.
( cd /app/backend && PORT=8080 HOST=0.0.0.0 bash start.sh ) &
OWI_PID=$!

echo "[merged] starting LAMB backend on :9099"
# The backend blocks at startup until OWI creates webui.db on the shared volume,
# then continues — so parallel start is fine.
( cd /lamb/backend && /lamb/venv/bin/uvicorn main:app --host 0.0.0.0 --port 9099 --forwarded-allow-ips '*' ) &
LAMB_PID=$!

echo "[merged] starting Caddy on :${PORT}"
caddy run --config /lamb/Caddyfile --adapter caddyfile &
CADDY_PID=$!

# If any of the three processes exits, tear the whole container down so Railway
# restarts it (a half-running container is never healthy).
wait -n
echo "[merged] a managed process exited; shutting down container"
kill "$OWI_PID" "$LAMB_PID" "$CADDY_PID" 2>/dev/null
exit 1
