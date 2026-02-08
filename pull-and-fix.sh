#!/bin/bash
# Pull latest HealFast branding and fix all issues (paths, SSL, config, proxy reload).
# Run on the server:  cd /opt/bahmni-docker/healfast-branding && sudo bash pull-and-fix.sh
# Optional:  sudo bash pull-and-fix.sh --letsencrypt   to also obtain Let's Encrypt cert.

set -e

HEALFAST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HEALFAST"

REMOTE="${1:-healfast}"
if [ "$1" = "--letsencrypt" ]; then
  REMOTE="healfast"
  LETSENCRYPT_FLAG="--letsencrypt"
fi

echo "=============================================="
echo "  HealFast – pull and fix"
echo "=============================================="
echo "Pull from: $REMOTE (branch: main)"
echo ""

git fetch "$REMOTE" 2>/dev/null || git fetch origin 2>/dev/null || true
git pull "$REMOTE" main 2>/dev/null || git pull origin main 2>/dev/null || git pull 2>/dev/null || true

echo ""
bash "$HEALFAST/fix-all.sh" $LETSENCRYPT_FLAG
