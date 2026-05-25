#!/usr/bin/env bash
# Entrypoint for the merged Railway service: runs Open WebUI, the LAMB backend
# and Caddy in one container so the backend can read OWI's webui.db from the
# shared volume (Railway volumes cannot be shared across services).
set -m

# The volume mounts empty at /opt/lamb and sqlite won't create missing parent
# directories, so create the data dirs at runtime (build-time mkdir is hidden by
# the volume mount). OWI's webui.db lives in DATA_DIR; LAMB's db in LAMB_DB_PATH.
DATA_DIR="${DATA_DIR:-/opt/lamb/owi-data}"
export DATA_DIR
mkdir -p "$DATA_DIR" "${LAMB_DB_PATH:-/opt/lamb}"

# Railway's $PORT is 8080 and Caddy binds it, so OWI must use a different port.
# Override OWI_BASE_URL here so the backend reaches OWI directly (not Caddy),
# regardless of what's configured in the service env.
OWI_INTERNAL_PORT=8081
export OWI_BASE_URL="http://localhost:${OWI_INTERNAL_PORT}"

echo "[merged] starting Open WebUI on :${OWI_INTERNAL_PORT} (DATA_DIR=$DATA_DIR)"
# Scope PORT to OWI only; Caddy keeps Railway's $PORT.
( cd /app/backend && PORT=$OWI_INTERNAL_PORT HOST=0.0.0.0 bash start.sh ) &
OWI_PID=$!

# Wait for OWI to accept connections before starting the backend: the backend
# calls OWI's API at startup (admin-user creation) and would otherwise race ahead
# while OWI is still running migrations / loading its embedding model.
echo "[merged] waiting for OWI on :${OWI_INTERNAL_PORT} before starting backend..."
for _ in $(seq 1 150); do
  if (exec 3<>"/dev/tcp/127.0.0.1/${OWI_INTERNAL_PORT}") 2>/dev/null; then
    exec 3>&- 2>/dev/null
    echo "[merged] OWI is accepting connections"
    break
  fi
  sleep 2
done

echo "[merged] starting LAMB backend on :9099 (OWI_BASE_URL=$OWI_BASE_URL)"
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
