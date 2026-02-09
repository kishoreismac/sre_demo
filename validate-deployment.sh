#!/bin/bash
# Deployment validation script for Azure App Service
# Usage: ./validate-deployment.sh <slot-url>
#
# This script validates that a deployment slot is safe to swap to production
# by checking the /health endpoint and ensuring INJECT_ERROR is not enabled.

set -e

SLOT_URL="$1"

if [ -z "$SLOT_URL" ]; then
    echo "Usage: $0 <slot-url>"
    echo "Example: $0 https://my-app-staging.azurewebsites.net"
    exit 1
fi

echo "======================================"
echo "Deployment Validation Script"
echo "======================================"
echo "Target URL: $SLOT_URL"
echo ""

# Remove trailing slash if present
SLOT_URL="${SLOT_URL%/}"

# Check if health endpoint is accessible
echo "[1/3] Checking health endpoint..."
HEALTH_URL="${SLOT_URL}/health"

HTTP_STATUS=$(curl -s -o /tmp/health-response.json -w "%{http_code}" "$HEALTH_URL")

if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "❌ VALIDATION FAILED: Health check returned HTTP $HTTP_STATUS"
    echo ""
    echo "Response:"
    cat /tmp/health-response.json
    echo ""
    echo ""
    echo "⚠️  DO NOT PROCEED WITH DEPLOYMENT"
    echo "Fix the configuration issues before swapping to production."
    exit 1
fi

echo "✅ Health endpoint is accessible (HTTP $HTTP_STATUS)"

# Check health status
echo "[2/3] Validating health status..."

STATUS=$(cat /tmp/health-response.json | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

if [ "$STATUS" != "healthy" ]; then
    echo "❌ VALIDATION FAILED: Health status is '$STATUS'"
    echo ""
    echo "Response:"
    cat /tmp/health-response.json
    echo ""
    echo ""
    echo "⚠️  DO NOT PROCEED WITH DEPLOYMENT"
    echo "Common cause: INJECT_ERROR is enabled on this slot."
    echo "Disable INJECT_ERROR and restart the slot before proceeding."
    exit 1
fi

echo "✅ Health status is healthy"

# Check main page is accessible
echo "[3/3] Checking main application endpoint..."

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$SLOT_URL/")

if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "❌ VALIDATION FAILED: Main page returned HTTP $HTTP_STATUS"
    echo "⚠️  DO NOT PROCEED WITH DEPLOYMENT"
    exit 1
fi

echo "✅ Main application endpoint is accessible (HTTP $HTTP_STATUS)"

# Clean up
rm -f /tmp/health-response.json

echo ""
echo "======================================"
echo "✅ ALL VALIDATIONS PASSED"
echo "======================================"
echo ""
echo "This slot is safe to swap to production."
echo ""
echo "Next steps:"
echo "1. Review metrics (Http5xx should be 0)"
echo "2. Proceed with slot swap"
echo "3. Monitor production metrics for 10-15 minutes after swap"
echo "4. Be ready to rollback if issues are detected"
echo ""

exit 0
