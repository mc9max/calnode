# syntax=docker/dockerfile:1
# ============================================================================
# Railway Template: Calnode Lite (Calnode/calnode)
# ----------------------------------------------------------------------------
# A lean, self-hostable Calendly alternative — a single Go 1.26 static binary
# with an embedded SQLite database (pure-Go, CGO-free) and a LiteStream-
# compatible object-storage backup path. No Redis, no Postgres, no sidecars.
#
# Wraps the upstream public image ghcr.io/calnode/calnode:latest (busybox
# base, ENTRYPOINT /entrypoint.sh, DATABASE_URL default in image).
# We add:
#   - a /data directory (SQLite volume mount point — the base entrypoint
#     already does `mkdir -p /data` but the directory must exist in the
#     image layer for the volume to bind-mount cleanly),
#   - a /healthz HEALTHCHECK using busybox wget (no curl in this base image),
#   - EXPOSE 3000 (matches the app's default PORT).
# ============================================================================
ARG CALNODE_TAG=latest
FROM ghcr.io/calnode/calnode:${CALNODE_TAG}

# SQLite data dir for the Railway volume (calnode-data).
RUN mkdir -p /data

ENV PORT=3000

EXPOSE 3000

# Ops endpoint: GET /healthz (registered in internal/server/server.go:265).
# Busybox wget exits 0 on 2xx, non-zero on 4xx/5xx/connection-refused.
HEALTHCHECK --interval=30s --timeout=8s --start-period=60s --retries=5 \
  CMD wget -q --spider http://127.0.0.1:${PORT:-3000}/healthz || exit 1
