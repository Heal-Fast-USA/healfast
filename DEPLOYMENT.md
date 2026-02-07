# HealFast USA - Bahmni Deployment Guide

This guide provides step-by-step instructions for deploying a fully branded HealFast USA instance of Bahmni on Ubuntu Server 22.04 LTS using Docker.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Server Setup](#initial-server-setup)
3. [DNS Configuration](#dns-configuration)
4. [SSL Certificate Setup](#ssl-certificate-setup)
5. [Docker Installation](#docker-installation)
6. [Bahmni Deployment](#bahmni-deployment)
7. [Branding Verification](#branding-verification)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

- Ubuntu Server 22.04 LTS (64-bit)
- Root or sudo access
- Server IP: **69.30.247.92**; subdomains: **clinic.healfastusa.org**, **staff.healfastusa.org**
- Minimum server requirements:
  - 4 CPU cores
  - 8 GB RAM
  - 100 GB disk space
  - Network access (ports 80, 443, 22)

## Initial Server Setup

### 1. Update System Packages

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y curl wget git vim
```

### 2. Configure Firewall

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## DNS Configuration

Before proceeding, ensure your DNS records are configured:

1. DNS: **clinic.healfastusa.org** and **staff.healfastusa.org** must point to **69.30.247.92**.
2. Ensure ports 80, 443, 22 are open to this IP.

## SSL Certificate Setup

### Option 1: Let's Encrypt (Recommended for Production)

```bash
# Install Certbot
sudo apt-get install -y certbot

# Navigate to branding directory
cd bahmni-docker/healfast-branding

# Run SSL setup script
chmod +x setup-ssl.sh
./setup-ssl.sh
# Select option 1 for Let's Encrypt
```

### Option 2: Use Existing Certificates

If you have existing SSL certificates:

```bash
# Copy certificates to SSL directory
cp /path/to/your/certificate.crt healfast-branding/ssl/healfastusa.org.crt
cp /path/to/your/private.key healfast-branding/ssl/healfastusa.org.key

# Set proper permissions
chmod 644 healfast-branding/ssl/healfastusa.org.crt
chmod 600 healfast-branding/ssl/healfastusa.org.key
```

### Option 3: Self-Signed (Testing Only)

```bash
cd healfast-branding
chmod +x setup-ssl.sh
./setup-ssl.sh
# Select option 3 for self-signed certificates
```

## Docker Installation

### 1. Install Docker

```bash
# Remove old Docker versions
sudo apt-get remove -y docker docker-engine docker.io containerd runc

# Install prerequisites
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
sudo usermod -aG docker $USER

# Log out and log back in for group changes to take effect
```

### 2. Verify Docker Installation

```bash
docker --version
docker compose version
```

## Bahmni Deployment

### 1. Clone or Copy Repository

If you have the repository:

```bash
cd /opt
git clone <your-bahmni-docker-repo> bahmni-docker
cd bahmni-docker
```

Or if you're copying files:

```bash
# Copy the entire bahmni-docker directory to your server
# Ensure healfast-branding directory is included
```

### 2. Configure Environment Variables

```bash
# Navigate to bahmni-lite or bahmni-standard
cd bahmni-lite  # or bahmni-standard

# Copy environment template
cp ../healfast-branding/.env.example .env

# Edit .env file with your settings
vim .env
```

**Important variables to update in `.env`:**

```bash
# Set strong passwords
OPENMRS_DB_PASSWORD=<strong-password>
MYSQL_ROOT_PASSWORD=<strong-root-password>
OPENMRS_ATOMFEED_PASSWORD=<strong-atomfeed-password>
REPORTS_DB_PASSWORD=<strong-reports-password>

# Update config volume path (use absolute path)
CONFIG_VOLUME=/opt/bahmni-docker/healfast-branding/config

# Set timezone
TZ=America/New_York
```

### 3. Update Docker Compose for HealFast Branding

Create or update `docker-compose.override.yml` in your bahmni-lite or bahmni-standard directory:

```bash
# Copy the override file
cp ../healfast-branding/docker-compose.override.yml .
```

Or manually merge the override configuration into your `docker-compose.yml`.

### 4. Start Bahmni Services

```bash
# Make run script executable
chmod +x run-bahmni.sh

# Start services
./run-bahmni.sh
# Select option 1: START Bahmni services
```

Or use docker compose directly:

```bash
docker compose --env-file .env up -d
```

### 5. Monitor Startup

```bash
# Check service status
docker compose ps

# View logs
docker compose logs -f

# Check specific service logs
docker compose logs openmrs -f
docker compose logs proxy -f
```

**Initial startup may take 10-15 minutes** as databases are initialized.

## Branding Verification

### 1. Verify Logo and Branding

1. Open browser and navigate to:
   - `https://clinic.healfastusa.org`

2. Check for:
   - ✓ HealFast logo on login page
   - ✓ Green color theme throughout UI
   - ✓ Poppins font applied
   - ✓ No default Bahmni branding

### 2. Verify SSL Certificates

```bash
# Test SSL from command line
openssl s_client -connect 69.30.247.92:443

# Or use online tools:
# https://www.ssllabs.com/ssltest/
```

### 3. Verify Custom CSS

1. Log into the system
2. Open browser developer tools (F12)
3. Check that `healfast-custom.css` is loaded
4. Verify Poppins font is applied (check computed styles)

### 4. Test Subdomain Routing

- `https://clinic.healfastusa.org` and `https://staff.healfastusa.org` → Should show HealFast Bahmni

## Troubleshooting

### Issue: Services won't start

```bash
# Check Docker logs
docker compose logs

# Check if ports are in use
sudo netstat -tulpn | grep -E ':(80|443|8080)'

# Check disk space
df -h

# Check memory
free -h
```

### Issue: SSL certificate errors

```bash
# Verify certificates exist
ls -lh healfast-branding/ssl/

# Check certificate validity
openssl x509 -in healfast-branding/ssl/healfastusa.org.crt -text -noout

# Verify nginx configuration
docker compose exec proxy nginx -t
```

### Issue: Branding not showing

```bash
# Verify config volume is mounted
docker compose exec bahmni-web ls -la /usr/local/apache2/htdocs/bahmni_config/

# Check if logo file exists
docker compose exec bahmni-web ls -la /usr/local/apache2/htdocs/bahmni_config/openmrs/apps/home/

# Restart bahmni-web service
docker compose restart bahmni-web
```

### Issue: Database connection errors

```bash
# Check database container status
docker compose ps openmrsdb

# Check database logs
docker compose logs openmrsdb

# Verify environment variables
docker compose exec openmrs env | grep OPENMRS
```

### Issue: DNS not resolving

```bash
# Test DNS resolution
ping clinic.healfastusa.org

# Check if DNS has propagated (may take up to 48 hours)
```

## Maintenance

### Updating Bahmni

```bash
# Pull latest images
./run-bahmni.sh
# Select option 7: PULL latest images

# Restart services
./run-bahmni.sh
# Select option 2: STOP services
# Then option 1: START services
```

### Backing Up

```bash
# Use Bahmni backup scripts
cd bahmni-lite  # or bahmni-standard
./backup_bahmni_lite.sh  # or backup_bahmni_standard.sh
```

### Renewing SSL Certificates (Let's Encrypt)

```bash
# Certbot auto-renewal (set up cron job)
sudo certbot renew --dry-run

# Or renew manually
sudo certbot renew
# Then copy new certificates
# If using Let's Encrypt (requires clinic.healfastusa.org and staff.healfastusa.org pointing to 69.30.247.92):
# sudo cp /etc/letsencrypt/live/YOUR_DOMAIN/fullchain.pem healfast-branding/ssl/healfastusa.org.crt
# sudo cp /etc/letsencrypt/live/YOUR_DOMAIN/privkey.pem healfast-branding/ssl/healfastusa.org.key
docker compose restart proxy
```

## Support

For issues or questions:
- Check Bahmni documentation: https://bahmni.atlassian.net/
- HealFast USA support (see README)

## Security Notes

1. **Change all default passwords** in `.env` file
2. **Use strong passwords** (minimum 16 characters, mixed case, numbers, symbols)
3. **Keep SSL certificates updated**
4. **Regularly update Docker images** for security patches
5. **Monitor logs** for suspicious activity
6. **Restrict SSH access** to known IPs if possible
7. **Enable firewall** (UFW) and only open necessary ports

## Next Steps

After successful deployment:

1. Configure OpenMRS users and roles
2. Set up clinic locations and departments
3. Configure clinical forms and templates
4. Set up reporting dashboards
5. Configure email notifications (if needed)
6. Set up automated backups
7. Configure monitoring and alerts

---

**Deployment Date:** _______________
**Deployed By:** _______________
**Server IP:** _______________
**Notes:** _______________
