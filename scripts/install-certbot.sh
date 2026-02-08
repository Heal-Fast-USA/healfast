#!/bin/bash
# Install Certbot on the server for Let's Encrypt HTTPS.
# Run with sudo:  sudo bash scripts/install-certbot.sh
# Requires: Debian/Ubuntu (apt). For RHEL/CentOS use: dnf install certbot python3-certbot-nginx

set -e

echo "=== Installing Certbot for Let's Encrypt ==="

# Update package list
apt-get update

# Install Certbot and Nginx plugin (nginx plugin used only when nginx runs on host;
# for nginx in Docker we use webroot method, but having the package doesn't hurt)
apt-get install -y certbot python3-certbot-nginx

# Optional: Apache variant if you ever switch proxy to Apache
# apt-get install -y certbot python3-certbot-apache

echo ""
echo "Certbot installed. Next steps:"
echo "  1. Ensure DNS for clinic.healfastusa.org and staff.healfastusa.org points to this server"
echo "  2. Run fix-and-start.sh from healfast-branding (so nginx is up and acme-webroot is used)"
echo "  3. Run: sudo bash scripts/obtain-letsencrypt.sh"
echo "  4. Set up renewal: sudo certbot renew --dry-run  (then add cron: 0 3 * * * certbot renew -q)"