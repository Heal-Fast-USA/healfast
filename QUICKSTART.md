# HealFast USA - Quick Start Guide

This is a condensed quick start guide. For detailed instructions, see [DEPLOYMENT.md](DEPLOYMENT.md).

## Prerequisites Checklist

- [ ] Ubuntu Server 22.04 LTS
- [ ] Root/sudo access
- [ ] DNS: clinic.healfastusa.org and staff.healfastusa.org → 69.30.247.92
- [ ] Ports 80, 443, 22 open

## 5-Minute Setup

### Step 1: Install Docker (2 minutes)

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Log out and back in
```

### Step 2: Initialize Branding (1 minute)

```bash
cd /path/to/bahmni-docker/healfast-branding
chmod +x init-branding.sh setup-ssl.sh
./init-branding.sh
```

### Step 3: Set Up SSL (1 minute)

```bash
./setup-ssl.sh
# Choose option 1 (Let's Encrypt) for production
# Or option 3 (self-signed) for testing
```

### Step 4: Configure Environment (1 minute)

```bash
cd ../bahmni-lite  # or bahmni-standard
cp ../healfast-branding/env.template .env
vim .env  # Update passwords and CONFIG_VOLUME path
```

**Required changes in `.env`:**
```bash
CONFIG_VOLUME=/absolute/path/to/bahmni-docker/healfast-branding/config
OPENMRS_DB_PASSWORD=<strong-password>
MYSQL_ROOT_PASSWORD=<strong-password>
```

### Step 5: Start Services

```bash
cp ../healfast-branding/docker-compose.override.yml .
docker compose -f docker-compose.yml -f docker-compose.override.yml --env-file .env up -d
```

### Step 6: Wait and Verify

```bash
# Wait 10-15 minutes for initial setup
docker compose logs -f

# Verify services are running
docker compose ps

# Test URL
curl -I https://clinic.healfastusa.org
```

## Verification

1. Open browser: `https://clinic.healfastusa.org` or `https://staff.healfastusa.org`
2. Check for:
   - ✓ HealFast logo
   - ✓ Green theme
   - ✓ Poppins font
   - ✓ No SSL warnings

## Common Issues

**Services won't start?**
```bash
docker compose logs
docker compose ps
```

**Logo not showing?**
```bash
docker compose exec bahmni-web ls -la /usr/local/apache2/htdocs/bahmni_config/
docker compose restart bahmni-web
```

**SSL errors?**
```bash
ls -lh healfast-branding/ssl/
docker compose restart proxy
```

## Next Steps

1. Access OpenMRS admin: `https://clinic.healfastusa.org/openmrs`
2. Create users and configure system
3. Set up clinic locations
4. Configure clinical forms

For detailed instructions, see [DEPLOYMENT.md](DEPLOYMENT.md).
