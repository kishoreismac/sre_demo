# Deployment Guide for Azure App Service

## Azure App Service Configuration

### Step 1: Configure Slot-Specific Settings

To prevent `INJECT_ERROR` from accidentally moving to production during slot swaps:

1. Navigate to Azure Portal → App Service → **Configuration**
2. Go to **Application settings** tab
3. For the `INJECT_ERROR` setting:
   - **Production Slot**: Set to `0` or leave unset
   - **Staging/Test Slots**: Can be set to `1` for testing
4. **IMPORTANT**: Check the "Deployment slot setting" checkbox for `INJECT_ERROR`
   - This makes the setting "sticky" to the slot
   - It will NOT swap to production during slot swap operations

### Step 2: Pre-Deployment Validation

Before swapping any slot to production:

```bash
# Check the health endpoint on the staging slot
curl -i https://<staging-slot-url>/health

# Expected response for safe deployment:
HTTP/1.1 200 OK
{"status":"healthy","environment":"<environment>","timestamp":"..."}

# If you see HTTP 503 or "unhealthy" status, DO NOT PROCEED with swap
# Fix the configuration first
```

### Step 3: Slot Swap Procedure

1. **Validate staging slot**:
   ```bash
   curl https://<staging-slot-url>/health
   ```

2. **Check metrics** (ensure Http5xx = 0 for at least 5 minutes):
   - Azure Portal → App Service → Metrics
   - Select metric: `Http 5xx` (Total)
   - Time range: Last 15 minutes

3. **Perform swap**:
   - Azure Portal → App Service → Deployment slots
   - Click **Swap**
   - Source: staging slot
   - Target: production
   - Review settings preview
   - Click **Swap**

4. **Post-swap validation**:
   ```bash
   # Verify production health
   curl https://<production-url>/health
   
   # Should return HTTP 200 with "healthy" status
   ```

5. **Monitor metrics** for 10-15 minutes:
   - Http5xx should remain at 0
   - Request rate should be normal
   - Response time should be acceptable

### Step 4: Rollback Procedure (if needed)

If Http5xx errors are detected after swap:

1. **Immediate action**: Swap back to previous slot
   ```bash
   # Azure CLI command
   az webapp deployment slot swap \
     --resource-group <resource-group> \
     --name <app-name> \
     --slot <current-production-slot> \
     --target-slot <previous-good-slot>
   ```

2. **Investigate**:
   - Check application logs
   - Verify `INJECT_ERROR` setting
   - Check `/health` endpoint
   - Review recent configuration changes

3. **Fix and redeploy**:
   - Correct the configuration issue
   - Validate on staging slot
   - Reattempt deployment following steps 1-3

## Environment Settings Reference

| Environment | INJECT_ERROR Value | Purpose |
|-------------|-------------------|---------|
| Production | `0` or unset | Normal operation - NO error injection |
| Staging | `0` or `1` | Can enable for pre-production testing |
| Development | `0` or `1` | Can enable for local testing |
| Test/Demo Slots | `1` | Error simulation for demos |

## Troubleshooting

### App Won't Start in Production

**Symptom**: Application fails to start with exit code 1

**Cause**: `INJECT_ERROR=1` is set in Production environment

**Solution**:
1. Go to Azure Portal → App Service → Configuration
2. Find `INJECT_ERROR` setting
3. Change value to `0` or delete the setting
4. Save changes
5. Restart the app

### Health Check Returns 503

**Symptom**: `/health` endpoint returns HTTP 503

**Response**:
```json
{
  "status": "unhealthy",
  "reason": "INJECT_ERROR is enabled",
  "environment": "...",
  "timestamp": "..."
}
```

**Solution**:
1. This is a WARNING - do not deploy this slot to production
2. Disable `INJECT_ERROR` in the slot configuration
3. Restart the slot
4. Verify `/health` returns 200 before proceeding

### HTTP 5xx Errors in Production

**Symptom**: Elevated Http5xx error rate in production

**Immediate Action**:
1. Execute slot swap rollback
2. Check metrics to verify error rate has dropped
3. Review `INJECT_ERROR` configuration
4. Check application logs for root cause

**Prevention**:
- Always validate `/health` endpoint before slot swap
- Ensure `INJECT_ERROR` is marked as slot-specific setting
- Follow the deployment checklist in README.md

## Monitoring and Alerts

### Recommended Alert Rules

Configure these alerts in Azure Monitor:

1. **HTTP 5xx Errors**:
   - Metric: `Http 5xx`
   - Threshold: `> 0` (any 5xx error)
   - Time window: 5 minutes
   - Action: Notify ops team

2. **Error Rate**:
   - Metric: `Http 5xx / Requests * 100`
   - Threshold: `> 1%`
   - Time window: 5 minutes
   - Action: Notify ops team + consider auto-rollback

3. **Health Check**:
   - Availability test on `/health` endpoint
   - Expected: HTTP 200 with "healthy" status
   - Frequency: Every 5 minutes
   - Action: Alert if unhealthy

## Additional Resources

- [Azure App Service Deployment Slots](https://docs.microsoft.com/en-us/azure/app-service/deploy-staging-slots)
- [Azure App Service Configuration](https://docs.microsoft.com/en-us/azure/app-service/configure-common)
- [Azure Monitor Alerts](https://docs.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-overview)
