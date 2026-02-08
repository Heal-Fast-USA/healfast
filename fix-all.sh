#!/bin/bash
# HealFast USA – single script to fix all issues: paths, SSL, stack, Certbot, and Let's Encrypt.
# Run on the server:  cd /opt/bahmni-docker/healfast-branding && sudo bash fix-all.sh
# Optional:  sudo bash fix-all.sh --letsencrypt   to also install Certbot and obtain a real HTTPS cert.
#
# Requires: bahmni-lite as sibling (or BAHMNI_LITE_PATH), Docker, docker compose.
# For --letsencrypt: DNS for clinic.healfastusa.org and staff.healfastusa.org must point to this server.

set -e

HEALFAST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DO_LETSENCRYPT=false
[ "$1" = "--letsencrypt" ] && DO_LETSENCRYPT=true
[ "$FIX_ALL_LETSENCRYPT" = "1" ] && DO_LETSENCRYPT=true

echo "=============================================="
echo "  HealFast USA – fix-all (paths, SSL, stack)"
echo "=============================================="
echo ""

# Run the standard fix-and-start (paths, self-signed SSL, .env, start stack, reports)
bash "$HEALFAST/fix-and-start.sh"

echo ""
echo "--- Post-start fixes ---"

# Reload proxy so nginx picks up config/certs
_proxy=$(docker ps --format '{{.Names}}' | grep -E 'proxy|nginx' | head -1)
if [ -n "$_proxy" ]; then
  docker exec "$_proxy" nginx -s reload 2>/dev/null && echo "[+] Reloaded nginx (proxy)" || true
fi

if [ "$DO_LETSENCRYPT" = true ]; then
  echo ""
  echo "--- Let's Encrypt (Certbot) ---"
  # Install Certbot if missing (Debian/Ubuntu)
  if ! command -v certbot >/dev/null 2>&1; then
    echo "[*] Installing Certbot..."
    apt-get update -qq
    apt-get install -y certbot python3-certbot-nginx
  else
    echo "[+] Certbot already installed"
  fi
  # Obtain certificate and copy into ssl/ (then reload nginx)
  if [ -f "$HEALFAST/scripts/obtain-letsencrypt.sh" ]; then
    bash "$HEALFAST/scripts/obtain-letsencrypt.sh" || echo "[!] Let's Encrypt obtain failed (check DNS and port 80). You can run: sudo bash scripts/obtain-letsencrypt.sh"
  else
    echo "[!] scripts/obtain-letsencrypt.sh not found; skip Let's Encrypt or run: sudo certbot certonly --webroot -w $HEALFAST/acme-webroot -d clinic.healfastusa.org -d staff.healfastusa.org --cert-name healfastusa.org --email admin@healfastusa.org --agree-tos -n"
  fi
else
  echo ""
  echo "Tip: For trusted HTTPS (no browser cert errors), run:  sudo bash fix-all.sh --letsencrypt"
fi

echo ""
echo "=============================================="
echo "  Done. URLs: https://clinic.healfastusa.org   https://staff.healfastusa.org"
echo "=============================================="
