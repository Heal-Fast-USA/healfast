#!/bin/bash
# Obtain or renew Let's Encrypt certificate for clinic.healfastusa.org and staff.healfastusa.org.
# Run with sudo after fix-and-start.sh:  sudo bash scripts/obtain-letsencrypt.sh
# Requires: certbot installed (run install-certbot.sh), nginx running with acme-webroot mounted.

set -e

HEALFAST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SSL_DIR="$HEALFAST/ssl"
ACME_WEBROOT="${ACME_WEBROOT:-$HEALFAST/acme-webroot}"
CERT_NAME="${CERT_NAME:-healfastusa.org}"
DOMAINS="${DOMAINS:-clinic.healfastusa.org,staff.healfastusa.org}"
EMAIL="${LETSENCRYPT_EMAIL:-admin@healfastusa.org}"

mkdir -p "$ACME_WEBROOT"
mkdir -p "$SSL_DIR"

# Convert comma-separated to -d args
_domains=""
for d in ${DOMAINS//,/ }; do
  _domains="$_domains -d $d"
done

echo "=== Let's Encrypt certificate for $CERT_NAME ==="
echo "Webroot: $ACME_WEBROOT"
echo "Domains: $DOMAINS"
echo ""

# Obtain or renew
certbot certonly --webroot \
  -w "$ACME_WEBROOT" \
  $_domains \
  --cert-name "$CERT_NAME" \
  --email "$EMAIL" \
  --agree-tos \
  --no-eff-email \
  --keep \
  --non-interactive || true

LIVE="/etc/letsencrypt/live/$CERT_NAME"
if [ ! -f "$LIVE/fullchain.pem" ] || [ ! -f "$LIVE/privkey.pem" ]; then
  echo "Certificate not found at $LIVE. Run with --non-interactive removed for first-time (will prompt for email)."
  echo "Ensure DNS for $DOMAINS points to this server and port 80 is reachable."
  exit 1
fi

# Copy to healfast ssl dir and reload nginx
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/copy-certs-and-reload.sh"
echo "Copied certs to $SSL_DIR (healfastusa.org.crt / healfastusa.org.key)"

echo ""
echo "HTTPS is now using Let's Encrypt. Set up renewal:"
echo "  sudo certbot renew --dry-run"
echo "  Crontab: 0 3 * * * root certbot renew -q --deploy-hook \"$HEALFAST/scripts/copy-certs-and-reload.sh\""