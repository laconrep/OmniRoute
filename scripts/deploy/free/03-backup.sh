#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 03-backup.sh — Back up the persistent OmniRoute data (SQLite DB + secrets)
# to an off-host destination so free-host restarts never lose data.
#
# Supported destinations (pick one):
#   DEST=git-repo   TARGET=<gitURL> [GIT_BRANCH=<branch>]   push to a git repo
#   DEST=archive    TARGET=<dir>                             copy to a mounted disk
#
# Default: tar.gz snapshot written to the repo (gitignored) + optionally pushed.
#
# Usage:
#   DEST=git-repo TARGET=https://github.com/you/omniroute-backup.git \
#     GIT_BRANCH=main bash scripts/deploy/free/03-backup.sh
# ---------------------------------------------------------------------------
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${REPO_ROOT}"

DATA_DIR="${DATA_DIR:-/workspaces/omniroute-data}"
SNAPSHOT="${REPO_ROOT}/.backup/omniroute-$(date -u +%Y%m%d-%H%M%S).tar.gz"
mkdir -p "${REPO_ROOT}/.backup"

echo "==> Backing up ${DATA_DIR} -> ${SNAPSHOT}"
tar --exclude="${DATA_DIR}/cache" -czf "${SNAPSHOT}" -C "$(dirname "${DATA_DIR}")" "$(basename "${DATA_DIR}")"

DEST="${DEST:-local}"
case "${DEST}" in
  archive)
    TARGET="${TARGET:?TARGET dir required}"
    mkdir -p "${TARGET}"
    cp "${SNAPSHOT}" "${TARGET}/"
    echo "==> Copied to ${TARGET}/"
    ;;
  git-repo)
    TARGET="${TARGET:?TARGET git URL required}"
    GIT_BRANCH="${GIT_BRANCH:-main}"
    BACKUP_CLONE="${REPO_ROOT}/.backup/repo"
    rm -rf "${BACKUP_CLONE}"
    git clone --depth 1 -b "${GIT_BRANCH}" "${TARGET}" "${BACKUP_CLONE}" 2>/dev/null || {
      mkdir -p "${BACKUP_CLONE}"
      git -C "${BACKUP_CLONE}" init -b "${GIT_BRANCH}"
    }
    git -C "${BACKUP_CLONE}" remote remove origin 2>/dev/null || true
    git -C "${BACKUP_CLONE}" remote add origin "${TARGET}"
    cp "${SNAPSHOT}" "${BACKUP_CLONE}/"
    git -C "${BACKUP_CLONE}" add -A
    git -C "${BACKUP_CLONE}" -c user.email="backup@omniroute" -c user.name="OmniRoute Backup" \
      commit -m "backup $(date -u +%Y-%m-%dT%H:%M:%SZ)" 2>/dev/null || true
    git -C "${BACKUP_CLONE}" push origin "${GIT_BRANCH}" 2>&1 || echo "!! push failed (check TARGET credentials)"
    ;;
  *)
    echo "==> Local snapshot only: ${SNAPSHOT}"
    ;;
esac

echo "==> Backup complete."
