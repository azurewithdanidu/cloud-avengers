# Step 2 — Post-Deployment Checklist

Requires: [Step 1 — Pre-Deployment Checklist](01-pre-deployment-checklist.md) passed and the deployment completed.

## 1. Resource Deployment Status

```bash
# Verify all expected resources are in Succeeded state
az resource list --resource-group $RESOURCE_GROUP \
  --query "[?provisioningState!='Succeeded'].[name,type,provisioningState]" \
  --output table
# Expected: empty table
```

- [ ] All resources: `provisioningState == Succeeded`
- [ ] No resources in Failed, Creating, or Deleting state
- [ ] Resource count matches expected count from design document

## 2. Connectivity Verification

```bash
# Function App reachable (200 or 401 acceptable; 5xx = fail)
curl -sf -o /dev/null -w "%{http_code}" "https://<functionapp>.azurewebsites.net/api/health"

# Application API endpoints — /api/files and /api/upload must respond (not 5xx)
FUNC_HOST="<functionapp>.azurewebsites.net"

FILES_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://${FUNC_HOST}/api/files")
echo "/api/files: $FILES_STATUS"
[ "$FILES_STATUS" -ne 500 ] && [ "$FILES_STATUS" -ne 502 ] && [ "$FILES_STATUS" -ne 503 ] \
  || { echo "FAIL: /api/files returned 5xx"; exit 1; }

UPLOAD_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X HEAD "https://${FUNC_HOST}/api/upload")
echo "/api/upload (HEAD): $UPLOAD_STATUS"
[ "$UPLOAD_STATUS" -ne 500 ] && [ "$UPLOAD_STATUS" -ne 502 ] && [ "$UPLOAD_STATUS" -ne 503 ] \
  || { echo "FAIL: /api/upload returned 5xx"; exit 1; }

# Static Web App reachable
curl -sf -o /dev/null -w "%{http_code}" "https://<swa>.azurestaticapps.net/index.html"

# Database host resolvable (from within VNet)
nslookup <postgres>.postgres.database.azure.com
```

- [ ] All Function App HTTP endpoints return 200 or 401 (not 5xx)
- [ ] `/api/files` responds without 5xx error
- [ ] `/api/upload` responds without 5xx error (HEAD probe)
- [ ] Static Web App serves index.html (HTTP 200)
- [ ] Database host resolves and is reachable on the correct port
- [ ] Blob Storage containers accessible via Function App Managed Identity
- [ ] Key Vault secrets accessible from Function App

## 3. Managed Identity Verification

```bash
FUNC_PRINCIPAL_ID=$(az webapp identity show \
  --resource-group $RESOURCE_GROUP \
  --name $FUNCTION_APP_NAME \
  --query principalId -o tsv)

az role assignment list --assignee $FUNC_PRINCIPAL_ID --output table
```

- [ ] System-assigned Managed Identity enabled on Function App
- [ ] `Storage Blob Data Contributor` role assigned on storage account
- [ ] `Key Vault Secrets User` role assigned on Key Vault
- [ ] No access key credentials in app settings (all auth via Managed Identity)

## 4. Key Vault Access Verification

```bash
az keyvault secret list --vault-name $KEY_VAULT_NAME --query "[].name" -o tsv
```

- [ ] All required secrets exist in Key Vault
- [ ] Key Vault references resolving correctly in Function App settings
- [ ] Soft delete and purge protection enabled on Key Vault
- [ ] No secrets visible as plain-text app settings

Next: [Step 3 — Security Validation](03-security-validation.md).
