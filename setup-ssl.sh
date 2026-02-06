#!/bin/bash
# HealFast USA - SSL Certificate Setup Script
# This script helps set up SSL certificates for HealFast USA domains

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSL_DIR="$SCRIPT_DIR/ssl"

echo "=========================================="
echo "HealFast USA - SSL Certificate Setup"
echo "=========================================="
echo ""

# Create SSL directory if it doesn't exist
mkdir -p "$SSL_DIR"

# Check if certificates already exist
if [ -f "$SSL_DIR/healfastusa.org.crt" ] && [ -f "$SSL_DIR/healfastusa.org.key" ]; then
    echo "✓ SSL certificates already exist in $SSL_DIR"
    echo ""
    echo "Current certificates:"
    ls -lh "$SSL_DIR"/*.crt "$SSL_DIR"/*.key 2>/dev/null || true
    echo ""
    read -p "Do you want to replace them? (y/N): " replace
    if [[ ! "$replace" =~ ^[Yy]$ ]]; then
        echo "Keeping existing certificates."
        exit 0
    fi
fi

echo "SSL Certificate Setup Options:"
echo "1) Use Let's Encrypt (Certbot) - Recommended for production"
echo "2) Use existing certificates (copy to $SSL_DIR)"
echo "3) Generate self-signed certificates (for testing only)"
echo ""
read -p "Select option (1-3): " option

case $option in
    1)
        echo ""
        echo "Setting up Let's Encrypt certificates..."
        echo ""
        echo "Prerequisites:"
        echo "- Domain DNS must point to this server"
        echo "- Ports 80 and 443 must be open"
        echo "- Certbot must be installed: sudo apt-get install certbot"
        echo ""
        read -p "Continue with Let's Encrypt setup? (y/N): " continue
        
        if [[ "$continue" =~ ^[Yy]$ ]]; then
            # Check if certbot is installed
            if ! command -v certbot &> /dev/null; then
                echo "Error: certbot is not installed."
                echo "Install it with: sudo apt-get update && sudo apt-get install -y certbot"
                exit 1
            fi
            
            echo ""
            echo "Obtaining certificates for clinic.healfastusa.org and staff.healfastusa.org..."
            echo "Note: You may need to temporarily stop nginx/proxy service"
            echo ""
            
            # Obtain certificates
            sudo certbot certonly --standalone \
                -d clinic.healfastusa.org \
                -d staff.healfastusa.org \
                --email admin@healfastusa.org \
                --agree-tos \
                --non-interactive || {
                echo ""
                echo "Certbot failed. You may need to:"
                echo "1. Ensure DNS is pointing to this server"
                echo "2. Stop nginx/proxy service: sudo systemctl stop nginx"
                echo "3. Run certbot manually: sudo certbot certonly --standalone -d clinic.healfastusa.org -d staff.healfastusa.org"
                exit 1
            }
            
            # Copy certificates to SSL directory
            CERT_PATH="/etc/letsencrypt/live/clinic.healfastusa.org"
            if [ -d "$CERT_PATH" ]; then
                sudo cp "$CERT_PATH/fullchain.pem" "$SSL_DIR/healfastusa.org.crt"
                sudo cp "$CERT_PATH/privkey.pem" "$SSL_DIR/healfastusa.org.key"
                sudo chown $USER:$USER "$SSL_DIR"/*.crt "$SSL_DIR"/*.key
                sudo chmod 644 "$SSL_DIR/healfastusa.org.crt"
                sudo chmod 600 "$SSL_DIR/healfastusa.org.key"
                echo ""
                echo "✓ Certificates copied to $SSL_DIR"
                echo ""
                echo "Note: Let's Encrypt certificates expire in 90 days."
                echo "Set up auto-renewal with: sudo certbot renew --dry-run"
            else
                echo "Error: Could not find certificates at $CERT_PATH"
                exit 1
            fi
        fi
        ;;
    2)
        echo ""
        echo "Please provide the paths to your existing certificates:"
        read -p "Certificate file (.crt or .pem): " cert_file
        read -p "Private key file (.key): " key_file
        
        if [ ! -f "$cert_file" ] || [ ! -f "$key_file" ]; then
            echo "Error: One or both certificate files not found."
            exit 1
        fi
        
        cp "$cert_file" "$SSL_DIR/healfastusa.org.crt"
        cp "$key_file" "$SSL_DIR/healfastusa.org.key"
        chmod 644 "$SSL_DIR/healfastusa.org.crt"
        chmod 600 "$SSL_DIR/healfastusa.org.key"
        
        echo "✓ Certificates copied to $SSL_DIR"
        ;;
    3)
        echo ""
        echo "Generating self-signed certificates (for testing only)..."
        echo "WARNING: Self-signed certificates will show security warnings in browsers!"
        echo ""
        
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$SSL_DIR/healfastusa.org.key" \
            -out "$SSL_DIR/healfastusa.org.crt" \
            -subj "/C=US/ST=State/L=City/O=HealFast USA/CN=clinic.healfastusa.org" \
            -addext "subjectAltName=DNS:clinic.healfastusa.org,DNS:staff.healfastusa.org"
        
        chmod 644 "$SSL_DIR/healfastusa.org.crt"
        chmod 600 "$SSL_DIR/healfastusa.org.key"
        
        echo "✓ Self-signed certificates generated in $SSL_DIR"
        echo ""
        echo "WARNING: These are self-signed certificates for testing only!"
        echo "For production, use Let's Encrypt (option 1) or trusted certificates (option 2)."
        ;;
    *)
        echo "Invalid option selected."
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "SSL Setup Complete!"
echo "=========================================="
echo ""
echo "Certificate files:"
ls -lh "$SSL_DIR"/*.crt "$SSL_DIR"/*.key
echo ""
echo "Next steps:"
echo "1. Verify certificates are in place: ls -lh $SSL_DIR"
echo "2. Update docker-compose.yml to use these certificates"
echo "3. Restart the proxy service: docker compose restart proxy"
echo ""
