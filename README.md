# HealFast USA - Bahmni Branding Package

This package contains all necessary files and configurations to fully brand Bahmni for HealFast USA deployment.

## Contents

```
healfast-branding/
├── config/                          # Branding configuration files
│   ├── openmrs/
│   │   └── apps/
│   │       └── home/
│   │           ├── logo.png         # HealFast logo
│   │           ├── favicon.ico       # Favicon
│   │           └── whiteLabel.json  # White labeling configuration
│   └── custom/
│       └── healfast-custom.css     # Custom CSS with Poppins font and green theme
├── ssl/                             # SSL certificates directory (create and add certificates)
├── nginx/
│   └── nginx.conf                   # Nginx configuration for subdomain routing
├── docker-compose.override.yml      # Docker Compose override for branding
├── env.template                     # Environment variables template
├── setup-ssl.sh                     # SSL certificate setup script
├── init-branding.sh                 # Branding initialization script
├── DEPLOYMENT.md                    # Full deployment guide
└── README.md                        # This file
```

## Quick Start

### 1. Initialize Branding

```bash
cd healfast-branding
chmod +x init-branding.sh
./init-branding.sh
```

### 2. Set Up SSL Certificates

```bash
chmod +x setup-ssl.sh
./setup-ssl.sh
```

Choose one of:
- **Option 1**: Let's Encrypt (recommended for production)
- **Option 2**: Use existing certificates
- **Option 3**: Self-signed (testing only)

### 3. Configure Environment

```bash
# Copy template to your bahmni-lite or bahmni-standard directory
cp env.template ../bahmni-lite/.env
# or
cp env.template ../bahmni-standard/.env

# Edit .env file
vim ../bahmni-lite/.env
```

**Important**: Update these values:
- `CONFIG_VOLUME` - Path to branding config (use absolute path)
- `OPENMRS_DB_PASSWORD` - Strong password
- `MYSQL_ROOT_PASSWORD` - Strong password
- All other passwords

### 4. Apply Docker Compose Override

**Option A: Use override file (Recommended)**

```bash
cd ../bahmni-lite  # or bahmni-standard
cp ../healfast-branding/docker-compose.override.yml .
docker compose -f docker-compose.yml -f docker-compose.override.yml --env-file .env up -d
```

**Option B: Manual integration**

Edit `docker-compose.yml` and add volumes for:
- `bahmni-config` service: mount branding config
- `bahmni-web` service: mount branding config
- `proxy` service: mount SSL certificates and nginx config (or use custom nginx)

### 5. Start Services

```bash
./run-bahmni.sh
# Select option 1: START Bahmni services
```

Or:

```bash
docker compose --env-file .env up -d
```

## Branding Features

### Logo
- **Location**: `config/openmrs/apps/home/logo.png`
- **Usage**: Login page, header, favicon
- **Format**: PNG (recommended: 200x200px or larger)

### Color Theme
- **Primary Green**: `#00C853` (vibrant green from logo)
- **Applied to**: Buttons, links, headers, active states, accents
- **CSS File**: `config/custom/healfast-custom.css`

### Font
- **Font Family**: Poppins (Google Fonts)
- **Applied to**: Entire UI (all text elements)
- **Weights**: 300, 400, 500, 600, 700

### White Labeling
- **Configuration**: `config/openmrs/apps/home/whiteLabel.json`
- **Features**:
  - Custom logo path
  - Custom title: "HealFast USA"
  - Custom subtitle: "Medical Information System"
  - Custom CSS integration
  - Help link customization

## Domain Configuration

### Subdomains

**clinic.healfastusa.org** and **staff.healfastusa.org** (IP 69.30.247.92)
- Routes to: bahmni-web, openmrs, reports, implementer-interface
- Access: https://clinic.healfastusa.org and https://staff.healfastusa.org

### SSL/TLS

- Certificates stored in: `ssl/`
- Required files:
  - `healfastusa.org.crt` (certificate)
  - `healfastusa.org.key` (private key)
- Supports both subdomains (SAN certificate)

### Nginx Configuration

The `nginx/nginx.conf` file provides:
- HTTP to HTTPS redirects
- SSL/TLS termination
- Subdomain routing
- Security headers
- WebSocket support
- Proper proxy headers

## File Structure Details

### Branding Config (`config/`)

```
config/
├── openmrs/
│   └── apps/
│       └── home/
│           ├── logo.png              # Main logo (copied from logoo.png)
│           ├── favicon.ico           # Browser favicon
│           └── whiteLabel.json       # White labeling config
└── custom/
    └── healfast-custom.css          # Custom CSS with Poppins and green theme
```

### SSL Certificates (`ssl/`)

```
ssl/
├── healfastusa.org.crt              # SSL certificate
└── healfastusa.org.key              # Private key
```

**Note**: These files are not included in the repository for security. You must add them using `setup-ssl.sh` or manually.

## Customization

### Changing Colors

Edit `config/custom/healfast-custom.css` and update CSS variables:

```css
:root {
  --healfast-green: #00C853;        /* Primary green */
  --healfast-green-dark: #00A043;    /* Darker green */
  --healfast-green-light: #4DD865;   /* Lighter green */
  --healfast-green-hover: #00B84A;   /* Hover state */
}
```

### Changing Logo

1. Replace `config/openmrs/apps/home/logo.png` with your logo
2. Update `config/openmrs/apps/home/favicon.ico` if needed
3. Restart bahmni-web service: `docker compose restart bahmni-web`

### Modifying White Label Config

Edit `config/openmrs/apps/home/whiteLabel.json`:

```json
{
  "logo": "/bahmni_config/openmrs/apps/home/logo.png",
  "title": "HealFast USA",
  "subTitle": "Medical Information System",
  "customCSS": "/bahmni_config/custom/healfast-custom.css"
}
```

## Verification Checklist

After deployment, verify:

- [ ] Logo appears on login page
- [ ] Logo appears in header/navigation
- [ ] Favicon shows in browser tab
- [ ] Green color theme applied (buttons, links, etc.)
- [ ] Poppins font applied throughout UI
- [ ] `https://clinic.healfastusa.org` loads correctly
- [ ] SSL certificates valid (no browser warnings)
- [ ] Custom CSS loads (check browser dev tools)
- [ ] No default Bahmni branding visible

## Troubleshooting

### Logo Not Showing

```bash
# Check if logo file exists
docker compose exec bahmni-web ls -la /usr/local/apache2/htdocs/bahmni_config/openmrs/apps/home/

# Verify config volume is mounted
docker compose exec bahmni-web ls -la /usr/local/apache2/htdocs/bahmni_config/

# Restart service
docker compose restart bahmni-web
```

### CSS Not Loading

```bash
# Check if CSS file exists
docker compose exec bahmni-web ls -la /usr/local/apache2/htdocs/bahmni_config/custom/

# Verify whiteLabel.json references CSS correctly
docker compose exec bahmni-web cat /usr/local/apache2/htdocs/bahmni_config/openmrs/apps/home/whiteLabel.json

# Check browser console for 404 errors
```

### SSL Certificate Issues

```bash
# Verify certificates exist
ls -lh ssl/

# Check certificate validity
openssl x509 -in ssl/healfastusa.org.crt -text -noout

# Test SSL connection
openssl s_client -connect clinic.healfastusa.org:443
```

### Subdomain Not Routing

```bash
# Check nginx configuration
docker compose exec proxy nginx -t

# Check nginx logs
docker compose logs proxy

# Verify DNS resolution
curl -I https://clinic.healfastusa.org
```

## Maintenance

### Updating Logo

1. Replace `config/openmrs/apps/home/logo.png`
2. Replace `config/openmrs/apps/home/favicon.ico`
3. Restart: `docker compose restart bahmni-web`

### Updating CSS

1. Edit `config/custom/healfast-custom.css`
2. Restart: `docker compose restart bahmni-web`
3. Clear browser cache

### Renewing SSL Certificates

For Let's Encrypt:

```bash
sudo certbot renew
# If using Let's Encrypt (domain required): copy fullchain.pem → ssl/healfastusa.org.crt, privkey.pem → ssl/healfastusa.org.key
docker compose restart proxy
```

## Support

For deployment assistance:
- Review `DEPLOYMENT.md` for detailed instructions
- Check Bahmni documentation: https://bahmni.atlassian.net/
- Contact: see project support

## License

This branding package is for HealFast USA use. Bahmni is open-source software.

---

**Version**: 1.0.0
**Last Updated**: 2026-02-06
**Compatible with**: Bahmni Docker 1.0.0+
