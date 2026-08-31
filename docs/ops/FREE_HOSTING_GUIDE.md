---
title: "OmniRoute Free Hosting — Combined Guide"
version: 3.8.51
lastUpdated: 2026-08-30
---

# OmniRoute Free Hosting (Combined Guide)

Run the **full** OmniRoute (dashboard + AI router + API) **completely free**,
with **no credit card**, by combining several free platforms so each one covers
what the others cannot.

## Why "combined"?

OmniRoute is a persistent Node.js app (SQLite, long-running proxy server,
WebSockets, native modules). No single free PaaS runs it end-to-end:

| Platform | What it's good at | Why it alone is not enough |
|---|---|---|
| GitHub Codespaces | Free Linux container, root, persistent disk | Sleeps when idle; dev quota |
| Gitpod | Same model, 50h/month | Sleeps when idle |
| Cloudflare Quick Tunnel | Free public URL, no account | Ephemeral URL, needs a server behind it |
| Turso / Upstash / Supabase | Free cloud DB / cache / KV | OmniRoute's core DB is file SQLite; use these for backup/extra |
| Vercel / Cloudflare Pages | Free static hosting | Can't run the proxy server |

**Combined recipe:** Codespaces (or Gitpod) hosts the process; platform port
forwarding gives the public URL; Cloudflare Quick Tunnel is the no-account
backup URL; git/archive backup protects the SQLite data; a keepalive keeps the
container from sleeping.

---

## 1. The combined stack

```
 Browser ──> public URL
              ├── Codespaces port-forward  https://<space>-20128.app.github.dev
              └── Cloudflare Quick Tunnel  https://<random>.trycloudflare.com
                        │
                        ▼
              OmniRoute server (port 20128, API 20129)
                        │  DATA_DIR=/workspaces/omniroute-data  (persistent volume)
                        ▼
              SQLite database + secrets  ── periodic backup ──> git / archive
```

---

## 2. Deploy on GitHub Codespaces (primary runtime)

1. Open your fork: `https://github.com/laconrep/OmniRoute`
2. Click **Code ▸ Codespaces ▸ Create codespace on release/v3.8.51**
   - This repo ships a `.devcontainer` → the container auto-builds with Node 24.
3. In the Codespaces terminal, run the combined launcher:

   ```bash
   bash scripts/deploy/free/run.sh
   ```

   Or step by step:

   ```bash
   bash scripts/deploy/free/00-setup.sh   # install deps + generate secrets
   bash scripts/deploy/free/01-start.sh   # start full app (dashboard + API)
   ```

4. Get your public URL:
   - Open the **Ports** tab, find port **20128**, click the globe icon → your
     `https://<space>-20128.app.github.dev` URL.
   - Optional: bake it into the app for OAuth/callbacks:

     ```bash
     FORWARDED_URL=https://<space>-20128.app.github.dev bash scripts/deploy/free/02-public-url.sh
     ```

5. Login: open the URL, default password is **CHANGEME** — change it in
   Dashboard ▸ Settings ▸ Security immediately.

> **Gitpod alternative:** the same `.devcontainer` is recognized by Gitpod.
> Open `https://gitpod.io/#https://github.com/laconrep/OmniRoute` and run the
> same scripts.

---

## 3. Backup public URL — Cloudflare Quick Tunnel (no account)

When you don't want to depend on the Codespaces URL, or you need a URL you can
paste anywhere, use OmniRoute's built-in tunnel. It auto-downloads `cloudflared`
and needs **no Cloudflare account or card**:

```bash
bash scripts/deploy/free/02-public-url.sh --cloudflared
```

You'll see a `https://<random>.trycloudflare.com` URL. Note: it changes on every
restart (use ngrok free / Tailscale Funnel if you need a stable name).

The tunnel is also manageable from the dashboard (see
`docs/ops/TUNNELS_GUIDE.md`).

---

## 4. Data backup — never lose the SQLite DB

Free containers can restart or sleep; the persistent volume keeps data, but an
off-host backup is the safety net. Snapshot + push to a private git repo:

```bash
DEST=git-repo \
  TARGET=https://github.com/laconrep/omniroute-backup.git \
  GIT_BRANCH=main \
  bash scripts/deploy/free/03-backup.sh
```

Or copy the archive to any mounted disk:

```bash
DEST=archive TARGET=/path/to/backup bash scripts/deploy/free/03-backup.sh
```

Add a cron/loop to back up every few hours:

```bash
# crontab -e  (every 6 hours)
0 */6 * * * DEST=git-repo TARGET=https://github.com/laconrep/omniroute-backup.git bash /workspaces/OmniRoute/scripts/deploy/free/03-backup.sh
```

---

## 5. Keepalive — stop free hosts from sleeping

Codespaces/Gitpod sleep after inactivity. A cheap keepalive pings your public
URL every ~5 minutes from anywhere (a cron on your own machine, a free
Cloudflare Worker, or GitHub Actions scheduled job):

```yaml
# .github/workflows/keepalive.yml (in a repo with Actions enabled)
name: keepalive
on:
  schedule:
    - cron: "*/5 * * * *"
jobs:
  ping:
    runs-on: ubuntu-latest
    steps:
      - run: curl -fsSI -m 30 "${{ vars.OMNIROUTE_URL }}" || true
```

Set `OMNIROUTE_URL` as a repository variable to your public URL. (Free Actions
minutes apply; a 5-min ping uses ~0.2 min/day.)

---

## 6. Optional — free cloud DB sidecars

- **Turso** (free SQLite-compatible cloud DB): use for a replicated read-only
  copy or as a second backup target.
- **Upstash** (free Redis): point `REDIS_URL` at it for shared caching instead
  of the local Redis fallback.
- **Supabase / Neon** (free Postgres): not the primary store (OmniRoute uses
  file SQLite), but usable for log/analytics export.

These are additive — the app runs with zero cloud dependencies out of the box.

---

## 7. Reference — scripts

| Script | Purpose |
|---|---|
| `.devcontainer/devcontainer.json` | Codespaces/Gitpod container (Node 24, tools) |
| `.devcontainer/scripts/post-create.sh` | deps + secrets on first boot |
| `.devcontainer/scripts/start.sh` | start app inside the container |
| `scripts/deploy/free/00-setup.sh` | install deps + generate `.env`/secrets |
| `scripts/deploy/free/01-start.sh` | start full app (`--prod` for prod build) |
| `scripts/deploy/free/02-public-url.sh` | print port-forward URL or Cloudflare tunnel |
| `scripts/deploy/free/03-backup.sh` | snapshot `DATA_DIR` to git/archive |
| `scripts/deploy/free/run.sh` | one-command combined runner |

---

## 8. Success indicators

- Logs show `[bootstrap] DATA_DIR resolved to: /workspaces/omniroute-data`
- `curl http://localhost:20128/healthz` returns `200`
- Dashboard loads over the public URL and you can log in
- `ls ${DATA_DIR}` shows `server.env` + `storage.sqlite`
