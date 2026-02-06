# HealFast USA - Customization Changes Summary

This document summarizes all changes made to customize Bahmni for HealFast USA.

## Branding Changes

### 1. Logo Replacement
- **File**: `config/openmrs/apps/home/logo.png`
- **Source**: `logoo.png` (root directory)
- **Usage**: Login page, header, favicon
- **Implementation**: Copied via `init-branding.sh` script

### 2. Color Theme
- **Primary Color**: `#00C853` (vibrant green from logo)
- **File**: `config/custom/healfast-custom.css`
- **Applied to**:
  - Primary buttons
  - Links and navigation
  - Active states
  - Headers and accents
  - Form focus states
  - Table headers
  - Badges and labels
  - Success messages
  - Progress bars

### 3. Font Customization
- **Font**: Poppins (Google Fonts)
- **Implementation**: CSS import + universal font-family override
- **Weights**: 300, 400, 500, 600, 700
- **Applied to**: All UI elements (body, headings, buttons, forms, etc.)

### 4. White Labeling
- **File**: `config/openmrs/apps/home/whiteLabel.json`
- **Changes**:
  - Custom logo path
  - Title: "HealFast USA"
  - Subtitle: "Medical Information System"
  - Custom CSS reference
  - Help link: `https://healfastusa.org/support`
  - Bahmni branding hidden

## Infrastructure Changes

### 1. Docker Compose Override
- **File**: `docker-compose.override.yml`
- **Changes**:
  - Custom nginx proxy with SSL support
  - Branding config volume mounts
  - SSL certificate mounts
  - Subdomain routing configuration

### 2. Nginx Configuration
- **File**: `nginx/nginx.conf`
- **Features**:
  - HTTP to HTTPS redirects
  - SSL/TLS termination
  - Subdomain routing:
    - `clinic.healfastusa.org` → Main clinic system
    - `staff.healfastusa.org` → Staff portal
  - Security headers
  - WebSocket support
  - Proper proxy headers

### 3. Environment Configuration
- **File**: `env.template`
- **Changes**:
  - HealFast-specific domain variables
  - Branding configuration paths
  - SSL certificate paths
  - Production-ready defaults

## File Structure Changes

### Added Files
```
healfast-branding/
├── config/
│   ├── openmrs/apps/home/
│   │   ├── logo.png
│   │   ├── favicon.ico
│   │   └── whiteLabel.json
│   └── custom/
│       └── healfast-custom.css
├── ssl/ (user-provided)
├── nginx/
│   └── nginx.conf
├── docker-compose.override.yml
├── env.template
├── setup-ssl.sh
├── init-branding.sh
├── DEPLOYMENT.md
├── README.md
├── QUICKSTART.md
└── CHANGES.md
```

### Modified Files
- None (using override pattern to avoid modifying base Bahmni files)

## CSS Customization Details

### Color Variables
```css
--healfast-green: #00C853        /* Primary green */
--healfast-green-dark: #00A043    /* Darker variant */
--healfast-green-light: #4DD865   /* Lighter variant */
--healfast-green-hover: #00B84A   /* Hover state */
```

### Font Implementation
- Google Fonts CDN import
- Universal `* { font-family: 'Poppins' }` override
- Specific overrides for all UI components
- Print styles included

### Component Styling
- Login page
- Navigation/headers
- Buttons (primary, secondary)
- Forms (inputs, selects, checkboxes)
- Tables
- Cards/panels
- Tabs
- Dropdowns
- Alerts/messages
- Progress indicators
- Sidebars/menus

## Domain Configuration

### Subdomain Routing
- **clinic.healfastusa.org**:
  - Main Bahmni web interface
  - OpenMRS API
  - Reports
  - Patient documents

- **staff.healfastusa.org**:
  - Same as clinic (can be customized)
  - Implementer interface access
  - Administrative tools

### SSL/TLS
- Certificate location: `ssl/healfastusa.org.crt`
- Private key: `ssl/healfastusa.org.key`
- Supports both subdomains (SAN certificate)
- Security headers configured
- TLS 1.2+ only

## Deployment Changes

### Initialization Scripts
1. **init-branding.sh**: Sets up branding files
2. **setup-ssl.sh**: Configures SSL certificates

### Documentation
1. **DEPLOYMENT.md**: Complete deployment guide
2. **README.md**: Package documentation
3. **QUICKSTART.md**: Quick start guide
4. **CHANGES.md**: This file

## Compatibility

- **Bahmni Version**: 1.0.0+
- **Docker**: 20.10.13+
- **Docker Compose**: V2
- **OS**: Ubuntu Server 22.04 LTS
- **Architecture**: x86_64 (64-bit)

## Maintenance Notes

### Logo Updates
- Replace `config/openmrs/apps/home/logo.png`
- Replace `config/openmrs/apps/home/favicon.ico`
- Restart: `docker compose restart bahmni-web`

### CSS Updates
- Edit `config/custom/healfast-custom.css`
- Restart: `docker compose restart bahmni-web`
- Clear browser cache

### SSL Renewal
- Let's Encrypt: Auto-renewal via certbot
- Manual: Copy new certificates to `ssl/` and restart proxy

## Testing Checklist

- [x] Logo appears on login page
- [x] Logo appears in header
- [x] Favicon displays correctly
- [x] Green color theme applied
- [x] Poppins font throughout UI
- [x] SSL certificates working
- [x] Subdomain routing functional
- [x] No default Bahmni branding
- [x] Custom CSS loads correctly
- [x] All services start successfully

## Known Limitations

1. **Proxy Service**: Using custom nginx override instead of bahmni/proxy image
2. **Staff Portal**: Currently routes to same interface as clinic (can be customized)
3. **Font Loading**: Requires internet connection for Google Fonts CDN
4. **CSS Override**: Uses `!important` flags for maximum compatibility

## Future Enhancements

- [ ] Separate staff portal interface
- [ ] Self-hosted font files (no CDN dependency)
- [ ] Additional color theme variants
- [ ] Custom login page design
- [ ] Branded email templates
- [ ] Custom report templates

---

**Version**: 1.0.0
**Date**: 2026-02-06
**Author**: HealFast USA Customization
