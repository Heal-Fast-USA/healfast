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

**Pull and fix (after git updates):**
```bash
cd /opt/bahmni-docker/healfast-branding
sudo bash pull-and-fix.sh
# or with Let's Encrypt:  sudo bash pull-and-fix.sh --letsencrypt
```

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

## /bahmni-reports/ not working

Reports are served at **https://.../bahmni-reports/** (and **/bahmni/reports/** from the dashboard link). Ensure:

1. **Profiles:** `.env` has `COMPOSE_PROFILES=emr,bahmni-lite` so the `reports` and `reportsdb` services start.
2. **After fix-and-start:** Run `sudo bash fix-and-start.sh` or `sudo bash pull-and-fix.sh`; they restart reports and run `scripts/ensure-reports-running.sh`.
3. **502 on /bahmni-reports/:** The reports container may listen on **8080** instead of **8050**. In `nginx/nginx.conf`, change `set $reports_backend reports:8050;` to `set $reports_backend reports:8080;` in both server blocks, then `docker compose restart proxy`.
4. **Check containers:** `docker ps | grep reports` should show `reports` and `reportsdb` running. If not, run `docker compose -f bahmni-lite/docker-compose.yml -f healfast-branding/docker-compose.override.yml --env-file bahmni-lite/.env up -d reports reportsdb`.

## Branding and dashboard (/bahmni/home/#/dashboard)

Config (logo, CSS, whiteLabel) is served by nginx at `/bahmni_config/` so it applies to both clinic and staff. If the dashboard keeps loading (spinner never stops), the custom CSS includes a fallback that hides the loader after ~10s so the page can show. Ensure **fix-and-start.sh** or **pull-and-fix.sh** has been run so config is synced and the proxy is reloaded.

## Repo layout

- **pull-and-fix.sh** – git pull then fix-all (run after updates)
- **fix-all.sh** – fix paths, SSL, stack, optional Certbot
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

## Mixed content (HTTPS) – "requested an insecure XMLHttpRequest endpoint"

The app must use HTTPS for API calls. **fix-and-start.sh** and **pull-and-fix.sh** now run **scripts/set-baseurl-https-db.sh**, which sets **bahmni.baseUrl** in the OpenMRS database to the value of **BAHMNI_BASE_URL** in `.env` (default **https://staff.healfastusa.org**).

- **Staff:** Leave default or set in bahmni-lite `.env`: `BAHMNI_BASE_URL=https://staff.healfastusa.org`
- **Clinic only:** Set `BAHMNI_BASE_URL=https://clinic.healfastusa.org` in `.env`, then run **fix-and-start.sh** or **pull-and-fix.sh** again.

After running, hard-refresh the browser (Ctrl+F5). If mixed content persists:

1. **Manual:** Open **https://staff.healfastusa.org/openmrs** → Admin → **Advanced Settings → Global Property** → set **bahmni.baseUrl** to **https://staff.healfastusa.org** (no trailing slash). Save and hard-refresh.
2. **Run DB script alone:** `cd healfast-branding && BAHMNI_BASE_URL=https://staff.healfastusa.org bash scripts/set-baseurl-https-db.sh`

## CSP / ChunkLoadError (script blocked, loading forever)

If you see "Loading the script ... violates the following Content Security Policy" or "ChunkLoadError: Loading chunk failed", it is often a **browser extension** (e.g. password manager, ad blocker) injecting a strict CSP. Try:

- Open the site in an **incognito/private window** (extensions usually disabled), or  
- Disable extensions for **staff.healfastusa.org** / **clinic.healfastusa.org**.

The server sends a permissive CSP so app scripts can load; if the error persists, the block is from the extension.
