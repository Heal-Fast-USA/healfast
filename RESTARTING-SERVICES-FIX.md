# Fix Restarting Containers (bahmni-config, reports, crater-php)

## 1. bahmni-config – "same file" error

**Cause:** The override mounted the same config to both `/usr/local/bahmni_config` and `/etc/bahmni_config`, so the image’s copy step failed.

**Fix (in repo):** Override mounts your config to `/usr/local/bahmni_config` and a separate named volume to `/etc/bahmni_config` so the image's copy step has two distinct paths. Update and recreate the container:

```bash
cd /opt/bahmni-docker/healfast-branding
sudo git pull origin main
cd /opt/bahmni-docker/bahmni-lite
sudo docker compose -f docker-compose.yml -f ../healfast-branding/docker-compose.override.yml --env-file .env up -d --force-recreate bahmni-config
```

---

## 2. reports – "Access denied for user 'openmrs'"

**Cause:** Reports is using the password from `.env` (e.g. `HealFast2024Secure`), but the OpenMRS MySQL user was created with a different password.

**Fix:** Set the OpenMRS MySQL user password to match `.env`:

```bash
# Use the same password as in .env (OPENMRS_DB_PASSWORD)
docker exec -it bahmni-lite-openmrsdb-1 mysql -u root -pHealFast2024Secure -e "ALTER USER 'openmrs'@'%' IDENTIFIED BY 'HealFast2024Secure'; FLUSH PRIVILEGES;"
```

If your root password is different, use it:

```bash
docker exec -it bahmni-lite-openmrsdb-1 mysql -u root -pYOUR_MYSQL_ROOT_PASSWORD -e "ALTER USER 'openmrs'@'%' IDENTIFIED BY 'HealFast2024Secure'; FLUSH PRIVILEGES;"
```

Then restart reports:

```bash
cd /opt/bahmni-docker/bahmni-lite
sudo docker compose -f docker-compose.yml -f ../healfast-branding/docker-compose.override.yml --env-file .env restart reports
```

---

## 3. crater-php – "country_id 566" foreign key error

**Cause:** `CRATER_COUNTRY_ID=566` (Nigeria) is not in Crater’s `countries` table, so the seeder fails.

**Fix:** Use a country ID that exists in Crater (e.g. `1` or `231` for USA). Already updated in `env.template` to `CRATER_COUNTRY_ID=1`. On the server:

```bash
# Update .env
sudo sed -i 's/CRATER_COUNTRY_ID=566/CRATER_COUNTRY_ID=1/' /opt/bahmni-docker/bahmni-lite/.env

# Recreate crater containers (clean start; may lose existing Crater data)
cd /opt/bahmni-docker/bahmni-lite
sudo docker compose -f docker-compose.yml -f ../healfast-branding/docker-compose.override.yml --env-file .env stop crater-php crater-nginx craterdb
sudo docker compose -f docker-compose.yml -f ../healfast-branding/docker-compose.override.yml --env-file .env rm -f crater-php crater-nginx craterdb
# Remove crater volume if you want a fresh DB (optional):
# docker volume rm bahmni-lite_craterdb 2>/dev/null || true
sudo docker compose -f docker-compose.yml -f ../healfast-branding/docker-compose.override.yml --env-file .env up -d craterdb
# Wait ~30 sec for DB to be ready, then:
sudo docker compose -f docker-compose.yml -f ../healfast-branding/docker-compose.override.yml --env-file .env up -d crater-php crater-nginx
```

If you need Nigeria and your Crater has it under another ID, look up the ID in the DB and set `CRATER_COUNTRY_ID` to that value.
