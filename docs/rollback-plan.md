# Rollback Plan

## Primary Runtime
Azure App Service for Containers

## Rollback Triggers
- Smoke test failure after deployment
- Health endpoint degradation
- Critical production defect
- Security issue detected in promoted image

## Rollback Steps
1. Identify the last known good image tag in Azure Container Registry.
2. Reconfigure the App Service container setting to the previous tag.
3. Restart the App Service or swap back if deployment slots are used.
4. Re-run smoke tests against the restored version.
5. Capture incident details and create follow-up actions.

## Validation
- `/actuator/health` returns success.
- Core application workflow loads successfully.
- Monitoring alerts return to normal.