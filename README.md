# Deploy and Host Calnode

Self-hostable Calendly alternative in a single Go binary with embedded SQLite.
API-first and MCP-native, out of the box. No Redis, no Postgres, no separate
API server, no multi-gigabyte image.

[![Deploy to Railway](https://railway.app/button.svg)](https://railway.com/deploy/calnode)

## Dependencies for Calnode

No external services required. Calnode runs as one service with one volume
(`/data`) holding the SQLite database file.

| Variable                   | Default                       | Optional | Notes                                                                                          |
|----------------------------|-------------------------------|----------|------------------------------------------------------------------------------------------------|
| `PORT`                     | `3000`                        | yes      | HTTP listen port. Calnode binds `0.0.0.0:3000` by default.                                     |
| `BASE_URL`                 | `http://localhost:3000`       | **no**   | Public identity host used for OAuth callbacks, the admin UI, and team-invite links. Set to your real domain after the first deploy and redeploy. |
| `DATABASE_URL`             | `sqlite:///data/calnode.db`   | yes      | SQLite driver path. Keep on the `/data` volume so calendar data survives restarts.              |
| `CALNODE_ENCRYPTION_KEY`   | `${{secret(32)}}`             | **no**   | Envelope-encryption master key (auto-generated). Required for https `BASE_URL`.                 |
| `CALNODE_RECOVERY_SECRET`  | *(blank)*                     | yes      | Break-glass escrow for recovering from a lost encryption key.                                   |
| `PUBLIC_BASE_URL`          | *(blank)*                     | yes      | Optional booker-facing host. Blank = inherits `BASE_URL`.                                       |
| `TZ`                       | `UTC`                         | yes      | Timezone for meetings, reminders, and logs.                                                    |
| `GOOGLE_CLIENT_ID/SECRET`  | *(blank)*                     | yes      | Google sign-in + Google Calendar sync. Redirect URIs: `{BASE_URL}/v1/auth/callback`, `{BASE_URL}/v1/calendar/callback`. |
| `MICROSOFT_CLIENT_ID/SECRET` | *(blank)*                   | yes      | Microsoft 365 sign-in + calendar sync. Redirect URIs: `{BASE_URL}/v1/auth/microsoft/callback`, `{BASE_URL}/v1/calendar/callback`. |
| `MICROSOFT_TENANT`         | `common`                      | yes      | Azure tenant. `common` allows personal + work/school accounts.                                  |
| `EMAIL_SMTP_*`             | *(blank)*                     | yes      | SMTP host/port/user/pass for booking invitation and confirmation emails. Blank = no email.      |
| `LITESTREAM_*`             | *(blank)*                     | yes      | Continuous SQLite backup to S3/R2/B2/MinIO via Litestream.                                       |

### Deployment Dependencies

- One service.
- One volume mounted at `/data` (Railway volume, 5 GB default — enough for
  years of bookings; the binary is ~20 MB and the SQLite file grows slowly).
- No sidecar. No database plugin. No Redis.

## About Hosting

Calnode is a single static Go binary compiled with `CGO_ENABLED=0` — one
process, one port, one file. The database is a standard SQLite file at
`/data/calnode.db`, easy to back up and easy to move.

Deployment surface:

- **Service `calnode`** — listens on `PORT` (default 3000), healthcheck at
  `/healthz` (returns `{"status":"ok"}`), admin UI at `/admin/`, JSON API at
  `/v1/*`, MCP server at `/mcp`.
- **Volume `calnode-data`** — mounted at `/data`; holds the SQLite database
  plus any object-storage backup state.

Railway maps the public domain to the service's `PORT`. `BASE_URL` must match
where your team actually lives (the `https://YOUR-SUB.up.railway.app` or
your custom domain) because Calnode derives OAuth redirect URIs, admin-UI
links, and invite links from it.

## Why Deploy

- **Single binary, single volume** — the entire stack is one process on one
  port. No Redis, no Postgres, no sidecar, no multi-gigabyte image.
- **MCP-native** — book events, read availability, and manage calendars
  through MCP tools that work with any MCP-compatible client (Claude Desktop,
  VS Code, Cursor, OpenAI Codex, etc.).
- **API-first** — every UI action has a JSON endpoint at `/v1/*`; Swagger at
  `/v1/docs`.
- **Calendar sync** — Google and Microsoft 365 out of the box. OAuth redirect
  URIs are derived from `BASE_URL`.
- **First-party video + AI notetaking** — build on top of the MCP API or the
  `/v1/*` JSON endpoints.
- **Optional object-storage backup** — continuous SQLite replication to
  S3/R2/B2/MinIO via `LITESTREAM_*` vars when you want it.
- **SMTP for real** — calendar invites land in inboxes, not in a UI.
- **Apache-2.0** — upstream `Calnode/calnode`, actively developed, Go 1.26.

## Common Use Cases

- **Personal scheduling** — replace Calendly's $10–20/month subscription
  with a single Go binary on a $5/mo host.
- **Team-facing bookings** — one instance, multiple event types, one booking
  link per customer.
- **AI-agent scheduling** — wire Calnode's MCP server into Claude Desktop,
  Cursor, Codex, or any MCP client so your agents can book on your behalf.
- **Self-hosted frontend/backend split** — Calnode's API is
  `https://YOUR-DOMAIN/v1/*`; pair it with any calendar SPA.
- **Migration from Cal.com** — the API surface is a subset of Cal.com's;
  point your existing clients at Calnode's `/v1/*` endpoints.

## Quick Start

1. **Deploy** — `PORT`, `DATABASE_URL`, and `CALNODE_ENCRYPTION_KEY` are
   pre-filled (the key is a fresh random value per deployment). `BASE_URL`
   defaults to `http://localhost:3000`; set it to your real domain after the
   first deploy and redeploy.
2. **Create your admin user** from the admin UI at `/admin/`, or via
   `POST /v1/admin/users` (see the API docs at `/v1/docs`).
3. **Connect a calendar** — Google or Microsoft 365 — from Settings →
   Calendars. Add the redirect URIs derived from `BASE_URL` in your OAuth
   console first.
4. **Create an event type** and share the booking link.
