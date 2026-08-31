#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 00-setup.sh — Prepare OmniRoute for free self-hosting (Codespaces / Gitpod /
# any Linux sandbox with a persistent disk). No card, no paid plan.
#
# Usage: bash scripts/deploy/free/00-setup.sh
# ---------------------------------------------------------------------------
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${REPO_ROOT}"

# Default persistent data dir. Override with: DATA_DIR=/path bash .../00-setup.sh
DATA_DIR="${DATA_DIR:-${WORKSPACE_DIR:-/workspaces/omniroute-data}}"
mkdir -p "${DATA_DIR}"

echo "==> OmniRoute free-hosting setup"
echo "    DATA_DIR=${DATA_DIR}"

# 1. Install dependencies (npm ci preferred; fall back to install).
if [[ -f package-lock.json ]]; then
  npm ci --no-audit --no-fund 2>/dev/null || npm install --no-audit --no-fund
else
  npm install --no-audit --no-fund
fi

# 2. Bootstrap secrets + .env on first run.
ENV_FILE="${DATA_DIR}/.env"
if [[ ! -f "${ENV_FILE}" ]]; then
  cp .env.example "${ENV_FILE}"

  gen_hex() { openssl rand -hex "${1:-32}"; }
  gen_b64() { openssl rand -base64 "${1:-48}" | tr -d '\n'; }

  sed -i "s~^JWT_SECRET=.*~JWT_SECRET=$(gen_b64 48)~" "${ENV_FILE}"
  sed -i "s~^API_KEY_SECRET=.*~API_KEY_SECRET=$(gen_hex 32)~" "${ENV_FILE}"
  sed -i "s~^STORAGE_ENCRYPTION_KEY=.*~STORAGE_ENCRYPTION_KEY=$(gen_hex 32)~" "${ENV_FILE}"
  sed -i "s~^MACHINE_ID_SALT=.*~MACHINE_ID_SALT=$(gen_hex 32)~" "${ENV_FILE}"
  sed -i "s~^# OMNIROUTE_WS_BRIDGE_SECRET=.*~OMNIROUTE_WS_BRIDGE_SECRET=$(gen_hex 32)~" "${ENV_FILE}"

  # Uncomment + set DATA_DIR (bootstrap also reads it from process.env, which wins).
  sed -i "s|^# DATA_DIR=.*|DATA_DIR=${DATA_DIR}|" "${ENV_FILE}"
  sed -i "s/^PORT=.*/PORT=20128/" "${ENV_FILE}"
  sed -i "s/^# API_PORT=.*/API_PORT=20129/" "${ENV_FILE}"
  sed -i "s/^# API_HOST=.*/API_HOST=0.0.0.0/" "${ENV_FILE}"
  echo "==> Generated ${ENV_FILE} with fresh secrets."
else
  echo "==> Using existing ${ENV_FILE}."
fi

echo "==> Setup done. Next: bash scripts/deploy/free/01-start.sh"
