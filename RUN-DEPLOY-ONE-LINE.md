# One-Line Deploy to Server

Deploy HealFast Bahmni to **91.221.36.80** (single server, no subdomains).

## Option 1: From Linux/Mac/WSL (with sshpass)

Install sshpass if needed:
- Ubuntu/Debian: `sudo apt-get install -y sshpass`
- Mac: `brew install sshpass` (or use Option 2)

**One-line command:**

```bash
sshpass -p 'YOUR_PASSWORD' ssh -o StrictHostKeyChecking=no administrator@91.221.36.80 'bash -s' < deploy-healfast-remote.sh
```

Or with full path to script:

```bash
sshpass -p 'YOUR_PASSWORD' ssh -o StrictHostKeyChecking=no administrator@91.221.36.80 'bash -s' < /path/to/healfast-branding/deploy-healfast-remote.sh
```

## Option 2: Without sshpass (any OS)

**Step 1 – Copy script (from your machine):**
```bash
scp -o StrictHostKeyChecking=no deploy-healfast-remote.sh administrator@91.221.36.80:~/
```

**Step 2 – SSH in and run (you’ll be prompted for password):**
```bash
ssh -o StrictHostKeyChecking=no administrator@91.221.36.80 'chmod +x ~/deploy-healfast-remote.sh && bash ~/deploy-healfast-remote.sh'
```

**One line that fetches and runs from GitHub:**

```bash
ssh -o StrictHostKeyChecking=no administrator@91.221.36.80 "curl -sSL https://raw.githubusercontent.com/goodwinbrannon005-alt/bahmni-healfast/main/deploy-healfast-remote.sh | bash"
```

## What the script does

1. Installs Docker (and Docker Compose) if missing  
2. Clones/updates Bahmni Docker to `/opt/bahmni-docker`  
3. Clones/updates HealFast branding from GitHub to `/opt/bahmni-docker/healfast-branding`  
4. Ensures SSL certs exist (creates self-signed for 91.221.36.80 if missing)  
5. Creates `.env` in `bahmni-lite` with absolute paths and default passwords  
6. Runs `docker compose` with the HealFast override and starts all services  

## After deploy

- Wait **5–10 minutes** for all containers to start.  
- Open: **https://91.221.36.80**  
- Change default passwords in `/opt/bahmni-docker/bahmni-lite/.env` on the server.  
- To use your own SSL certs, place `healfastusa.org.crt` and `healfastusa.org.key` in `healfast-branding/ssl/` on the server and restart the proxy.  

## Security

- Change the server password after first login.  
- Prefer SSH keys: `ssh-copy-id administrator@91.221.36.80`  
- Change **HealFast2024Secure** in `/opt/bahmni-docker/bahmni-lite/.env` to strong, unique passwords.  

## Troubleshooting

- **Permission denied:** Check username/password and SSH auth.  
- **Docker: permission denied:** On the server run `sudo usermod -aG docker administrator` and re-login.  
- **Containers not starting:** On server run:  
  `cd /opt/bahmni-docker/bahmni-lite && sudo docker compose -f docker-compose.yml -f ../healfast-branding/docker-compose.override.yml --env-file .env logs -f`  
