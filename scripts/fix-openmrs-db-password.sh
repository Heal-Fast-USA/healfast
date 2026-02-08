#!/bin/bash
# Fix OpenMRS DB user password so OpenMRS/Liquibase can connect (stops "Access denied for user 'openmrs'@'...'").
# Run from healfast-branding; reads bahmni-lite .env. Requires openmrsdb container running.

set -e

HEALFAST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARENT="$(dirname "$HEALFAST")"
BAHMNI_LITE="${BAHMNI_LITE_PATH:-$PARENT/bahmni-lite}"
ENV_FILE="$BAHMNI_LITE/.env"

[ ! -f "$ENV_FILE" ] && echo "No $ENV_FILE" && exit 1

OPENMRS_PASS=$(grep '^OPENMRS_DB_PASSWORD=' "$ENV_FILE" 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'")
ROOT_PASS=$(grep '^MYSQL_ROOT_PASSWORD=' "$ENV_FILE" 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'")
OPENMRS_DB_NAME=$(grep '^OPENMRS_DB_NAME=' "$ENV_FILE" 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'")
OPENMRS_DB_NAME="${OPENMRS_DB_NAME:-openmrs}"

if [ -z "$OPENMRS_PASS" ] || [ "$OPENMRS_PASS" = "CHANGE_ME_OPENMRS_DB_PASSWORD" ]; then
  OPENMRS_PASS="${OPENMRS_DB_PASSWORD:-HealFast2024Secure}"
fi
[ -z "$ROOT_PASS" ] && ROOT_PASS="${MYSQL_ROOT_PASSWORD:-HealFast2024Secure}"

CONTAINER=$(docker ps --format '{{.Names}}' | grep -E 'openmrsdb|openmrs-db' | head -1)
[ -z "$CONTAINER" ] && echo "openmrsdb container not running." && exit 1

# Escape single quotes for MySQL
OPENMRS_PASS_ESC="${OPENMRS_PASS//\'/\'\'}"

echo "Setting MySQL password for user openmrs (so OpenMRS/Liquibase can connect)..."
echo "Container: $CONTAINER"

# Containers connect from Docker network, so we need openmrs@'%'. Also fix openmrs@'localhost'.
# 1) Create user if missing (MySQL 5.7.6+); 2) ALTER to set password; 3) GRANT
for HOST in '%' 'localhost'; do
  docker exec "$CONTAINER" mysql -u root -p"$ROOT_PASS" -e "
    CREATE USER IF NOT EXISTS 'openmrs'@'$HOST' IDENTIFIED BY '$OPENMRS_PASS_ESC';
    ALTER USER 'openmrs'@'$HOST' IDENTIFIED BY '$OPENMRS_PASS_ESC';
    GRANT ALL PRIVILEGES ON \`$OPENMRS_DB_NAME\`.* TO 'openmrs'@'$HOST';
    FLUSH PRIVILEGES;
  " 2>/dev/null || docker exec "$CONTAINER" mysql -u root -p"$ROOT_PASS" -e "
    ALTER USER 'openmrs'@'$HOST' IDENTIFIED BY '$OPENMRS_PASS_ESC';
    GRANT ALL PRIVILEGES ON \`$OPENMRS_DB_NAME\`.* TO 'openmrs'@'$HOST';
    FLUSH PRIVILEGES;
  " 2>/dev/null || true
done
echo "Done. OpenMRS will be restarted by fix-and-start so Liquibase can connect."
exit 0
