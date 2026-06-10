# =============================================================================
# Chosen Object — Dockerfile unificado
#   - MySQL 8.0          (puerto 3306, solo interno)
#   - FastAPI backend     (puerto 8002)
#   - Vue/Vite frontend   (puerto 3001)
#
# BUILD:
#   docker compose build
#
# START:
#   docker compose up -d
#
# LOGS:
#   docker logs -f chosen-object
# =============================================================================

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# ── Sistema base ─────────────────────────────────────────────
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
        curl wget gnupg ca-certificates \
        tzdata locales && \
    locale-gen C.UTF-8 && \
    ln -fs /usr/share/zoneinfo/Europe/Madrid /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# ── Python 3 ─────────────────────────────────────────────────
RUN apt-get install -y python3 python3-pip python3-venv && \
    ln -sf /usr/bin/python3 /usr/bin/python

# ── MySQL 8.0 ────────────────────────────────────────────────
RUN apt-get install -y mysql-server && \
    rm -rf /var/lib/apt/lists/*

# ── Node.js 22 ───────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g serve

# ── Backend: instalar dependencias Python ────────────────────
COPY backend/requirements.txt /app/backend/requirements.txt
RUN pip install --no-cache-dir --break-system-packages \
    -r /app/backend/requirements.txt

# ── Backend: copiar código ───────────────────────────────────
COPY backend/ /app/backend/

# ── Frontend: build Vue ──────────────────────────────────────
COPY web/package.json web/package-lock.json* /app/web/
WORKDIR /app/web
RUN npm ci
COPY web/ /app/web/
RUN npm run build-only

# ── Entrypoint ───────────────────────────────────────────────
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3001 8002

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -fsS http://localhost:8002/health 2>/dev/null || exit 1

CMD ["/entrypoint.sh"]
