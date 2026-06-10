#!/bin/bash
set -e

# =============================================================================
# Chosen Object — Entrypoint
# Arranca MySQL, ejecuta migraciones, lanza backend + frontend
# =============================================================================

echo "═══════════════════════════════════════════════"
echo "  Chosen Object — Starting services"
echo "═══════════════════════════════════════════════"

# ── Cargar secrets si existe el fichero ──────────────────────
if [ -f /run/secrets.env ]; then
    echo "[env] Loading secrets from /run/secrets.env"
    set -a
    source /run/secrets.env
    set +a
fi

# ── Variables por defecto ────────────────────────────────────
DB_NAME="${DB_NAME:-chosen_object}"
DB_USER="${DB_USER:-chosen}"
DB_PASSWORD="${DB_PASSWORD:-ChosenObj2026!}"
APP_PORT="${APP_PORT:-8002}"

# ── Iniciar MySQL ────────────────────────────────────────────
echo "[mysql] Starting MySQL..."
if [ ! -d /var/lib/mysql/mysql ]; then
    echo "[mysql] Initializing data directory..."
    mysqld --initialize-insecure --user=mysql
fi

mysqld --user=mysql --datadir=/var/lib/mysql &
MYSQL_PID=$!

# Esperar a que MySQL esté listo
echo "[mysql] Waiting for MySQL to be ready..."
for i in $(seq 1 30); do
    if mysqladmin ping --silent 2>/dev/null; then
        echo "[mysql] MySQL is ready"
        break
    fi
    sleep 1
done

# ── Crear BD y usuario si no existen ─────────────────────────
echo "[mysql] Setting up database and user..."
mysql -u root <<-EOSQL
    CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
    FLUSH PRIVILEGES;
EOSQL

# ── Migraciones Alembic ─────────────────────────────────────
echo "[backend] Running migrations..."
cd /app/backend
alembic upgrade head

# ── Seed data (solo si la BD está vacía) ───────────────────
USER_COUNT=$(mysql -u root -N -e "SELECT COUNT(*) FROM \`${DB_NAME}\`.users;" 2>/dev/null || echo "0")
if [ "$USER_COUNT" = "0" ]; then
    echo "[backend] Seeding database..."
    cd /app/backend
    python seed_users.py
else
    echo "[backend] Database already has ${USER_COUNT} users, skipping seed"
fi

# ── Lanzar backend (FastAPI) ─────────────────────────────────
echo "[backend] Starting FastAPI on port ${APP_PORT}..."
cd /app/backend
uvicorn main:app --host 0.0.0.0 --port "${APP_PORT}" &
BACKEND_PID=$!

# ── Lanzar frontend (serve static) ──────────────────────────
echo "[web] Starting frontend on port 3001..."
serve -s /app/web/dist -l 3001 &
FRONTEND_PID=$!

echo "═══════════════════════════════════════════════"
echo "  ✓ MySQL     : running (internal)"
echo "  ✓ Backend   : http://0.0.0.0:${APP_PORT}"
echo "  ✓ Frontend  : http://0.0.0.0:3001"
echo "═══════════════════════════════════════════════"

# ── Trap SIGTERM para shutdown limpio ────────────────────────
cleanup() {
    echo "[shutdown] Stopping services..."
    kill $FRONTEND_PID 2>/dev/null
    kill $BACKEND_PID 2>/dev/null
    mysqladmin shutdown 2>/dev/null
    wait
    echo "[shutdown] Done"
}
trap cleanup SIGTERM SIGINT

# Mantener el contenedor vivo
wait $MYSQL_PID
