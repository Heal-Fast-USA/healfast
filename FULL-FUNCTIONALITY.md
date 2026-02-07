# Achieving Full Functionality – HealFast Bahmni

Full functionality means: all required containers are **Up**, HealFast branding is visible, and you can use **clinic** and **staff** URLs for login, registration, clinical, and reports.

---

## 1. Get all containers stable (no Restarting)

Do these on the server in order.

### 1.1 Apply HealFast update (fix bahmni-config + proxy)

```bash
cd /opt/bahmni-docker/healfast-branding
sudo git pull
sudo bash update-server.sh
```

This syncs `config` → `config_etc`, sets `.env` paths, and recreates **bahmni-config** and **proxy**.

**Check:**  
`docker ps -a --filter name=bahmni-config --filter name=proxy`  
Both should show **Up**.  
`docker logs bahmni-lite-bahmni-config-1 --tail 15` should have **no** “same file” errors.

### 1.2 Fix reports (OpenMRS DB password)

Reports needs the same OpenMRS DB password as in `.env`:

```bash
# Use the password from your .env (OPENMRS_DB_PASSWORD)
docker exec -it bahmni-lite-openmrsdb-1 mysql -u root -pYOUR_ROOT_PASSWORD -e "ALTER USER 'openmrs'@'%' IDENTIFIED BY 'YOUR_OPENMRS_DB_PASSWORD'; FLUSH PRIVILEGES;"
```

Then restart reports:

```bash
cd /opt/bahmni-docker/bahmni-lite
sudo docker compose -f docker-compose.yml -f ../healfast-branding/docker-compose.override.yml --env-file .env restart reports
```

**Check:**  
`docker ps -a --filter name=reports` → **Up**.  
`docker logs bahmni-lite-reports-1 --tail 20` → no “Access denied” for user `openmrs`.

### 1.3 Proxy (nginx)

If proxy is still **Restarting**:

- Confirm SSL files exist:  
  `ls -la /opt/bahmni-docker/healfast-branding/ssl/`  
  You need `healfastusa.org.crt` and `healfastusa.org.key`.
- Confirm nginx config:  
  `docker run --rm -v /opt/bahmni-docker/healfast-branding/nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro nginx:alpine nginx -t`
- After `update-server.sh`, proxy should already be recreated; if not:  
  `sudo docker compose -f docker-compose.yml -f ../healfast-branding/docker-compose.override.yml --env-file .env up -d --force-recreate proxy`

---

## 2. DNS and URLs

- **clinic.healfastusa.org** and **staff.healfastusa.org** must resolve to your server IP (e.g. **69.30.247.92**).
- SSL cert (self-signed or Let’s Encrypt) should include those hostnames (and optionally the IP).

Without DNS, you can still test by IP if your nginx has a default server and the cert has the IP in SAN (see `env.template` / deploy script).

---

## 3. Verification – “full functionality” checklist

Run on the server:

```bash
cd /opt/bahmni-docker/bahmni-lite
COMPOSE="docker compose -f docker-compose.yml -f ../healfast-branding/docker-compose.override.yml --env-file .env"
$COMPOSE ps
```

**Containers that should be Up (not Restarting):**

| Service              | Purpose                          |
|----------------------|----------------------------------|
| proxy                | HTTPS, routes to apps            |
| bahmni-config        | Config for OpenMRS/others        |
| bahmni-web           | HealFast UI, login/landing       |
| openmrs              | EMR backend                      |
| openmrsdb            | OpenMRS database                 |
| reports              | Bahmni reports                   |
| reportsdb            | Reports DB                       |
| implementer-interface| Admin/implementer               |
| bahmni-apps-frontend | New UI apps                     |
| appointments         | Appointments                     |
| bahmni-lab           | Lab (if used)                    |
| patient-documents    | Documents                        |

Optional (Crater, atomfeed, etc.): up if you use them; otherwise can stay stopped.

**Browser checks:**

1. **https://clinic.healfastusa.org** (or your URL)  
   - Loads without certificate/proxy errors.  
   - HealFast logo and green theme (Poppins, custom CSS).  
   - Login page works.

2. **Login**  
   - Use an OpenMRS/Bahmni user (e.g. admin).  
   - You should reach the main app (registration, clinical, etc.).

3. **Reports**  
   - Open **https://clinic.healfastusa.org/bahmni-reports/** (or equivalent).  
   - Should load without “Access denied” or 502.

4. **Staff / implementer**  
   - **https://staff.healfastusa.org** and/or **/implementer-interface/**  
   - Should load and allow admin tasks if you use them.

When all of the above are true, you have **full functionality** for your current deployment.

---

## 4. Optional: simplify by not using clinic-config (Annoor-style)

The **bahmni-config** (clinic-config) container exists to copy/merge config for OpenMRS and other services. Its “same file” issue comes from the image’s internal paths.

**Alternative:** Don’t run **bahmni-config** at all; rely only on:

- **bahmni-web** – mount HealFast `config` at `/usr/local/apache2/htdocs/bahmni_config/` (already in our override).
- **openmrs** – mount the same config at `/etc/bahmni_config/` (base bahmni-lite compose already has `CONFIG_VOLUME` → `/etc/bahmni_config/` for openmrs).

So: ensure **openmrs** gets config from your HealFast `config` (or `config_etc`) via its volume, and **bahmni-web** gets it from our override. Then you can **stop and disable** the **bahmni-config** service so it never runs.

**How to disable bahmni-config (optional):**

- In a copy of the override or in the compose you use, you can comment out or remove the `bahmni-config` service, or add a profile so it’s not started by default.  
- Or simply:  
  `docker stop bahmni-lite-bahmni-config-1`  
  and do not start it again.  
- Ensure **openmrs** still has a volume pointing to your HealFast config (e.g. `CONFIG_VOLUME` or `CONFIG_VOLUME_ETC` → `/etc/bahmni_config/`).  
- Restart **openmrs** and **bahmni-web** after any config change.

This gives you full functionality without the clinic-config container; branding and config are “mount only,” like [Annoor-Hospital/bahmni-web](https://github.com/Annoor-Hospital/bahmni-web).

---

## 5. One-page “get to full functionality” script (server)

You can run these in one go (adjust passwords to match your `.env`):

```bash
cd /opt/bahmni-docker/healfast-branding
sudo git pull
sudo bash update-server.sh

# Fix reports DB password (replace with your OPENMRS_DB_PASSWORD and root password)
OPENMRS_PASS="HealFast2024Secure"   # or from .env
ROOT_PASS="HealFast2024Secure"       # or your MYSQL_ROOT_PASSWORD
docker exec bahmni-lite-openmrsdb-1 mysql -u root -p"$ROOT_PASS" -e "ALTER USER 'openmrs'@'%' IDENTIFIED BY '$OPENMRS_PASS'; FLUSH PRIVILEGES;"

cd /opt/bahmni-docker/bahmni-lite
sudo docker compose -f docker-compose.yml -f ../healfast-branding/docker-compose.override.yml --env-file .env restart reports

echo "Wait ~1 min then check: docker ps"
```

After that, use the verification steps in **§3** to confirm full functionality.
