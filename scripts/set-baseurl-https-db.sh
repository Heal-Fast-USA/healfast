#!/bin/bash
# Set OpenMRS base URL to HTTPS in the database to fix Mixed Content
# (page at https://... requested http://.../openmrs/initialsetup).
# Run from healfast-branding; reads .env from bahmni-lite. No admin password needed.

set -e

HEALFAST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARENT="$(dirname "$HEALFAST")"
BAHMNI_LITE="${BAHMNI_LITE_PATH:-$PARENT/bahmni-lite}"
ENV_FILE="$BAHMNI_LITE/.env"

# Base URL must be HTTPS. For staff use https://staff.healfastusa.org, for clinic https://clinic.healfastusa.org
# If you use both, set the one you use most (or run this script twice with different BAHMNI_BASE_URL).
BAHMNI_BASE_URL="${BAHMNI_BASE_URL:-}"
if [ -z "$BAHMNI_BASE_URL" ] && [ -f "$ENV_FILE" ]; then
  BAHMNI_BASE_URL=$(grep '^BAHMNI_BASE_URL=' "$ENV_FILE" 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'")
fi
BAHMNI_BASE_URL="${BAHMNI_BASE_URL:-https://staff.healfastusa.org}"
BAHMNI_BASE_URL="${BAHMNI_BASE_URL%/}"

ROOT_PASS=$(grep '^MYSQL_ROOT_PASSWORD=' "$ENV_FILE" 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'")
OPENMRS_DB_NAME=$(grep '^OPENMRS_DB_NAME=' "$ENV_FILE" 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'")
OPENMRS_DB_NAME="${OPENMRS_DB_NAME:-openmrs}"

if [ -z "$ROOT_PASS" ]; then
  echo "Could not read MYSQL_ROOT_PASSWORD from $ENV_FILE"
  exit 1
fi

CONTAINER=$(docker ps --format '{{.Names}}' | grep -E 'openmrsdb|openmrs-db' | head -1)
if [ -z "$CONTAINER" ]; then
  echo "OpenMRS DB container not running. Start the stack first (fix-and-start.sh)."
  exit 1
fi

OPENMRS_BASE="${BAHMNI_BASE_URL}/openmrs"

echo "Setting OpenMRS base URLs to HTTPS: $BAHMNI_BASE_URL and $OPENMRS_BASE"
echo "Container: $CONTAINER  DB: $OPENMRS_DB_NAME"

# Update existing rows (fixes mixed content for initialsetup, implementer-interface, REST links)
docker exec "$CONTAINER" mysql -u root -p"$ROOT_PASS" "$OPENMRS_DB_NAME" -e "
  UPDATE global_property SET property_value = '$BAHMNI_BASE_URL' WHERE property = 'bahmni.baseUrl';
  UPDATE global_property SET property_value = '$OPENMRS_BASE' WHERE property = 'webservices.rest.uriPrefix';
  UPDATE global_property SET property_value = '$BAHMNI_BASE_URL' WHERE property = 'referenceapplication.redirectUri';
" 2>/dev/null && echo "Updated base URL properties." || true

# If bahmni.baseUrl did not exist, insert it
AFFECTED=$(docker exec "$CONTAINER" mysql -u root -p"$ROOT_PASS" "$OPENMRS_DB_NAME" -sN -e "SELECT COUNT(*) FROM global_property WHERE property = 'bahmni.baseUrl';" 2>/dev/null || echo "0")
if [ "$AFFECTED" = "0" ]; then
  docker exec "$CONTAINER" mysql -u root -p"$ROOT_PASS" "$OPENMRS_DB_NAME" -e "
    INSERT INTO global_property (property, property_value, description) VALUES ('bahmni.baseUrl', '$BAHMNI_BASE_URL', 'HTTPS base');
  " 2>/dev/null && echo "Inserted bahmni.baseUrl." || true
fi

echo "Done. OpenMRS will be restarted by fix-and-start so it picks up changes. Hard-refresh the browser (Ctrl+F5)."
exit 0
