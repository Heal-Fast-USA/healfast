# Why 9443 Works But Customized (HealFast) Doesn’t Show

## What you’re seeing

- **https://69.30.247.92:9443** → Works, but shows **default Bahmni** (no HealFast logo/colors).
- **Customized (HealFast)** → Should appear at **https://clinic.healfastusa.org** and **https://staff.healfastusa.org** (port 443).

## Why

- **Port 9443** is the default Bahmni proxy. It does **not** use the HealFast override, so you get default branding.
- The **HealFast customization** is served by our **nginx proxy on 80/443** (from the override). So the customized UI is only on:
- **https://clinic.healfastusa.org** and **https://staff.healfastusa.org** (port 443)
- **http://** (port 80, redirects to https)

## What to do

### 1. Use the right URL for HealFast

Open:

- **https://clinic.healfastusa.org**

Do **not** use `:9443` for the customized version.

### 2. If https://69.30.247.92 doesn’t load or shows errors

Then the HealFast proxy (nginx on 80/443) isn’t running or is failing. On the server run:

```bash
# Are you using the override?
cd /opt/bahmni-docker/bahmni-lite
grep HEALFAST_BRANDING_PATH .env
# Should show: HEALFAST_BRANDING_PATH=/opt/bahmni-docker/healfast-branding

# Is the proxy container up (not restarting)?
docker ps | grep proxy
# If status is "Restarting", see PROXY-CRASH-FIX.md (SSL certs, etc.)

# Start (or restart) with the HealFast override so 80/443 are used
sudo docker compose -f docker-compose.yml -f ../healfast-branding/docker-compose.override.yml --env-file .env up -d
```

### 3. Make sure branding is mounted

HealFast logo/CSS come from `CONFIG_VOLUME` and the override. Check:

```bash
# On server
docker exec bahmni-lite-bahmni-web-1 ls -la /usr/local/apache2/htdocs/bahmni_config/openmrs/apps/home/
# You should see logo.png, whiteLabel.json
```

If those files are missing, `.env` likely doesn’t have the right paths or compose wasn’t run with the override.

## Summary

| URL | What it is |
|-----|------------|
| https://69.30.247.92**:9443** | Default Bahmni proxy → **no HealFast** branding |
| **https://clinic.healfastusa.org** / **https://staff.healfastusa.org** (port 443) | HealFast nginx proxy → **customized** logo, colors, CSS |

Use **https://clinic.healfastusa.org** or **https://staff.healfastusa.org** for the customized HealFast UI. If that doesn’t work, fix the proxy (SSL + override) using the commands above and PROXY-CRASH-FIX.md.
