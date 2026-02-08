#!/bin/bash
# Ensure reports and reportsdb are running (so /bahmni-reports/ works).
# Run from healfast-branding; uses bahmni-lite .env and compose.

set -e

HEALFAST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARENT="$(dirname "$HEALFAST")"
BAHMNI_LITE="${BAHMNI_LITE_PATH:-$PARENT/bahmni-lite}"
ENV_FILE="$BAHMNI_LITE/.env"
OVERRIDE="$HEALFAST/docker-compose.override.yml"
COMPOSE="docker compose -f $BAHMNI_LITE/docker-compose.yml -f $OVERRIDE --env-file $ENV_FILE"

cd "$BAHMNI_LITE"

# Start reports and reportsdb if not running (they use profile bahmni-lite)
if ! docker ps --format '{{.Names}}' | grep -qE 'reports|reportsdb'; then
  echo "Starting reports and reportsdb..."
  $COMPOSE up -d reports reportsdb 2>/dev/null || true
  sleep 15
fi

# Restart reports so it picks up OpenMRS DB password (after fix-and-start alters it)
if docker ps --format '{{.Names}}' | grep -q openmrsdb; then
  $COMPOSE restart reports 2>/dev/null || true
fi

echo "Reports: $(docker ps --format '{{.Names}} {{.Status}}' | grep -E 'reports|reportsdb' || echo 'not running')"
exit 0
