#!/bin/bash
# Fix OpenMRS DB user password so OpenMRS/Liquibase can connect (stops "Access denied for user 'openmrs'@'...'").
# Run from healfast-branding; reads bahmni-lite .env. Requires openmrsdb container running.

set -e

HEALFAST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARENT="$(dirname "$HEALFAST")"
BAHMNI_LITE="${BAHMNI_LITE_PATH:-$PARENT/bahmni-lite}"
ENV_FILE="$BAHMNI_LITE/.env"

[ ! -f "$ENV_FILE" ] && echo "No $ENV_FILE" && exit 1

OPENMRS_USER=$(grep '^OPENMRS_DB_USERNAME=' "$ENV_FILE" 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'")
OPENMRS_PASS=$(grep '^OPENMRS_DB_PASSWORD=' "$ENV_FILE" 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'")
ROOT_PASS=$(grep '^MYSQL_ROOT_PASSWORD=' "$ENV_FILE" 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'")
OPENMRS_DB_NAME=$(grep '^OPENMRS_DB_NAME=' "$ENV_FILE" 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'")
OPENMRS_DB_NAME="${OPENMRS_DB_NAME:-openmrs}"
OPENMRS_USER="${OPENMRS_USER:-openmrs}"

if [ -z "$OPENMRS_PASS" ] || [ "$OPENMRS_PASS" = "CHANGE_ME_OPENMRS_DB_PASSWORD" ]; then
  OPENMRS_PASS="${OPENMRS_DB_PASSWORD:-HealFast2024Secure}"
fi
[ -z "$ROOT_PASS" ] && ROOT_PASS="${MYSQL_ROOT_PASSWORD:-HealFast2024Secure}"

CONTAINER=$(docker ps --format '{{.Names}}' | grep -E 'openmrsdb|openmrs-db' | head -1)
[ -z "$CONTAINER" ] && echo "openmrsdb container not running." && exit 1

# Escape single quotes for MySQL
OPENMRS_PASS_ESC="${OPENMRS_PASS//\'/\'\'}"

echo "Setting MySQL user '$OPENMRS_USER' password (so OpenMRS/Liquibase can connect)..."
echo "Container: $CONTAINER  DB: $OPENMRS_DB_NAME"
echo ""

# Containers connect from Docker network (e.g. 172.18.0.17), so we need user@'%'.
# MySQL 8: use mysql_native_password so Java connector works (same as fix-reports-db).
# MySQL 5.6: no ALTER USER / CREATE USER IF NOT EXISTS; use GRANT ... IDENTIFIED BY.

for HOST in '%' 'localhost'; do
  # Try MySQL 5.7/8 style first (CREATE IF NOT EXISTS, ALTER with mysql_native_password, GRANT)
  if docker exec "$CONTAINER" mysql -u root -p"$ROOT_PASS" -e "
    CREATE USER IF NOT EXISTS '$OPENMRS_USER'@'$HOST' IDENTIFIED BY '$OPENMRS_PASS_ESC';
    ALTER USER '$OPENMRS_USER'@'$HOST' IDENTIFIED WITH mysql_native_password BY '$OPENMRS_PASS_ESC';
    GRANT ALL PRIVILEGES ON \`$OPENMRS_DB_NAME\`.* TO '$OPENMRS_USER'@'$HOST';
    FLUSH PRIVILEGES;
  " 2>&1; then
    echo "  OK $OPENMRS_USER@$HOST (MySQL 5.7/8)"
  else
    # MySQL 5.6: GRANT ... IDENTIFIED BY creates user and sets password
    if docker exec "$CONTAINER" mysql -u root -p"$ROOT_PASS" -e "
      GRANT ALL PRIVILEGES ON \`$OPENMRS_DB_NAME\`.* TO '$OPENMRS_USER'@'$HOST' IDENTIFIED BY '$OPENMRS_PASS_ESC';
      FLUSH PRIVILEGES;
    " 2>&1; then
      echo "  OK $OPENMRS_USER@$HOST (MySQL 5.6)"
    else
      echo "  WARN: failed to set $OPENMRS_USER@$HOST (check root password and MySQL version)"
    fi
  fi
done

echo ""
echo "Done. Restart OpenMRS so it reconnects: docker compose ... restart openmrs"
exit 0
