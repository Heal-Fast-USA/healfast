# Fix proxy + bahmni-config restart loops (server)

If **proxy** and **bahmni-config** are both **Restarting**, do the following on the server.

---

## 1. See why proxy is failing

```bash
docker logs bahmni-lite-proxy-1 --tail 30
```

Common causes:

- **HEALFAST_BRANDING_PATH** not set or wrong in `.env` → nginx mounts are wrong.
- **SSL files missing** → `ls -la /opt/bahmni-docker/healfast-branding/ssl/` should show `healfastusa.org.crt` and `healfastusa.org.key`.
- **Nginx config error** → fix with the latest repo (default_server added for 443).

**Checks:**

```bash
# .env must have absolute path
grep HEALFAST_BRANDING_PATH /opt/bahmni-docker/bahmni-lite/.env
# Should be: HEALFAST_BRANDING_PATH=/opt/bahmni-docker/healfast-branding

# SSL files must exist
ls -la /opt/bahmni-docker/healfast-branding/ssl/
```

If SSL is missing, create self-signed (from healfast-branding dir):

```bash
cd /opt/bahmni-docker/healfast-branding
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/healfastusa.org.key -out ssl/healfastusa.org.crt \
  -subj "/CN=clinic.healfastusa.org" \
  -addext "subjectAltName=DNS:clinic.healfastusa.org,DNS:staff.healfastusa.org,IP:69.30.247.92"
```

---

## 2. Run without bahmni-config (stops “same file” loop)

OpenMRS and bahmni-web already get config from **CONFIG_VOLUME** in the base compose. You can leave the **bahmni-config** container off:

```bash
cd /opt/bahmni-docker/bahmni-lite

# Pull latest (nginx default_server fix) if you haven’t
cd /opt/bahmni-docker/healfast-branding && sudo git pull && cd ../bahmni-lite

# Start everything except bahmni-config (scale 0)
sudo docker compose -f docker-compose.yml -f ../healfast-branding/docker-compose.override.yml --env-file .env up -d --scale bahmni-config=0
```

Then check:

```bash
docker ps -a --filter name=proxy --filter name=bahmni-config
```

- **proxy** should be **Up** (if .env and SSL are correct).
- **bahmni-config** will show **0** replicas / not running (that’s intentional).

---

## 3. If proxy is still Restarting

Inspect the exact error:

```bash
docker logs bahmni-lite-proxy-1 2>&1 | tail -20
```

- **“no such file”** or **“open() failed”** → fix **HEALFAST_BRANDING_PATH** and/or create SSL under `healfast-branding/ssl/`.
- **“invalid parameter”** or **nginx -t error** → ensure you pulled the latest `nginx/nginx.conf` (with `default_server` on the 443 server block).

Test nginx config locally (replace path if needed):

```bash
docker run --rm -v /opt/bahmni-docker/healfast-branding/nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro nginx:alpine nginx -t
```

---

## 4. Summary

| Step | Action |
|------|--------|
| 1 | Check proxy logs; fix HEALFAST_BRANDING_PATH and SSL if needed |
| 2 | `git pull` in healfast-branding (nginx default_server) |
| 3 | Run: `docker compose ... up -d --scale bahmni-config=0` |
| 4 | Verify: `docker ps` → proxy Up, bahmni-config not running |

After this, use **https://clinic.healfastusa.org** (or your URL); HealFast branding comes from the **bahmni-web** and **openmrs** config mounts, not from the bahmni-config container.
