#!/bin/bash
# Teardown: remove all Docker project resources (containers, volumes, networks),
# clear .env, and delete the entire installation directory (git clone and all).
# Docker and Docker Compose are NOT uninstalled.
#
# Usage (run as root or with sudo):
#   sudo bash teardown-all.sh
#   sudo bash teardown-all.sh --confirm   # skip confirmation prompt
#
# After running, the installation path (e.g. /opt/bahmni-docker) will be gone.
# To redeploy, clone the repo again and run fix-and-start.

set -e

HEALFAST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT="$(dirname "$HEALFAST")"
BAHMNI_LITE="${BAHMNI_LITE_PATH:-$PARENT/bahmni-lite}"
ENV_FILE="$BAHMNI_LITE/.env"
OVERRIDE="$HEALFAST/docker-compose.override.yml"

CONFIRM="${1:-}"

echo "=============================================="
echo "  HealFast / Bahmni – FULL TEARDOWN"
echo "=============================================="
echo ""
echo "This will:"
echo "  1. Stop and remove all project containers"
echo "  2. Remove all project volumes (DB data, config volumes, etc.)"
echo "  3. Remove project networks"
echo "  4. Remove/clear .env in bahmni-lite"
echo "  5. DELETE the entire installation directory: $PARENT"
echo "     (includes healfast-branding, bahmni-lite, and everything inside)"
echo ""
echo "Docker and Docker Compose will NOT be uninstalled."
echo ""

if [ "$CONFIRM" != "--confirm" ]; then
  printf "Type YES (uppercase) to continue and destroy everything: "
  read -r answer
  if [ "$answer" != "YES" ]; then
    echo "Aborted."
    exit 0
  fi
fi

# 1) Compose down with volume removal (must run before we delete the dirs)
if [ -f "$BAHMNI_LITE/docker-compose.yml" ] && [ -f "$OVERRIDE" ]; then
  echo "[1/4] Stopping containers and removing volumes..."
  if [ -f "$ENV_FILE" ]; then
    docker compose -f "$BAHMNI_LITE/docker-compose.yml" -f "$OVERRIDE" --env-file "$ENV_FILE" down -v --remove-orphans 2>/dev/null || true
  fi
  docker compose -f "$BAHMNI_LITE/docker-compose.yml" -f "$OVERRIDE" down -v --remove-orphans 2>/dev/null || true
  echo "      Done."
else
  echo "[1/4] Compose files not found, skipping compose down."
fi

# 2) Remove any volumes that might be left (named volumes from this project)
echo "[2/4] Removing any remaining project volumes..."
docker volume ls -q 2>/dev/null | grep -E 'bahmni|openmrs|healfast|reportsdb|proxy' 2>/dev/null | while read -r v; do
  docker volume rm "$v" 2>/dev/null || true
done
echo "      Done."

# 3) Clear .env (remove so next setup starts empty)
echo "[3/4] Clearing .env and generated paths..."
for f in "$ENV_FILE" "$BAHMNI_LITE/.env.dev" "$HEALFAST/config_etc" "$HEALFAST/ssl" "$HEALFAST/acme-webroot"; do
  if [ -e "$f" ]; then
    rm -rf "$f"
    echo "      Removed: $f"
  fi
done
echo "      Done."

# 4) Delete the entire installation directory (parent of healfast-branding)
echo "[4/4] Deleting installation directory: $PARENT"
echo "      (healfast-branding, bahmni-lite, and all contents)"
INSTALL_ROOT="$PARENT"
cd / 2>/dev/null || true
rm -rf "$INSTALL_ROOT"
echo ""
echo "Teardown complete. $INSTALL_ROOT has been removed."
echo "Docker and Docker Compose are still installed."
echo "To redeploy: clone the repo again and run fix-and-start.sh"
