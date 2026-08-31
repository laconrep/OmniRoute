#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 01-start.sh — Start the full OmniRoute (dashboard + API) on a free host.
#
# Works on: GitHub Codespaces, Gitpod, or any Linux machine with Node >= 22.
# The server binds 0.0.0.0 so port forwarding / tunnels can reach it.
#
# Usage: bash scripts/deploy/free/01-start.sh [--prod]
#   --prod   build and run the standalone production server (slower first run)
# ---------------------------------------------------------------------------
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${REPO_ROOT}"

DATA_DIR="${DATA_DIR:-/workspaces/omniroute-data}"
export DATA_DIR

if [[ ! -f "${DATA_DIR}/.env" ]]; then
  echo "ERROR: ${DATA_DIR}/.env missing. Run: bash scripts/deploy/free/00-setup.sh"
  exit 1
fi

# Bind to all interfaces so the exposed port is reachable.
export HOSTNAME="0.0.0.0"
export HOST="0.0.0.0"
export BIND="0.0.0.0"

# OMNIROUTE_MEMORY_MB: free tiers usually have 512MB-2GB RAM.
# Clamp the V8 heap so the process fits instead of OOM-crashing.
MEM_MB="${OMNIROUTE_MEMORY_MB:-512}"
export OMNIROUTE_MEMORY_MB="${MEM_MB}"

MODE="${1:-dev}"
if [[ "${MODE}" == "--prod" ]]; then
  echo "==> Building production bundle (first run can take several minutes)..."
  npm run build
  echo "==> Starting production server on port 20128..."
  exec node scripts/dev/run-standalone.mjs
else
  echo "==> Starting dev server on port 20128 (dashboard) / 20129 (API)..."
  exec npm run dev
fi
