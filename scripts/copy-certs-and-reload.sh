#!/bin/bash
# Copy Let's Encrypt certs from /etc/letsencrypt/live to healfast ssl/ and reload nginx.
# Used after certbot certonly (obtain-letsencrypt.sh) or as certbot renew --deploy-hook.

set -e

HEALFAST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SSL_DIR="$HEALFAST/ssl"
CERT_NAME="${CERT_NAME:-healfastusa.org}"
LIVE="/etc/letsencrypt/live/$CERT_NAME"

if [ ! -f "$LIVE/fullchain.pem" ] || [ ! -f "$LIVE/privkey.pem" ]; then
  echo "Certs not found at $LIVE" >&2
  exit 1
fi

cp "$LIVE/fullchain.pem" "$SSL_DIR/healfastusa.org.crt"
cp "$LIVE/privkey.pem" "$SSL_DIR/healfastusa.org.key"
chmod 644 "$SSL_DIR/healfastusa.org.crt"
chmod 600 "$SSL_DIR/healfastusa.org.key"

_proxy=$(docker ps --format '{{.Names}}' | grep -E 'proxy|nginx' | head -1)
if [ -n "$_proxy" ]; then
  docker exec "$_proxy" nginx -s reload 2>/dev/null || true
fi