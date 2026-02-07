# Annoor-Hospital/bahmni-web – How they implemented it

Cloned from: https://github.com/Annoor-Hospital/bahmni-web

## Structure

```
annoor-bahmni-web/
├── docker/
│   ├── Dockerfile          # httpd:2.4-alpine, port 8091, custom httpd.conf + systemdate CGI
│   ├── httpd.conf          # Full Apache config: Listen 8091, security headers, DocumentRoot htdocs
│   ├── index.html          # Placeholder (simple "mount files here" page)
│   └── systemdate.sh       # CGI script: returns server date/offset as JSON (for timezone warning)
├── www/                    # Sample static files to mount
│   ├── index.html          # Full Bahmni landing page (logo, whiteLabel.json, apps, timezone warning)
│   ├── maintenance.html
│   ├── style.css
│   └── unauthorized.html
├── LICENSE (MIT)
└── README.md
```

## How they fixed / implemented

1. **Custom image (optional)**  
   - Base: `httpd:2.4-alpine`.  
   - They expose **port 8091** (not 80) so it can sit behind a proxy.  
   - Custom `httpd.conf`: `Listen 8091`, security headers (`X-Robots-Tag`, `X-Frame-Options`), logs to stdout/stderr.  
   - **systemdate CGI**: `/cgi-bin/systemdate` returns `{"date":"...","offset":"..."}` so the landing page can show a timezone mismatch warning.

2. **Content by volume mount**  
   - They **do not** bake app content into the image.  
   - Compose example: mount `./bahmni-web` → `/usr/local/apache2/htdocs`.  
   - They tell you to put `bahmniapps` and `bahmni_config` in that folder (or mount them as separate volumes after the main htdocs mount).  
   - So branding/config is entirely **outside** the image, same idea as HealFast’s `CONFIG_VOLUME` → `bahmni_config`.

3. **Landing page (www/index.html)**  
   - Single HTML file that:  
     - Fetches **whiteLabel.json** from `/bahmni_config/openmrs/apps/home/whiteLabel.json`.  
     - Uses it for: logo, header text, title, help link, bottom banner, **landing page apps** (from `data.landingPage`).  
     - Calls `/cgi-bin/systemdate` for server time/offset and shows a warning if browser and server timezones differ.  
   - So they use the same **whiteLabel** contract as Bahmni/HealFast; we already do that with our `config/openmrs/apps/home/whiteLabel.json`.

4. **No clinic-config / “same file”**  
   - This repo is **only** the web server (Apache + static files).  
   - They don’t run the `bahmni/clinic-config` container, so they have no copy-between-`/etc`-and-`/usr/local` logic.  
   - Branding is “mount your own htdocs (and bahmni_config)”; no config container needed.

## What HealFast already does (aligned with Annoor)

- Branding via **mount**: we mount `CONFIG_VOLUME` to `bahmni-web` at `/usr/local/apache2/htdocs/bahmni_config/` and use `whiteLabel.json` + custom CSS/logo.  
- Proxy in front: nginx handles SSL and routes to bahmni-web (and openmrs, etc.).  
- So conceptually we’re doing the same “custom content by volume, proxy in front.”

## What we could adopt from Annoor (optional)

1. **Port 8091**  
   - If we wanted to match their layout, we could use an image that listens on 8091 and keep nginx proxying to `bahmni-web:8091`. Our current setup uses port 80 inside the container; both are valid.

2. **systemdate CGI**  
   - Their landing page uses server date for a timezone warning. We could add a similar CGI (or a small API) and a small script in our landing/home if we want that UX.

3. **Landing page apps from whiteLabel**  
   - Their `index.html` reads `whiteLabel.json` → `landingPage` and renders one card per app (with logo, title, link). We could add a `landingPage` section to our `whiteLabel.json` and a similar block on our home/landing if we want that launcher.

4. **Separate “bahmni-web” image**  
   - They ship a dedicated image (`annoor-docker/bahmni-web:1.0.0`) with only httpd + systemdate; content is always mounted. We use the standard Bahmni image and override with volumes; we could instead build a minimal HealFast httpd image (with optional systemdate) and keep mounting our config the same way.

## Summary

- **Annoor**: Custom Apache image (port 8091, systemdate CGI), content 100% via mounts; no clinic-config container; landing page driven by `whiteLabel.json` and timezone from CGI.  
- **HealFast**: Standard Bahmni stack + override; branding via `CONFIG_VOLUME` and `bahmni_config` mount; same whiteLabel contract; we have the extra step of making **bahmni-config** (clinic-config) work with two dirs (`config` + `config_etc`) because we use that container.

If we ever dropped the clinic-config container and only served our own static config (like Annoor), the “same file” issue would go away; the tradeoff is we’d rely entirely on our own config files and wouldn’t use the clinic-config image’s logic.
