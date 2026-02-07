# HealFast USA – Bahmni Branding

Branding (logo, green theme, Poppins) for Bahmni. Subdomains: **clinic.healfastusa.org**, **staff.healfastusa.org** (IP 69.30.247.92).

## One command on the server

```bash
cd /opt/bahmni-docker/healfast-branding
sudo bash fix-and-start.sh
```

This script:

- Syncs `config` → `config_etc`
- Creates self-signed SSL in `ssl/` if missing
- Sets `.env` paths (HEALFAST_BRANDING_PATH, CONFIG_VOLUME, CONFIG_VOLUME_ETC)
- Starts the stack **without** bahmni-config (avoids restart loop)
- Fixes OpenMRS DB password for reports and restarts reports

No other steps needed. Then open **https://clinic.healfastusa.org** (or your URL).

## Repo layout

- **fix-and-start.sh** – single script to fix and start
- **config/** – logo, favicon, whiteLabel.json, healfast-custom.css
- **nginx/nginx.conf** – proxy for clinic + staff subdomains
- **docker-compose.override.yml** – proxy, bahmni-web, bahmni-config overrides
- **env.template** – sample .env (passwords and paths)

## First-time setup

1. Clone or copy this repo next to **bahmni-lite** (e.g. `/opt/bahmni-docker/healfast-branding`).
2. If bahmni-lite has no `.env`, copy `env.template` to `bahmni-lite/.env` and set passwords (or let fix-and-start.sh create it from env.template).
3. Run: `sudo bash fix-and-start.sh`

## DNS

Point **clinic.healfastusa.org** and **staff.healfastusa.org** to your server IP (69.30.247.92).

## Mixed content (HTTPS)

If the browser blocks requests to `http://...openmrs/...` (mixed content), set OpenMRS to use HTTPS:

1. Log in to OpenMRS Admin: **https://clinic.healfastusa.org/openmrs** (admin user).
2. Go to **Advanced Settings → Global Property**.
3. Find **bahmni.baseUrl** (or similar) and set it to **https://clinic.healfastusa.org** (no trailing slash). Create it if missing.
4. Save and hard-refresh the app.
