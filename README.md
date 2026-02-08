# HealFast USA – Bahmni Branding

Branding (logo, green theme, Poppins) for Bahmni. Subdomains: **clinic.healfastusa.org**, **staff.healfastusa.org** (IP 69.30.247.92).

## One command on the server (fix all issues)

```bash
cd /opt/bahmni-docker/healfast-branding
sudo bash fix-all.sh
```

This runs path fixes, SSL bootstrap, stack start, and proxy reload. For **trusted HTTPS** (Let's Encrypt) in one go:

```bash
sudo bash fix-all.sh --letsencrypt
```

(Requires DNS for clinic.healfastusa.org and staff.healfastusa.org pointing to the server.)

Alternatively, use **fix-and-start.sh** for the same steps without Certbot.

This script:

- Syncs `config` → `config_etc` and creates **acme-webroot** for Let's Encrypt
- Creates **self-signed SSL** in `ssl/` if missing (proxy mounts it at `/etc/nginx/ssl`); replace with Let's Encrypt (see below)
- Sets **absolute** paths in `.env`: HEALFAST_BRANDING_PATH, CONFIG_VOLUME, CONFIG_VOLUME_ETC, CERTIFICATE_PATH
- Starts the stack **without** bahmni-config (avoids restart loop)
- Fixes OpenMRS DB password for reports

**Customization:** `/bahmni_config/` (logo, CSS, whiteLabel) is served by nginx from the config folder so branding applies reliably.

---

## HTTPS with Let's Encrypt (Certbot)

To fix browser certificate errors and use trusted HTTPS:

### 1. Install Certbot on the server (Debian/Ubuntu)

```bash
sudo apt-get update
sudo apt-get install -y certbot python3-certbot-nginx
# OR for Apache: sudo apt-get install -y certbot python3-certbot-apache
```

Or run the provided script:

```bash
cd /opt/bahmni-docker/healfast-branding
sudo bash scripts/install-certbot.sh
```

### 2. Ensure DNS and stack are running

- **clinic.healfastusa.org** and **staff.healfastusa.org** must resolve to your server IP.
- Run `sudo bash fix-and-start.sh` so nginx is up and **acme-webroot** is used for challenges.

### 3. Obtain the certificate

```bash
cd /opt/bahmni-docker/healfast-branding
sudo bash scripts/obtain-letsencrypt.sh
```

This uses Certbot **webroot** (nginx serves `/.well-known/acme-challenge/` from `acme-webroot/`). The script copies the Let's Encrypt cert into `ssl/healfastusa.org.crt` and `ssl/healfastusa.org.key` and reloads nginx. Browsers will then trust HTTPS.

### 4. Auto-renewal (cron)

```bash
sudo certbot renew --dry-run
# Then add to crontab (e.g. 3 AM daily):
# 0 3 * * * root certbot renew -q --deploy-hook "/opt/bahmni-docker/healfast-branding/scripts/copy-certs-and-reload.sh"
```

---

## Repo layout

- **fix-and-start.sh** – fix paths, SSL, and start stack
- **scripts/install-certbot.sh** – install Certbot (apt)
- **scripts/obtain-letsencrypt.sh** – obtain/renew Let's Encrypt cert and copy to `ssl/`
- **scripts/copy-certs-and-reload.sh** – copy certs and reload nginx (used by renew hook)
- **config/** – logo, favicon, whiteLabel.json, healfast-custom.css
- **nginx/nginx.conf** – proxy + ACME challenge for Certbot
- **docker-compose.override.yml** – proxy (ssl + acme-webroot), bahmni-web, bahmni-config overrides
- **env.template** – sample .env (passwords and paths)

## First-time setup

1. Clone this repo next to **bahmni-lite** (e.g. `/opt/bahmni-docker/healfast-branding`).
2. If bahmni-lite has no `.env`, copy `env.template` to `bahmni-lite/.env` (or let fix-and-start.sh create it).
3. Run: `sudo bash fix-and-start.sh`
4. For trusted HTTPS: install Certbot, then run `sudo bash scripts/obtain-letsencrypt.sh`.

## DNS

Point **clinic.healfastusa.org** and **staff.healfastusa.org** to your server IP (69.30.247.92).

## Mixed content (HTTPS)

If the app requests `http://...` on an HTTPS page, set OpenMRS base URL to HTTPS:

1. Open **https://clinic.healfastusa.org/openmrs** → Advanced Settings → Global Property.
2. Set **bahmni.baseUrl** to **https://clinic.healfastusa.org** (no trailing slash). Save and hard-refresh.
