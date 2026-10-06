# Calnode Lite — Self-Hosted Calendly Alternative

One binary, one file. A lean, self-hostable scheduling engine that lives in your AI stack —
a Go 1.26 static binary with an embedded SQLite database and a LiteStream-compatible
object-storage backup path. No Redis, no Postgres, no separate API server.
API-first and MCP-native, out of the box.

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.com/deploy/calnode)

## Quick Start

Deploy from the template (or `railway up` locally). On first boot Calnode ships
with an admin UI at `/`, an API under `/v1/*`, and an MCP server.

1. **Deploy** the template — `PORT`, `DATABASE_URL`, and `CALNODE_ENCRYPTION_KEY`
   are pre-filled. `BASE_URL` is set to `http://localhost:3000`; change it to your
   real domain (e.g. `https://<your-sub>.up.railway.app`) after the first deploy
   and redeploy. Calnode derives OAuth callbacks and team-invite links from
   `BASE_URL`, so this must match where your team actually lives.
2. **Create your admin user** from the UI, or via
   `POST /v1/admin/users` (see the API docs at `/v1/docs`).
3. **Connect a calendar** — Google or Microsoft 365 — from Settings → Calendars.
   The OAuth redirect URIs are derived from `BASE_URL`; make sure you have added
   the corresponding redirect URI in your Google Cloud / Azure console.
4. **Create an event type** and share the booking link.

## Why Calnode

- **Single Go binary + embedded SQLite** — one process, one volume, no sidecars.
  The database is a standard SQLite file, easy to back up and easy to move.
- **MCP-native** — book events, read your availability, and manage calendars
  through MCP, not a web UI.
- **API-first** — every UI action has a JSON endpoint at `/v1/*`.
- **Pure-Go, CGO-free** — `CGO_ENABLED=0`, one `arch`, one binary. The
  deployment surface is one process on one port on one volume.
- **Apache-2.0**, actively developed (upstream: Calnode/calnode, 107★, Go 1.26).
- **Optional object-storage backup** via Litestream-compatible `LITESTREAM_*`
  env vars — continuous SQLite replication to S3/R2/B2/MinIO when you want it.
- **SMTP for real** — calendar invites land in inboxes, not in a UI.

## Deployment Dependencies

No services required. Calnode runs as a single container with one volume
(`/data`) for SQLite. The deploy form pre-fills the required variables:

| Variable                   | Default                          | Notes                                                                 |
|----------------------------|----------------------------------|-----------------------------------------------------------------------|
| `PORT`                     | `3000`                           | HTTP listen port.                                                     |
| `BASE_URL`                 | `http://localhost:3000`          | Public identity host. Set to your real domain after first deploy.     |
| `DATABASE_URL`             | `sqlite:///data/calnode.db`      | SQLite driver path (pre-set; keep this).                              |
| `CALNODE_ENCRYPTION_KEY`   | `${{secret(32)}}`                | Envelope-encryption key (required for production).                    |
| `TZ`                       | `UTC`                            | Timezone for meetings, reminders, logs.                               |
| `GOOGLE_CLIENT_ID/SECRET`  | *(blank)*                        | Optional. Sign-in + Google Calendar sync.                             |
| `MICROSOFT_*`              | *(blank)*                        | Optional. Sign-in + Microsoft 365 sync.                               |
| `EMAIL_SMTP_*`             | *(blank)*                        | Optional. Booking invitation / confirmation emails.                   |
| `LITESTREAM_*`             | *(blank)*                        | Optional. Continuous SQLite backup to S3/R2/B2/MinIO.                 |

**After the first deploy:**

1. Create the admin user in the UI.
2. Connect your calendar (Google or Microsoft 365).
3. Set `BASE_URL` to your real domain, redeploy, and verify the OAuth
   callback works under your real host.
