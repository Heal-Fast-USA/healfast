#!/bin/bash
# HealFast USA - Branding Initialization Script
# This script sets up branding configuration on first run

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRANDING_DIR="$SCRIPT_DIR"
CONFIG_DIR="$BRANDING_DIR/config"
LOGO_SOURCE="$SCRIPT_DIR/../logoo.png"

echo "=========================================="
echo "HealFast USA - Branding Initialization"
echo "=========================================="
echo ""

# Check if logo source exists
if [ ! -f "$LOGO_SOURCE" ]; then
    echo "Warning: Logo source file not found at $LOGO_SOURCE"
    echo "Please ensure logoo.png exists in the bahmni-docker root directory"
    read -p "Continue anyway? (y/N): " continue
    if [[ ! "$continue" =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    # Copy logo to branding config
    echo "Copying logo to branding configuration..."
    mkdir -p "$CONFIG_DIR/openmrs/apps/home"
    cp "$LOGO_SOURCE" "$CONFIG_DIR/openmrs/apps/home/logo.png"
    echo "✓ Logo copied to $CONFIG_DIR/openmrs/apps/home/logo.png"
fi

# Verify whiteLabel.json exists
if [ ! -f "$CONFIG_DIR/openmrs/apps/home/whiteLabel.json" ]; then
    echo "Error: whiteLabel.json not found!"
    echo "Expected location: $CONFIG_DIR/openmrs/apps/home/whiteLabel.json"
    exit 1
else
    echo "✓ whiteLabel.json found"
fi

# Verify custom CSS exists
if [ ! -f "$CONFIG_DIR/custom/healfast-custom.css" ]; then
    echo "Error: Custom CSS not found!"
    echo "Expected location: $CONFIG_DIR/custom/healfast-custom.css"
    exit 1
else
    echo "✓ Custom CSS found"
fi

# Create favicon from logo if it doesn't exist
if [ ! -f "$CONFIG_DIR/openmrs/apps/home/favicon.ico" ] && [ -f "$CONFIG_DIR/openmrs/apps/home/logo.png" ]; then
    echo "Creating favicon from logo..."
    cp "$CONFIG_DIR/openmrs/apps/home/logo.png" "$CONFIG_DIR/openmrs/apps/home/favicon.ico"
    echo "✓ Favicon created"
fi

# Verify directory structure
echo ""
echo "Verifying directory structure..."
required_dirs=(
    "$CONFIG_DIR"
    "$CONFIG_DIR/openmrs"
    "$CONFIG_DIR/openmrs/apps"
    "$CONFIG_DIR/openmrs/apps/home"
    "$CONFIG_DIR/custom"
)

for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "Creating directory: $dir"
        mkdir -p "$dir"
    fi
done

echo "✓ Directory structure verified"

# Set proper permissions
echo ""
echo "Setting file permissions..."
find "$CONFIG_DIR" -type f -exec chmod 644 {} \;
find "$CONFIG_DIR" -type d -exec chmod 755 {} \;
echo "✓ Permissions set"

# Summary
echo ""
echo "=========================================="
echo "Branding Initialization Complete!"
echo "=========================================="
echo ""
echo "Configuration directory: $CONFIG_DIR"
echo ""
echo "Files verified:"
ls -lh "$CONFIG_DIR/openmrs/apps/home/" 2>/dev/null || true
ls -lh "$CONFIG_DIR/custom/" 2>/dev/null || true
echo ""
echo "Next steps:"
echo "1. Ensure SSL certificates are in place (run setup-ssl.sh)"
echo "2. Update .env file with CONFIG_VOLUME path"
echo "3. Start Bahmni services: docker compose up -d"
echo ""
