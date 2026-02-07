#!/bin/bash
# HealFast USA – single script to fix and start the full stack (no manual steps).
# Run on the server:  cd /opt/bahmni-docker/healfast-branding && sudo bash fix-and-start.sh
# Requires: bahmni-lite as sibling (or set BAHMNI_LITE_PATH), Docker, docker compose.

set -e

HEALFAST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT="$(dirname "$HEALFAST")"
BAHMNI_LITE="${BAHMNI_LITE_PATH:-$PARENT/bahmni-lite}"
ENV_FILE="$BAHMNI_LITE/.env"
OVERRIDE="$HEALFAST/docker-compose.override.yml"
COMPOSE="docker compose -f $BAHMNI_LITE/docker-compose.yml -f $OVERRIDE --env-file $ENV_FILE"

echo "=== HealFast fix-and-start ==="
echo "HealFast:   $HEALFAST"
echo "Bahmni-lite: $BAHMNI_LITE"
echo ""

if [ ! -d "$BAHMNI_LITE" ]; then
  echo "Error: Bahmni-lite not found at $BAHMNI_LITE. Set BAHMNI_LITE_PATH or place this repo next to bahmni-lite."
  exit 1
fi

# 1) Sync config -> config_etc (two dirs so bahmni-config would not hit 'same file'; we run without that container)
mkdir -p "$HEALFAST/config_etc"
rsync -a --delete "$HEALFAST/config/" "$HEALFAST/config_etc/" 2>/dev/null || cp -r "$HEALFAST/config"/. "$HEALFAST/config_etc/"
echo "[1/5] Synced config -> config_etc"

# 2) SSL: create self-signed if missing
mkdir -p "$HEALFAST/ssl"
if [ ! -f "$HEALFAST/ssl/healfastusa.org.crt" ] || [ ! -f "$HEALFAST/ssl/healfastusa.org.key" ]; then
  echo "[2/5] Creating self-signed SSL (clinic/staff.healfastusa.org, IP 69.30.247.92)..."
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$HEALFAST/ssl/healfastusa.org.key" \
    -out "$HEALFAST/ssl/healfastusa.org.crt" \
    -subj "/CN=clinic.healfastusa.org" \
    -addext "subjectAltName=DNS:clinic.healfastusa.org,DNS:staff.healfastusa.org,IP:69.30.247.92" 2>/dev/null || \
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$HEALFAST/ssl/healfastusa.org.key" \
    -out "$HEALFAST/ssl/healfastusa.org.crt" \
    -subj "/CN=clinic.healfastusa.org"
else
  echo "[2/5] SSL certs already present"
fi

# 3) .env: create or update paths
if [ ! -f "$ENV_FILE" ]; then
  if [ -f "$HEALFAST/env.template" ]; then
    cp "$HEALFAST/env.template" "$ENV_FILE"
    echo "[3/5] Created .env from env.template"
  else
    echo "Error: No .env and no env.template. Create .env from bahmni-lite or copy env.template."
    exit 1
  fi
fi
for key in HEALFAST_BRANDING_PATH CONFIG_VOLUME CONFIG_VOLUME_ETC; do
  case "$key" in
    HEALFAST_BRANDING_PATH) val="$HEALFAST" ;;
    CONFIG_VOLUME)          val="$HEALFAST/config" ;;
    CONFIG_VOLUME_ETC)      val="$HEALFAST/config_etc" ;;
  esac
  if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
    sed -i "s|^${key}=.*|${key}=$val|" "$ENV_FILE"
  else
    echo "${key}=$val" >> "$ENV_FILE"
  fi
done
echo "[3/5] .env paths set"

# 4) Start stack without bahmni-config (avoids 'same file' restart loop)
echo "[4/5] Starting containers (bahmni-config disabled)..."
cd "$BAHMNI_LITE"
$COMPOSE up -d --scale bahmni-config=0

# 5) Fix reports: align OpenMRS DB user password with .env, then restart reports
echo "[5/5] Fixing OpenMRS DB password for reports..."
OPENMRS_PASS=$(grep '^OPENMRS_DB_PASSWORD=' "$ENV_FILE" 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'")
ROOT_PASS=$(grep '^MYSQL_ROOT_PASSWORD=' "$ENV_FILE" 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'")
if [ -z "$OPENMRS_PASS" ] || [ "$OPENMRS_PASS" = "CHANGE_ME_OPENMRS_DB_PASSWORD" ]; then
  OPENMRS_PASS="${OPENMRS_DB_PASSWORD:-HealFast2024Secure}"
fi
if [ -z "$ROOT_PASS" ]; then
  ROOT_PASS="${MYSQL_ROOT_PASSWORD:-HealFast2024Secure}"
fi
sleep 10
if docker ps --format '{{.Names}}' | grep -q openmrsdb; then
  docker exec bahmni-lite-openmrsdb-1 mysql -u root -p"$ROOT_PASS" -e "ALTER USER 'openmrs'@'%' IDENTIFIED BY '$OPENMRS_PASS'; FLUSH PRIVILEGES;" 2>/dev/null || true
  $COMPOSE restart reports 2>/dev/null || true
fi

echo ""
echo "=== Done ==="
echo "Check:  docker ps -a"
echo "URLs:   https://clinic.healfastusa.org   https://staff.healfastusa.org"
echo "If proxy or reports still restart, see logs: docker logs bahmni-lite-proxy-1 --tail 20"
