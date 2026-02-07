#!/bin/bash
# HealFast USA - One-shot remote deployment script
# Runs on the server via: ssh user@host 'bash -s' < deploy-healfast-remote.sh
set -e
export DEBIAN_FRONTEND=noninteractive
ROOT=/opt/bahmni-docker
HEALFAST="$ROOT/healfast-branding"
PASS="HealFast2024Secure"

echo "=== HealFast Bahmni - Remote Deploy ==="

# Install Docker if missing
if ! command -v docker &>/dev/null; then
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER" 2>/dev/null || true
fi
sudo systemctl enable docker 2>/dev/null || true
sudo systemctl start docker 2>/dev/null || true

# Install git if missing
command -v git &>/dev/null || sudo apt-get update -qq && sudo apt-get install -y -qq git

# Clone or update Bahmni Docker
sudo mkdir -p /opt
if [ ! -d "$ROOT/.git" ]; then
  echo "Cloning Bahmni Docker..."
  sudo git clone https://github.com/Bahmni/bahmni-docker.git "$ROOT"
else
  echo "Updating Bahmni Docker..."
  (cd "$ROOT" && sudo git pull --rebase || true)
fi

# Clone or update HealFast branding
if [ -d "$HEALFAST/.git" ]; then
  echo "Updating HealFast branding..."
  (cd "$HEALFAST" && sudo git pull --rebase || true)
else
  echo "Cloning HealFast branding..."
  sudo rm -rf "$HEALFAST"
  sudo git clone https://github.com/Heal-Fast-USA/healfast.git "$HEALFAST"
fi

# Ensure SSL certs exist (self-signed if not)
sudo mkdir -p "$HEALFAST/ssl"
if [ ! -f "$HEALFAST/ssl/healfastusa.org.crt" ]; then
  echo "Creating self-signed SSL certificate..."
  sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$HEALFAST/ssl/healfastusa.org.key" \
    -out "$HEALFAST/ssl/healfastusa.org.crt" \
    -subj "/CN=clinic.healfastusa.org" \
    -addext "subjectAltName=DNS:clinic.healfastusa.org,DNS:staff.healfastusa.org" 2>/dev/null || \
  sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$HEALFAST/ssl/healfastusa.org.key" \
    -out "$HEALFAST/ssl/healfastusa.org.crt" \
    -subj "/CN=clinic.healfastusa.org"
fi

# Create .env from template with absolute paths and passwords
echo "Configuring environment..."
sudo cp "$HEALFAST/env.template" "$ROOT/bahmni-lite/.env"
sudo sed -i "s|CONFIG_VOLUME=.*|CONFIG_VOLUME=$HEALFAST/config|" "$ROOT/bahmni-lite/.env"
sudo sed -i "s|CERTIFICATE_PATH=.*|CERTIFICATE_PATH=$HEALFAST/ssl|" "$ROOT/bahmni-lite/.env"
sudo sed -i "s|CHANGE_ME_OPENMRS_DB_PASSWORD|$PASS|g" "$ROOT/bahmni-lite/.env"
sudo sed -i "s|CHANGE_ME_ATOMFEED_PASSWORD|$PASS|g" "$ROOT/bahmni-lite/.env"
sudo sed -i "s|CHANGE_ME_REPORTS_DB_PASSWORD|$PASS|g" "$ROOT/bahmni-lite/.env"
sudo sed -i "s|CHANGE_ME_ROOT_PASSWORD|$PASS|g" "$ROOT/bahmni-lite/.env"
# Required by compose YAML (Loki not used; prevents "LOKI_URL is missing" error)
grep -q '^LOKI_URL=' "$ROOT/bahmni-lite/.env" || echo "LOKI_URL=http://127.0.0.1:3100" | sudo tee -a "$ROOT/bahmni-lite/.env" >/dev/null

# Fix ownership so administrator can run docker compose
sudo chown -R "$USER:$USER" "$ROOT" 2>/dev/null || true

# Pull images and start
echo "Pulling images and starting HealFast Bahmni..."
cd "$ROOT/bahmni-lite"
sudo docker compose -f docker-compose.yml -f ../healfast-branding/docker-compose.override.yml --env-file .env pull
sudo docker compose -f docker-compose.yml -f ../healfast-branding/docker-compose.override.yml --env-file .env up -d

echo ""
echo "=== HealFast Bahmni is starting ==="
echo "Wait 5-10 minutes for all services, then open: https://$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_SERVER_IP')"
echo "Change default passwords in: $ROOT/bahmni-lite/.env"
echo "Status: sudo docker compose -f $ROOT/bahmni-lite/docker-compose.yml -f $HEALFAST/docker-compose.override.yml --env-file $ROOT/bahmni-lite/.env -d ps"
