# HealFast USA - Bahmni Customization Summary

## Overview

This package provides a complete end-to-end customization solution for deploying Bahmni with HealFast USA branding on Ubuntu Server 22.04 LTS using Docker.

## What's Included

### ✅ Branding Assets
- **Logo**: HealFast logo (`logoo.png`) integrated into system
- **Favicon**: Browser favicon updated
- **Color Theme**: Vibrant green (#00C853) applied throughout UI
- **Font**: Poppins Google Font integrated across entire application
- **White Labeling**: Complete removal of default Bahmni branding

### ✅ Infrastructure Configuration
- **Nginx Configuration**: Subdomains **clinic.healfastusa.org** and **staff.healfastusa.org** (IP 69.30.247.92)
- **SSL/TLS Support**: Certificate management and HTTPS configuration
- **Docker Compose Override**: Seamless integration without modifying base files
- **Environment Templates**: Pre-configured environment variables

### ✅ Deployment Tools
- **Initialization Script**: Automated branding setup
- **SSL Setup Script**: Certificate installation (Let's Encrypt, existing, or self-signed)
- **Deployment Documentation**: Complete step-by-step guide
- **Quick Start Guide**: 5-minute setup instructions

## File Structure

```
healfast-branding/
├── config/                          # Branding configuration
│   ├── openmrs/apps/home/
│   │   ├── logo.png                # HealFast logo
│   │   ├── favicon.ico            # Browser favicon
│   │   └── whiteLabel.json        # White labeling config
│   └── custom/
│       └── healfast-custom.css    # Custom CSS (Poppins + green theme)
├── ssl/                            # SSL certificates (user-provided)
├── nginx/
│   └── nginx.conf                  # Subdomain routing configuration
├── docker-compose.override.yml    # Docker override for branding
├── env.template                    # Environment variables template
├── setup-ssl.sh                    # SSL certificate setup
├── init-branding.sh                # Branding initialization
├── DEPLOYMENT.md                   # Full deployment guide
├── README.md                       # Package documentation
├── QUICKSTART.md                   # Quick start guide
├── CHANGES.md                      # Changes summary
└── SUMMARY.md                      # This file
```

## Quick Deployment Steps

1. **Initialize Branding**
   ```bash
   cd healfast-branding
   ./init-branding.sh
   ```

2. **Set Up SSL**
   ```bash
   ./setup-ssl.sh
   ```

3. **Configure Environment**
   ```bash
   cd ../bahmni-lite  # or bahmni-standard
   cp ../healfast-branding/env.template .env
   vim .env  # Update passwords and paths
   ```

4. **Start Services**
   ```bash
   cp ../healfast-branding/docker-compose.override.yml .
   docker compose -f docker-compose.yml -f docker-compose.override.yml --env-file .env up -d
   ```

5. **Verify**
   - Open: `https://clinic.healfastusa.org` and `https://staff.healfastusa.org`
   - Check: Logo, green theme, Poppins font

## Key Features

### Branding
- ✅ HealFast logo on login page and throughout UI
- ✅ Green color theme (#00C853) as primary accent
- ✅ Poppins font applied to all UI elements
- ✅ Custom CSS for comprehensive styling
- ✅ White labeling configuration

### Domain Configuration
- ✅ **clinic.healfastusa.org** and **staff.healfastusa.org** (HTTPS)
- ✅ SSL/TLS encryption for both subdomains
- ✅ HTTP to HTTPS redirects

### Infrastructure
- ✅ Docker Compose integration
- ✅ Nginx reverse proxy with subdomain routing
- ✅ SSL certificate management
- ✅ Automated initialization scripts

## Requirements

- **OS**: Ubuntu Server 22.04 LTS (64-bit)
- **Docker**: 20.10.13+
- **Docker Compose**: V2
- **Server IP**: 69.30.247.92; DNS: clinic.healfastusa.org and staff.healfastusa.org → this IP
- **Resources**: 4 CPU cores, 8 GB RAM, 100 GB disk

## Documentation

- **DEPLOYMENT.md**: Complete deployment guide with troubleshooting
- **README.md**: Package documentation and customization guide
- **QUICKSTART.md**: 5-minute quick start guide
- **CHANGES.md**: Detailed list of all changes made

## Support

For deployment assistance:
- Review documentation files
- Check Bahmni wiki: https://bahmni.atlassian.net/
- Contact: see README

## Validation Checklist

After deployment, verify:

- [ ] Logo appears on login page
- [ ] Logo appears in header/navigation
- [ ] Favicon displays in browser tab
- [ ] Green color theme applied (buttons, links, etc.)
- [ ] Poppins font visible throughout UI
- [ ] `https://clinic.healfastusa.org` loads correctly
- [ ] SSL certificates valid (no browser warnings)
- [ ] Custom CSS loads (check browser dev tools)
- [ ] No default Bahmni branding visible
- [ ] All services running: `docker compose ps`

## Customization Points

### Logo
- **File**: `config/openmrs/apps/home/logo.png`
- **Update**: Replace file and restart `bahmni-web` service

### Colors
- **File**: `config/custom/healfast-custom.css`
- **Variables**: `--healfast-green`, `--healfast-green-dark`, etc.
- **Update**: Edit CSS variables and restart service

### Font
- **Implementation**: Google Fonts CDN in CSS
- **Update**: Modify `@import` statement in CSS file

### White Labeling
- **File**: `config/openmrs/apps/home/whiteLabel.json`
- **Update**: Edit JSON file and restart service

## Maintenance

### Updating Logo
```bash
# Replace logo file
cp new-logo.png healfast-branding/config/openmrs/apps/home/logo.png
# Restart service
docker compose restart bahmni-web
```

### Updating CSS
```bash
# Edit CSS file
vim healfast-branding/config/custom/healfast-custom.css
# Restart service
docker compose restart bahmni-web
```

### Renewing SSL (Let's Encrypt)
```bash
sudo certbot renew
# If using Let's Encrypt: copy your domain's fullchain.pem and privkey.pem to healfast-branding/ssl/ as healfastusa.org.crt and .key
docker compose restart proxy
```

## Troubleshooting

### Logo Not Showing
```bash
docker compose exec bahmni-web ls -la /usr/local/apache2/htdocs/bahmni_config/openmrs/apps/home/
docker compose restart bahmni-web
```

### CSS Not Loading
```bash
docker compose exec bahmni-web ls -la /usr/local/apache2/htdocs/bahmni_config/custom/
docker compose logs bahmni-web
```

### SSL Issues
```bash
ls -lh healfast-branding/ssl/
openssl x509 -in healfast-branding/ssl/healfastusa.org.crt -text -noout
docker compose logs proxy
```

### Site not loading
```bash
curl -I https://clinic.healfastusa.org
docker compose exec proxy nginx -t
docker compose logs proxy
```

## Next Steps After Deployment

1. Access OpenMRS admin: `https://clinic.healfastusa.org/openmrs`
2. Create users and configure roles
3. Set up clinic locations and departments
4. Configure clinical forms and templates
5. Set up reporting dashboards
6. Configure email notifications (if needed)
7. Set up automated backups
8. Configure monitoring and alerts

## Version Information

- **Package Version**: 1.0.0
- **Bahmni Version**: 1.0.0+
- **Created**: 2026-02-06
- **Compatible with**: Bahmni Docker 1.0.0+

---

**Ready for Production Deployment** ✅

All files are in place and ready for deployment. Follow the DEPLOYMENT.md guide for step-by-step instructions.
