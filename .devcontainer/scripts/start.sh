#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="/workspaces/omniroute-data"

echo "==> OmniRoute start (free-hosting)"
echo "    DATA_DIR=${DATA_DIR}"

if [[ ! -f "${DATA_DIR}/.env" ]]; then
  echo "ERROR: ${DATA_DIR}/.env not found. Run post-create (or bash .devcontainer/scripts/post-create.sh) first."
  exit 1
fi

# Bind to all interfaces so port forwarding (Codespaces / Gitpod / Cloudflare Tunnel) can reach the app.
export DATA_DIR
export HOSTNAME="0.0.0.0"
export HOST="0.0.0.0"
export BIND="0.0.0.0"

# Point the standalone launcher at the persistent .env (bootstrap picks it up from DATA_DIR).
if [[ -f "${DATA_DIR}/.env" ]]; then
  export OMNIROUTE_ENV_FILE="${DATA_DIR}/.env"
fi

echo "==> Starting OmniRoute on port 20128 (dashboard) / 20129 (API)..."
echo "    Codespaces: open the 'OmniRoute Dashboard' forwarded port to get your public URL."
echo "    Or run: bash scripts/deploy/free/02-tunnel.sh   (Cloudflare Quick Tunnel, free, no card)"

# Dev mode is the fastest free-hosting path. Use `npm start` after a full `npm run build` for prod.
exec npm run dev
