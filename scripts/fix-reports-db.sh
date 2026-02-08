#!/bin/bash
# Fix reports DB user so the reports container can connect (stops restart loop).
# Run from healfast-branding; reads bahmni-lite .env. Run after reportsdb is up.

set -e

HEALFAST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARENT="$(dirname "$HEALFAST")"
BAHMNI_LITE="${BAHMNI_LITE_PATH:-$PARENT/bahmni-lite}"
ENV_FILE="$BAHMNI_LITE/.env"

[ ! -f "$ENV_FILE" ] && echo "No $ENV_FILE" && exit 1

ROOT_PASS=$(grep '^MYSQL_ROOT_PASSWORD=' "$ENV_FILE" 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'")
REPORTS_DB_NAME=$(grep '^REPORTS_DB_NAME=' "$ENV_FILE" 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'")
REPORTS_DB_USER=$(grep '^REPORTS_DB_USERNAME=' "$ENV_FILE" 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'")
REPORTS_DB_PASS=$(grep '^REPORTS_DB_PASSWORD=' "$ENV_FILE" 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'")

REPORTS_DB_NAME="${REPORTS_DB_NAME:-bahmni_reports}"
REPORTS_DB_USER="${REPORTS_DB_USER:-reports-user}"
REPORTS_DB_PASS="${REPORTS_DB_PASS:-password}"
[ -z "$ROOT_PASS" ] && ROOT_PASS="${MYSQL_ROOT_PASSWORD:-password}"

CONTAINER=$(docker ps --format '{{.Names}}' | grep -E 'reportsdb' | head -1)
[ -z "$CONTAINER" ] && echo "reportsdb container not running." && exit 1

# Escape single quotes for MySQL
REPORTS_DB_PASS_ESC="${REPORTS_DB_PASS//\'/\'\'}"

echo "Fixing reports DB user $REPORTS_DB_USER in $CONTAINER..."

# Create DB, user, set password, grant. (MySQL 5.7 and 8.)
docker exec "$CONTAINER" mysql -u root -p"$ROOT_PASS" -e "
  CREATE DATABASE IF NOT EXISTS \`$REPORTS_DB_NAME\`;
  GRANT ALL PRIVILEGES ON \`$REPORTS_DB_NAME\`.* TO '$REPORTS_DB_USER'@'%' IDENTIFIED BY '$REPORTS_DB_PASS_ESC';
  FLUSH PRIVILEGES;
" 2>/dev/null || true

# If user already exists (MySQL 5.7): GRANT may not set password; ALTER USER does.
docker exec "$CONTAINER" mysql -u root -p"$ROOT_PASS" -e "
  ALTER USER '$REPORTS_DB_USER'@'%' IDENTIFIED BY '$REPORTS_DB_PASS_ESC';
  GRANT ALL PRIVILEGES ON \`$REPORTS_DB_NAME\`.* TO '$REPORTS_DB_USER'@'%';
  FLUSH PRIVILEGES;
" 2>/dev/null || true

# MySQL 8: use native password so older Java drivers can connect
docker exec "$CONTAINER" mysql -u root -p"$ROOT_PASS" -e "
  ALTER USER '$REPORTS_DB_USER'@'%' IDENTIFIED WITH mysql_native_password BY '$REPORTS_DB_PASS_ESC';
  FLUSH PRIVILEGES;
" 2>/dev/null || true

echo "Done. Restart reports: docker compose -f $BAHMNI_LITE/docker-compose.yml -f $HEALFAST/docker-compose.override.yml --env-file $ENV_FILE restart reports"
exit 0
