#!/bin/bash
# HealFast – apply repo state to server: fix bahmni-config (config_etc), .env, recreate containers.
# Run on the server from the healfast-branding directory (e.g. after git pull).
# Usage: cd /opt/bahmni-docker/healfast-branding && sudo bash update-server.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# HealFast branding root (absolute)
HEALFAST="${HEALFAST_BRANDING_PATH:-$SCRIPT_DIR}"
# Bahmni-lite dir (sibling of healfast-branding by default)
PARENT="$(dirname "$HEALFAST")"
BAHMNI_LITE="${BAHMNI_LITE_PATH:-$PARENT/bahmni-lite}"
ENV_FILE="$BAHMNI_LITE/.env"

echo "=== HealFast server update ==="
echo "HealFast:  $HEALFAST"
echo "Bahmni-lite: $BAHMNI_LITE"
echo ""

if [ ! -d "$BAHMNI_LITE" ]; then
  echo "Error: Bahmni-lite not found at $BAHMNI_LITE. Set BAHMNI_LITE_PATH or place repo as sibling of bahmni-lite."
  exit 1
fi

# 1) Ensure config_etc exists and is a real copy of config (fixes "same file" for bahmni-config)
CONFIG="$HEALFAST/config"
CONFIG_ETC="$HEALFAST/config_etc"
if [ ! -d "$CONFIG" ]; then
  echo "Error: $CONFIG not found."
  exit 1
fi
echo "Syncing config -> config_etc (must be two separate dirs for bahmni-config)..."
mkdir -p "$CONFIG_ETC"
rsync -a --delete "$CONFIG/" "$CONFIG_ETC/" 2>/dev/null || cp -r "$CONFIG"/. "$CONFIG_ETC/"
echo "Done: $CONFIG_ETC"

# 2) Ensure .env has absolute CONFIG_VOLUME and CONFIG_VOLUME_ETC
if [ ! -f "$ENV_FILE" ]; then
  echo "Warning: $ENV_FILE not found. Create it from env.template first."
else
  export CONFIG_VOLUME="$HEALFAST/config"
  export CONFIG_VOLUME_ETC="$HEALFAST/config_etc"
  for key in HEALFAST_BRANDING_PATH CONFIG_VOLUME CONFIG_VOLUME_ETC; do
    case "$key" in
      HEALFAST_BRANDING_PATH) val="$HEALFAST" ;;
      CONFIG_VOLUME)         val="$HEALFAST/config" ;;
      CONFIG_VOLUME_ETC)     val="$HEALFAST/config_etc" ;;
    esac
    if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
      sed -i "s|^${key}=.*|${key}=$val|" "$ENV_FILE"
    else
      echo "${key}=$val" >> "$ENV_FILE"
    fi
  done
  echo "Updated .env: HEALFAST_BRANDING_PATH, CONFIG_VOLUME, CONFIG_VOLUME_ETC"
fi

# 3) Recreate bahmni-config and proxy so they use the new override
echo ""
echo "Recreating bahmni-config and proxy..."
cd "$BAHMNI_LITE"
OVERRIDE="$HEALFAST/docker-compose.override.yml"
docker compose -f docker-compose.yml -f "$OVERRIDE" --env-file .env up -d --force-recreate bahmni-config proxy

echo ""
echo "=== Update done ==="
echo "Check: docker ps -a --filter name=bahmni-config --filter name=proxy"
echo "Logs:  docker logs bahmni-lite-bahmni-config-1 --tail 20"
echo "If reports is still restarting, fix OpenMRS DB password (see RESTARTING-SERVICES-FIX.md)."
