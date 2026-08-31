#!/usr/bin/env bash
set -euo pipefail

echo "==> OmniRoute free-hosting bootstrap (Codespaces / Gitpod)"

# Persistent data lives on the mounted volume so SQLite survives container restarts.
DATA_DIR="/workspaces/omniroute-data"
mkdir -p "${DATA_DIR}"
export DATA_DIR

# Install npm dependencies (this repo is large; use npm ci for reproducibility).
if [[ -f package-lock.json ]]; then
  echo "==> Installing dependencies with npm ci (this can take a while)..."
  npm ci --no-audit --no-fund || { echo "npm ci failed, falling back to npm install"; npm install --no-audit --no-fund; }
else
  npm install --no-audit --no-fund
fi

# Generate a .env only if missing (never overwrite existing config / secrets).
if [[ ! -f "${DATA_DIR}/.env" ]]; then
  echo "==> Generating ${DATA_DIR}/.env with fresh secrets..."
  cp .env.example "${DATA_DIR}/.env"

  gen_hex() { openssl rand -hex "${1:-32}"; }
  gen_b64() { openssl rand -base64 "${1:-48}" | tr -d '\n'; }

  # Required secrets
  sed -i "s~^JWT_SECRET=.*~JWT_SECRET=$(gen_b64 48)~" "${DATA_DIR}/.env"
  sed -i "s~^API_KEY_SECRET=.*~API_KEY_SECRET=$(gen_hex 32)~" "${DATA_DIR}/.env"
  sed -i "s~^STORAGE_ENCRYPTION_KEY=.*~STORAGE_ENCRYPTION_KEY=$(gen_hex 32)~" "${DATA_DIR}/.env"
  sed -i "s~^MACHINE_ID_SALT=.*~MACHINE_ID_SALT=$(gen_hex 32)~" "${DATA_DIR}/.env"
  sed -i "s~^# OMNIROUTE_WS_BRIDGE_SECRET=.*~OMNIROUTE_WS_BRIDGE_SECRET=$(gen_hex 32)~" "${DATA_DIR}/.env"

  # Persistence + host bindings for the sandbox.
  sed -i "s|^# DATA_DIR=.*|DATA_DIR=${DATA_DIR}|" "${DATA_DIR}/.env"
  sed -i "s/^PORT=.*/PORT=20128/" "${DATA_DIR}/.env"
  sed -i "s/^# API_PORT=.*/API_PORT=20129/" "${DATA_DIR}/.env"
  sed -i "s/^# API_HOST=.*/API_HOST=0.0.0.0/" "${DATA_DIR}/.env"

  echo "==> Generated. Default login password is CHANGEME (change it after first login)."
else
  echo "==> Found existing ${DATA_DIR}/.env — keeping it."
fi

echo "==> Bootstrap complete."
echo "    DATA_DIR=${DATA_DIR}"
echo "    Next step: bash .devcontainer/scripts/start.sh"
