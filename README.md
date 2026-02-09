
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
| LICENSE                       | License for this sample                |
| README.md                     | Project documentation (this file)      |
