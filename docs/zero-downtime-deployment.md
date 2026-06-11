# Zero-Downtime Deployment Setup

## Overview

Achieve zero-downtime deployments using Azure App Service deployment slots.

**How it works:**
```
┌─────────────────────────────────────────────────────────────┐
│  Production Slot                  Staging Slot               │
│  (Live Traffic)                   (New Version)              │
│                                                               │
│  Current: v1                      Deploy: v2                 │
│  Status: Running ──────────────→  Status: Starting          │
│                                   Warm-up: Health checks     │
│                                   Tests: Passed ✓            │
│                                                               │
│  ┌─────────────────────────────────────────────────┐        │
│  │            INSTANT SWAP (0ms downtime)           │        │
│  └─────────────────────────────────────────────────┘        │
│                                                               │
│  New: v2                          Old: v1                    │
│  Status: Serving traffic          Status: Standby           │
│                                   (Ready for rollback)       │
└─────────────────────────────────────────────────────────────┘
```

## Benefits

- ✅ **Zero Downtime**: Traffic switches instantly (atomic swap)
- ✅ **Pre-warmed**: New version is running and tested before going live
- ✅ **Instant Rollback**: Swap back in seconds if issues detected
- ✅ **Production Testing**: Test new version in prod-like environment first
- ✅ **Gradual Rollout**: Optional traffic routing (e.g., 10% to staging)

## Setup Instructions

### Step 1: Create Staging Slot

**Via Azure CLI:**
```bash
# Set variables
RESOURCE_GROUP="kml_rg_main-c5aa79dd5cb64558"
APP_NAME="petclininc"

# Create staging slot
az webapp deployment slot create \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --slot staging \
  --configuration-source $APP_NAME

# The staging slot URL will be: petclininc-staging.azurewebsites.net
```

**Via Azure Portal:**
1. Go to App Service → **Deployment** → **Deployment slots**
2. Click **+ Add Slot**
3. Name: `staging`
4. Clone settings from: `petclininc` (production)
5. Click **Add**

### Step 2: Configure Slot-Specific Settings (Optional)

Some settings should NOT swap (like connection strings for different databases):

```bash
# Mark settings as slot-specific (won't swap)
az webapp config appsettings set \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --slot staging \
  --slot-settings MYSQL_URL MYSQL_USER MYSQL_PASS
```

### Step 3: Update Pipeline to Use Slots

Replace the deployment template in `azure-pipelines.yml`:

```yaml
# Old (causes downtime):
- template: templates/deploy-appservice.yml

# New (zero downtime):
- template: templates/deploy-appservice-zero-downtime.yml
```

### Step 4: Test Slot Deployment

**Manual test:**
```bash
# Deploy to staging slot
az webapp config container set \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --slot staging \
  --docker-custom-image-name petclinicspringbootacr.azurecr.io/petclinic:v2

# Test staging: https://petclininc-staging.azurewebsites.net

# When ready, swap to production (instant, zero downtime)
az webapp deployment slot swap \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --slot staging \
  --target-slot production
```

## Deployment Flow with Slots

### Before (Downtime):
```
1. Deploy new version → App restarts
2. Downtime: 30-60 seconds ❌
3. Users see errors during restart
```

### After (Zero Downtime):
```
1. Deploy to staging slot
2. Staging starts up (production still serving traffic)
3. Health checks pass on staging
4. SWAP: Traffic instantly switches ✓
5. Zero downtime, zero errors ✅
```

## Manual Swap Commands

```bash
# Swap staging → production
az webapp deployment slot swap \
  --name petclininc \
  --resource-group kml_rg_main-c5aa79dd5cb64558 \
  --slot staging \
  --target-slot production

# Rollback (swap back)
az webapp deployment slot swap \
  --name petclininc \
  --resource-group kml_rg_main-c5aa79dd5cb64558 \
  --slot staging \
  --target-slot production
```

## Advanced: Traffic Routing (Gradual Rollout)

Route percentage of traffic to staging before full swap:

```bash
# Send 10% of traffic to staging (canary deployment)
az webapp traffic-routing set \
  --name petclininc \
  --resource-group kml_rg_main-c5aa79dd5cb64558 \
  --distribution staging=10

# Monitor for errors, then increase to 50%
az webapp traffic-routing set \
  --name petclininc \
  --resource-group kml_rg_main-c5aa79dd5cb64558 \
  --distribution staging=50

# If all good, do full swap (100%)
az webapp deployment slot swap \
  --name petclininc \
  --resource-group kml_rg_main-c5aa79dd5cb64558 \
  --slot staging
```

## Cost Considerations

- **Standard tier or higher** required for deployment slots
- Staging slot runs on same App Service Plan (no extra compute cost if capacity available)
- Consider scaling plan temporarily during deployments if needed

## Pricing Tiers

| Tier | Slots Available | Zero Downtime |
|------|-----------------|---------------|
| Free/Shared | 0 | ❌ No |
| Basic | 0 | ❌ No |
| Standard | 5 | ✅ Yes |
| Premium | 20 | ✅ Yes |

Check current tier:
```bash
az appservice plan show \
  --name <your-plan-name> \
  --resource-group kml_rg_main-c5aa79dd5cb64558 \
  --query sku.tier
```

Upgrade if needed:
```bash
az appservice plan update \
  --name <your-plan-name> \
  --resource-group kml_rg_main-c5aa79dd5cb64558 \
  --sku S1
```

## Monitoring & Rollback

**View slot health:**
```bash
# Production health
curl https://petclininc.azurewebsites.net/actuator/health

# Staging health  
curl https://petclininc-staging.azurewebsites.net/actuator/health
```

**Quick rollback if issues:**
```bash
# Swap back (instant rollback)
az webapp deployment slot swap \
  --name petclininc \
  --resource-group kml_rg_main-c5aa79dd5cb64558 \
  --slot staging \
  --target-slot production
```

## References

- [Azure App Service Deployment Slots](https://learn.microsoft.com/azure/app-service/deploy-staging-slots)
- [Zero-downtime deployment patterns](https://learn.microsoft.com/azure/architecture/patterns/deployment-stamp)
