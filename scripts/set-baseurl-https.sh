#!/bin/bash
# Set OpenMRS/Bahmni base URL to HTTPS to fix "Mixed Content" (page loaded over HTTPS requested insecure http://...).
# Run once on the server after stack is up. Uses OpenMRS REST API (admin user).
#
# Usage:  BASE_URL=https://staff.healfastusa.org OPENMRS_USER=admin OPENMRS_PASS=yourpass bash scripts/set-baseurl-https.sh
# Or for clinic:  BASE_URL=https://clinic.healfastusa.org ...

set -e

BASE_URL="${BASE_URL:-https://clinic.healfastusa.org}"
OPENMRS_USER="${OPENMRS_USER:-admin}"
OPENMRS_PASS="${OPENMRS_PASS:-}"
OPENMRS_HOST="${OPENMRS_HOST:-https://clinic.healfastusa.org}"

if [ -z "$OPENMRS_PASS" ]; then
  echo "Set OPENMRS_PASS (OpenMRS admin password). Example: OPENMRS_PASS=mypass bash $0"
  exit 1
fi

# Strip trailing slash
BASE_URL="${BASE_URL%/}"
OPENMRS_HOST="${OPENMRS_HOST%/}"

echo "Setting base URL to $BASE_URL (fixes mixed content for initialsetup etc.)"
echo "Using OpenMRS at $OPENMRS_HOST"

# OpenMRS REST: get session, then update global property (BahmRS uses bahmni.baseUrl or similar)
# Try common property names
for PROP in "bahmni.baseUrl" "referenceapplication.redirectUri" "webservices.rest.uriPrefix"; do
  RESP=$(curl -s -k -w "\n%{http_code}" -u "$OPENMRS_USER:$OPENMRS_PASS" \
    "$OPENMRS_HOST/openmrs/ws/rest/v1/systemsetting/$PROP" 2>/dev/null || true)
  CODE=$(echo "$RESP" | tail -1)
  if [ "$CODE" = "200" ]; then
    echo "Updating $PROP to $BASE_URL"
    curl -s -k -X POST -u "$OPENMRS_USER:$OPENMRS_PASS" \
      -H "Content-Type: application/json" \
      "$OPENMRS_HOST/openmrs/ws/rest/v1/systemsetting" \
      -d "{\"property\":\"$PROP\",\"value\":\"$BASE_URL\"}" 2>/dev/null || true
  fi
done

# Legacy: some Bahmni use Admin UI to set this. Also try direct global property if module uses different API.
curl -s -k -X POST -u "$OPENMRS_USER:$OPENMRS_PASS" \
  -H "Content-Type: application/json" \
  "$OPENMRS_HOST/openmrs/ws/rest/v1/systemsetting" \
  -d "{\"property\":\"bahmni.baseUrl\",\"value\":\"$BASE_URL\"}" 2>/dev/null || echo "(If 404, set manually: OpenMRS Admin → Advanced Settings → Global Property → bahmni.baseUrl = $BASE_URL)"

echo ""
echo "Done. If mixed content persists, set manually in OpenMRS:"
echo "  Admin → Advanced Settings → Global Property → bahmni.baseUrl = $BASE_URL"
echo "  (Use https:// for clinic.healfastusa.org or https://staff.healfastusa.org)"
