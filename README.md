
This sample .NET app demonstrates Azure App Service deployment slots, error simulation, and integration with the Azure SRE (Site Reliability Engineering) Agent for AI-assisted troubleshooting.

## ⚠️ PRODUCTION SAFETY GUIDELINES

**CRITICAL: Never enable INJECT_ERROR in Production!**

1. **Always mark INJECT_ERROR as a slot setting** in Azure App Service to prevent it from swapping to production
2. **Validate configuration before slot swap**: Ensure INJECT_ERROR=0 (or unset) in production
3. **Use the /health endpoint** to validate configuration before completing deployments
4. **The app will refuse to start** if INJECT_ERROR=1 is detected in Production environment

### Deployment Checklist for Azure App Service Slots

Before swapping a slot to production:
- [ ] Verify INJECT_ERROR is unset or set to "0" on production slot
- [ ] Mark INJECT_ERROR as a slot-specific setting (sticky to slot)
- [ ] Check /health endpoint returns 200 status on staging slot
- [ ] Monitor Http5xx metrics for at least 5 minutes after swap
- [ ] Have rollback plan ready (swap back to previous slot)

## Overview

- **Simulates HTTP 500 errors** in a controlled way, using the `INJECT_ERROR` app setting.
- **Tracks button clicks** and throws an error after several clicks when error injection is enabled.
- **Works with Azure App Service deployment slots**, making it easy to test failures without affecting production.

## How it Works

- **Normal Mode:** The main page shows a counter and two buttons: **Refresh** and **Reset Counter**.
- **Error Simulation:** If you set the `INJECT_ERROR` app setting to `1`, clicking "Refresh" 6 times will trigger an HTTP 500 error.
- **Slots:** Run in parallel (e.g., staging vs. production) to test error scenarios safely.
- **Health Check:** The `/health` endpoint returns HTTP 200 when INJECT_ERROR is disabled, HTTP 503 when enabled.

## Configuration

### Environment Variables / App Settings

| Setting | Values | Description | Production Safe? |
|---------|--------|-------------|------------------|
| INJECT_ERROR | 0 or unset | Normal operation (default) | ✅ YES |
| INJECT_ERROR | 1 | Enables error simulation | ❌ NO - Only for testing slots |
| ASPNETCORE_ENVIRONMENT | Production | Production mode with safety checks | ✅ YES |
| ASPNETCORE_ENVIRONMENT | Development, Staging | Development/testing mode | ✅ YES |

### Azure App Service Slot Settings Configuration

To prevent INJECT_ERROR from accidentally moving to production during slot swaps:

1. In Azure Portal, go to your App Service → Configuration → Application settings
2. Add or edit the `INJECT_ERROR` setting
3. **Check the "deployment slot setting" checkbox** to make it sticky to the slot
4. Set INJECT_ERROR=1 only on test/staging slots, never on production
5. Production slot should have INJECT_ERROR=0 or unset

## Files

| File                          | Description                            |
|-------------------------------|----------------------------------------|
| Program.cs                    | Main app logic and web server setup    |
| appsettings.json              | App configuration (default)            |
| appsettings.Development.json  | Development environment config         |
| SreAgentMemoryDemo.csproj     | Project file                           |
| SreAgentMemoryDemo.http       | HTTP request samples                   |
| DEPLOYMENT_GUIDE.md           | Azure App Service deployment procedures |
| validate-deployment.sh        | Automated deployment validation script |
| LICENSE                       | License for this sample                |
| README.md                     | Project documentation (this file)      |

## API Endpoints

### `GET /`
Main application page with counter and error simulation controls.

### `GET /health`
Health check endpoint for deployment validation.

**Response when healthy:**
```json
{
  "status": "healthy",
  "environment": "Production",
  "timestamp": "2026-02-09T20:00:00Z"
}
```
**HTTP Status:** 200

**Response when unhealthy (INJECT_ERROR enabled):**
```json
{
  "status": "unhealthy",
  "reason": "INJECT_ERROR is enabled",
  "environment": "Development",
  "timestamp": "2026-02-09T20:00:00Z"
}
```
**HTTP Status:** 503

## Quick Reference

### For Developers
```bash
# Build the application
dotnet build

# Run locally (normal mode)
dotnet run

# Run with error injection enabled (Development only)
INJECT_ERROR=1 dotnet run

# Check health endpoint
curl http://localhost:5000/health
```

### For Operations/SRE Team

**Before Slot Swap:**
```bash
# Validate deployment safety
./validate-deployment.sh https://your-staging-slot.azurewebsites.net

# Manual health check
curl https://your-staging-slot.azurewebsites.net/health
```

**After Slot Swap:**
```bash
# Verify production health
curl https://your-production.azurewebsites.net/health

# Monitor Azure metrics
az monitor metrics list \
  --resource <resource-id> \
  --metric Http5xx \
  --start-time 2026-02-09T20:00:00Z \
  --end-time 2026-02-09T20:15:00Z
```

**Emergency Rollback:**
```bash
# Swap back to previous slot
az webapp deployment slot swap \
  --resource-group <rg-name> \
  --name <app-name> \
  --slot <current-slot> \
  --target-slot <previous-slot>
```

### Safety Features Summary

| Feature | Purpose | Behavior |
|---------|---------|----------|
| Startup Validation | Prevent production issues | App exits if INJECT_ERROR=1 in Production |
| /health Endpoint | Pre-deployment validation | Returns 503 if INJECT_ERROR enabled |
| Slot Settings | Configuration isolation | Keep INJECT_ERROR sticky to test slots |
| validate-deployment.sh | Automated checks | Validates health before swap |

## Additional Resources

- See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed Azure App Service procedures
- For questions or issues, contact the SRE team or file an issue in this repository
