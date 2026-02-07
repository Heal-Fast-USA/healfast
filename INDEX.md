# HealFast USA - Bahmni Customization Package Index

## 📋 Documentation Files

| File | Purpose | When to Use |
|-----|---------|-------------|
| **SUMMARY.md** | Complete overview of the package | Start here for overview |
| **QUICKSTART.md** | 5-minute quick start guide | Fast deployment |
| **DEPLOYMENT.md** | Complete deployment guide | Full step-by-step instructions |
| **README.md** | Package documentation | Reference and customization |
| **CHANGES.md** | Detailed changes summary | Understanding what was changed |
| **INDEX.md** | This file - navigation guide | Finding the right document |

## 🚀 Quick Navigation

### For First-Time Deployment
1. Read: **SUMMARY.md** (overview)
2. Follow: **QUICKSTART.md** (fast setup)
3. Reference: **DEPLOYMENT.md** (detailed steps)

### For Customization
1. Read: **README.md** (customization guide)
2. Review: **CHANGES.md** (what changed)
3. Edit: Files in `config/` directory

### For Troubleshooting
1. Check: **DEPLOYMENT.md** (troubleshooting section)
2. Review: **README.md** (common issues)
3. Verify: File structure matches documentation

## 📁 Directory Structure

```
healfast-branding/
│
├── 📄 Documentation
│   ├── INDEX.md              ← You are here
│   ├── SUMMARY.md            ← Start here
│   ├── QUICKSTART.md         ← Fast setup
│   ├── DEPLOYMENT.md         ← Full guide
│   ├── README.md             ← Reference
│   └── CHANGES.md            ← Changes log
│
├── ⚙️ Configuration
│   ├── config/
│   │   ├── openmrs/apps/home/
│   │   │   ├── logo.png      ← HealFast logo
│   │   │   ├── favicon.ico   ← Browser icon
│   │   │   └── whiteLabel.json ← Branding config
│   │   └── custom/
│   │       └── healfast-custom.css ← Custom CSS
│   │
│   ├── nginx/
│   │   └── nginx.conf        ← clinic + staff.healfastusa.org (69.30.247.92)
│   │
│   ├── docker-compose.override.yml ← Docker config
│   └── env.template          ← Environment variables
│
├── 🔒 SSL (user-provided)
│   └── ssl/
│       ├── healfastusa.org.crt
│       └── healfastusa.org.key
│
└── 🛠️ Scripts
    ├── init-branding.sh       ← Initialize branding
    └── setup-ssl.sh           ← SSL setup
```

## 🎯 Use Cases

### Use Case 1: Fresh Deployment
**Goal**: Deploy Bahmni with HealFast branding from scratch

**Steps**:
1. Read **SUMMARY.md**
2. Follow **QUICKSTART.md** or **DEPLOYMENT.md**
3. Run `init-branding.sh`
4. Run `setup-ssl.sh`
5. Configure `.env` file
6. Start services

**Files Needed**:
- All files in `healfast-branding/`
- SSL certificates (via `setup-ssl.sh`)

### Use Case 2: Update Branding
**Goal**: Change logo, colors, or fonts

**Steps**:
1. Read **README.md** (Customization section)
2. Replace files in `config/`
3. Edit `config/custom/healfast-custom.css` if needed
4. Restart services

**Files to Modify**:
- `config/openmrs/apps/home/logo.png`
- `config/openmrs/apps/home/favicon.ico`
- `config/custom/healfast-custom.css`
- `config/openmrs/apps/home/whiteLabel.json`

### Use Case 3: Troubleshooting
**Goal**: Fix deployment or branding issues

**Steps**:
1. Check **DEPLOYMENT.md** (Troubleshooting section)
2. Review **README.md** (Common Issues)
3. Check service logs
4. Verify file structure

**Common Issues**:
- Logo not showing → Check file paths
- CSS not loading → Verify whiteLabel.json
- SSL errors → Check certificate files
- Subdomain not working → Verify DNS and nginx config

### Use Case 4: SSL Certificate Renewal
**Goal**: Update SSL certificates

**Steps**:
1. Run `setup-ssl.sh` (option 1 for Let's Encrypt)
2. Or manually copy certificates to `ssl/`
3. Restart proxy service

**Files**:
- `ssl/healfastusa.org.crt`
- `ssl/healfastusa.org.key`

## 📚 Documentation Details

### SUMMARY.md
- Complete package overview
- What's included
- Quick deployment steps
- Validation checklist
- Maintenance guide

### QUICKSTART.md
- 5-minute setup guide
- Prerequisites checklist
- Step-by-step commands
- Common issues

### DEPLOYMENT.md
- Complete deployment guide
- Prerequisites and setup
- DNS configuration
- SSL certificate setup
- Docker installation
- Service deployment
- Troubleshooting
- Maintenance procedures

### README.md
- Package documentation
- File structure details
- Branding features
- Domain configuration
- Customization guide
- Verification checklist
- Troubleshooting

### CHANGES.md
- Detailed changes summary
- Branding changes
- Infrastructure changes
- File structure changes
- CSS customization details
- Compatibility information

## 🔍 Finding Information

### "How do I deploy this?"
→ **QUICKSTART.md** or **DEPLOYMENT.md**

### "How do I change the logo?"
→ **README.md** (Customization section)

### "How do I change colors?"
→ **README.md** (Customization section) or **CHANGES.md**

### "SSL certificate setup?"
→ **DEPLOYMENT.md** (SSL Certificate Setup) or run `setup-ssl.sh`

### "Troubleshooting issues?"
→ **DEPLOYMENT.md** (Troubleshooting section)

### "What files were changed?"
→ **CHANGES.md**

### "How does subdomain routing work?"
→ **README.md** (Domain Configuration) or `nginx/nginx.conf`

### "Environment variables?"
→ **env.template** or **DEPLOYMENT.md**

## ✅ Pre-Deployment Checklist

Before starting deployment:

- [ ] Read **SUMMARY.md** for overview
- [ ] Review **QUICKSTART.md** or **DEPLOYMENT.md**
- [ ] Verify Ubuntu Server 22.04 LTS
- [ ] Ensure Docker is installed (or will be)
- [ ] DNS configured for subdomains
- [ ] Ports 80, 443, 22 open
- [ ] Have SSL certificates ready (or use Let's Encrypt)
- [ ] Understand file structure

## 🎓 Learning Path

### Beginner
1. **SUMMARY.md** → Understand what this package does
2. **QUICKSTART.md** → Follow quick setup
3. **README.md** → Learn about customization

### Intermediate
1. **DEPLOYMENT.md** → Full deployment process
2. **CHANGES.md** → Understand all changes
3. **README.md** → Customization options

### Advanced
1. **nginx/nginx.conf** → Subdomain routing
2. **docker-compose.override.yml** → Docker configuration
3. **config/custom/healfast-custom.css** → CSS customization
4. **CHANGES.md** → Technical details

## 📞 Support Resources

- **Documentation**: All `.md` files in this directory
- **Bahmni Wiki**: https://bahmni.atlassian.net/
- **Scripts**: `init-branding.sh`, `setup-ssl.sh`
- **Configuration**: Files in `config/` directory

## 🔄 Update History

- **v1.0.0** (2026-02-06): Initial release
  - Complete branding package
  - SSL configuration
  - Subdomain routing
  - Full documentation

---

**Start Here**: [SUMMARY.md](SUMMARY.md)

**Quick Setup**: [QUICKSTART.md](QUICKSTART.md)

**Full Guide**: [DEPLOYMENT.md](DEPLOYMENT.md)
