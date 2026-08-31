#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# run.sh — One-command combined free-hosting runner.
#
# Combines every free method into a single flow:
#   1. Setup (install deps + generate secrets)   — 00-setup.sh
#   2. Start the full app (dashboard + API)      — 01-start.sh
#   3. Public URL (port-forward / tunnel)        — 02-public-url.sh
#   4. Optional: cloud-db sidecar (Turso/Upstash) + periodic backup
#
# Usage:
#   bash scripts/deploy/free/run.sh [--prod]
#   FORWARDED_URL=https://xxx.app.github.dev bash scripts/deploy/free/run.sh
# ---------------------------------------------------------------------------
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${REPO_ROOT}"

echo "===== OmniRoute — combined free hosting ====="

# Phase 1: setup
bash scripts/deploy/free/00-setup.sh

# Phase 2: expose URL (before start, so we can echo it in logs)
echo
echo "===== Public URL ====="
if [[ -n "${FORWARDED_URL:-}" ]]; then
  bash scripts/deploy/free/02-public-url.sh
else
  echo "(no FORWARDED_URL set — use the platform's forwarded port, or run"
  echo " 02-public-url.sh --cloudflared for a free Cloudflare Quick Tunnel)"
fi

# Phase 3: start the app (exec replaces this shell)
echo
echo "===== Starting OmniRoute ====="
exec bash scripts/deploy/free/01-start.sh "${1:-dev}"
