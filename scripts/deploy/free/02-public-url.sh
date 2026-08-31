#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 02-public-url.sh — Print the public URL and (optionally) enable a free tunnel.
#
# A free host gives you a public URL in one of these ways:
#   1. Platform port forwarding (Codespaces: *.app.github.dev, Gitpod: *.gitpod.io)
#      — set FORWARDED_URL when the platform already exposes the port.
#   2. OmniRoute's built-in Cloudflare Quick Tunnel (free, no card, no account)
#      — managed from the dashboard, or enable below.
#
# Usage:
#   FORWARDED_URL=https://xxx.app.github.dev bash scripts/deploy/free/02-public-url.sh
#   bash scripts/deploy/free/02-public-url.sh --cloudflared
# ---------------------------------------------------------------------------
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${REPO_ROOT}"

DATA_DIR="${DATA_DIR:-/workspaces/omniroute-data}"
export DATA_DIR

if [[ -n "${FORWARDED_URL:-}" ]]; then
  echo "==> Public URL (platform port forwarding):"
  echo "    ${FORWARDED_URL}"
  echo "    Set NEXT_PUBLIC_BASE_URL=${FORWARDED_URL} in ${DATA_DIR}/.env for OAuth/callbacks."
  exit 0
fi

if [[ "${1:-}" == "--cloudflared" ]]; then
  if ! command -v cloudflared >/dev/null 2>&1; then
    echo "==> Installing cloudflared..."
    case "$(uname -m)" in
      x86_64) CF_ARCH="amd64" ;;
      aarch64|arm64) CF_ARCH="arm64" ;;
      *) echo "Unsupported arch: $(uname -m)"; exit 1 ;;
    esac
    curl -fsSL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}" -o /usr/local/bin/cloudflared
    chmod +x /usr/local/bin/cloudflared
  fi
  echo "==> Starting Cloudflare Quick Tunnel -> public URL (ephemeral):"
  exec cloudflared tunnel --url http://127.0.0.1:20128
fi

echo "==> Detect your public URL:"
echo "   - Codespaces: Ports tab -> open the 20128 port -> use that *.app.github.dev URL."
echo "   - Gitpod: 20128 is auto-exposed as *.gitpod.io."
echo "   - Or run: bash scripts/deploy/free/02-public-url.sh --cloudflared  (free tunnel)"
