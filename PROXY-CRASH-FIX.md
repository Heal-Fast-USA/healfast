# Proxy (nginx) keeps restarting – fix

If **bahmni-lite-proxy-1** shows `Restarting (1)` and the site refuses to connect:

## 1. See why nginx is crashing

On the server:

```bash
docker logs bahmni-lite-proxy-1 2>&1 | tail -40
```

Typical messages:
- **"cannot load certificate"** or **"BIO_new_file() failed"** → SSL cert or key missing/wrong path
- **"open() ... failed"** → missing file (often SSL)
- **"host not found"** → upstream hostname not resolving (less common)

## 2. Ensure SSL certs exist and are used

Nginx needs these files inside the container (mounted from `healfast-branding/ssl/`):

- `healfastusa.org.crt`
- `healfastusa.org.key`

On the server check:

```bash
ls -la /opt/bahmni-docker/healfast-branding/ssl/
```

You should see `healfastusa.org.crt` and `healfastusa.org.key`.

**If the directory is empty or files are missing:**

- Use the SSL setup script:
  ```bash
  cd /opt/bahmni-docker/healfast-branding
  sudo bash setup-ssl.sh
  ```
  (e.g. choose self-signed for testing.)

- Or copy your own certs:
  ```bash
  sudo cp /path/to/your/fullchain.pem /opt/bahmni-docker/healfast-branding/ssl/healfastusa.org.crt
  sudo cp /path/to/your/privkey.pem /opt/bahmni-docker/healfast-branding/ssl/healfastusa.org.key
  ```

## 3. Restart the proxy

```bash
cd /opt/bahmni-docker/bahmni-lite
sudo docker compose -f docker-compose.yml -f ../healfast-branding/docker-compose.override.yml --env-file .env restart proxy
```

Check status:

```bash
docker ps | grep proxy
```

It should show **Up** (not Restarting).

## 4. Optional: test nginx config before restart

```bash
docker run --rm -v /opt/bahmni-docker/healfast-branding/nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro -v /opt/bahmni-docker/healfast-branding/ssl:/etc/nginx/ssl:ro nginx:alpine nginx -t
```

If this reports an error, fix the config or SSL paths (see step 2).
