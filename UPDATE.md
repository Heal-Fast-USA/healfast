# Update the server from this repo

Use this when the server is already deployed and you want to apply the latest HealFast branding (e.g. fix bahmni-config “same file” and proxy).

## One-time setup: get the repo on the server

If healfast-branding is not on the server yet:

```bash
sudo mkdir -p /opt/bahmni-docker
cd /opt/bahmni-docker
sudo git clone https://github.com/goodwinbrannon005-alt/bahmni-healfast.git healfast-branding
# Or copy the repo contents into /opt/bahmni-docker/healfast-branding
```

If the repo is already there (e.g. under `/opt/bahmni-docker/healfast-branding`):

```bash
cd /opt/bahmni-docker/healfast-branding
sudo git pull
```

## Apply the update

Run the update script from the healfast-branding directory:

```bash
cd /opt/bahmni-docker/healfast-branding
sudo bash update-server.sh
```

This script will:

1. Sync **config** → **config_etc** (so bahmni-config sees two separate dirs and stops “same file” errors).
2. Set **HEALFAST_BRANDING_PATH**, **CONFIG_VOLUME**, and **CONFIG_VOLUME_ETC** in `bahmni-lite/.env` (absolute paths).
3. Recreate **bahmni-config** and **proxy** with the override.

## Check that it worked

```bash
docker ps -a --filter name=bahmni-config --filter name=proxy
docker logs bahmni-lite-bahmni-config-1 --tail 20
```

- **bahmni-config** should be **Up** (not Restarting) and logs should not show “same file”.
- **proxy** should be **Up**.

## If bahmni-lite or healfast-branding is in a different path

```bash
export HEALFAST_BRANDING_PATH=/path/to/healfast-branding
export BAHMNI_LITE_PATH=/path/to/bahmni-lite
sudo -E bash update-server.sh
```

## Other restarting containers

- **reports** – See [RESTARTING-SERVICES-FIX.md](RESTARTING-SERVICES-FIX.md) (OpenMRS DB password).
- **crater-php** – Already fixed with CRATER_COUNTRY_ID=1; recreate if needed.
