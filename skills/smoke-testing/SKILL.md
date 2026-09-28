---
name: smoke-testing
description: Verify a deployed Azure environment is functional — endpoint availability, managed identity, Key Vault access, and end-to-end data flow checks across any Azure service type
---


# Smoke Testing Skill

## Purpose

Confirm a deployed environment works end-to-end by running targeted checks against the actual deployed resources, not just validating templates.

## When to Use

After a successful Bicep deployment, before marking Phase 4 complete.

## Inputs

| Path | Why it matters |
|---|---|
| `outputs/azure-architecture-output/design-document.md` | Section 4 and 8 define expected endpoints, networking topology, and service names |
| `outputs/bicep-templates/` | Bicep outputs provide deployed resource names, URLs, and Key Vault references |
| `outputs/azure-functions/` | Deployed function code to test endpoint availability against |
## Process

1. **Get deployed resource names** from Bicep outputs — one call per group (each group file is deployed via `az deployment sub create`, so its outputs are read via `az deployment sub show`):
   ```bash
   az deployment sub show \
     --name <deployment-name> \
     --query properties.outputs \
     --output json
   ```

2. **HTTP endpoint check** — expect 200 or 401 (auth required is OK; 5xx is a failure):
   ```bash
   HOST=$(az functionapp show \
     --name <functionapp-name> \
     --resource-group rg-<env>-<workload> \
     --query defaultHostName -o tsv)
   STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://${HOST}/api/health")
   echo "Health endpoint: $STATUS"
   [ "$STATUS" -eq 200 ] || [ "$STATUS" -eq 401 ] || exit 1
   ```

   > For **Container Apps**, replace `az functionapp show` with `az containerapp show ... --query properties.configuration.ingress.fqdn`.  
   > For **App Service**, replace with `az webapp show ... --query defaultHostName`.  
   > For **Static Web Apps**, replace with `az staticwebapp show ... --query defaultHostname`.

3. **Managed identity check** — must return a `principalId`:
   ```bash
   az functionapp identity show \
     --name <resource-name> \
     --resource-group rg-<env>-<workload> \
     --query principalId -o tsv
   ```

4. **Key Vault secret resolution check** — verify the app can read a secret:
   ```bash
   az keyvault secret show \
     --vault-name <kv-name> \
     --name TestSecret \
     --query value -o tsv
   ```

5. **End-to-end data flow check** — run the check that matches your primary data service. See [references/service-check-catalog.md](references/service-check-catalog.md) for the per-service commands (Blob Storage, Cosmos DB, Azure SQL/PostgreSQL, Service Bus, Redis, Static Web Apps, Functions API endpoints, APIM, Log Analytics ingestion).

---

6. **Write results** to `outputs/deployment-validation/smoke-test-report.md`:
   ```markdown
   # Smoke Test Report — <env>
   ## Status: PASSED / FAILED

   | Check | Result | Details |
   |---|---|---|
   | HTTP health endpoint | PASS | HTTP 200 |
   | Managed identity | PASS | principalId: <id> |
   | Key Vault secret read | PASS | Secret resolved |
   | <Primary data service> write/read | PASS | Test record created and verified |
   | Log Analytics ingestion | PASS | 5 rows returned |
   ```

## Rules

- **Never mark smoke tests passed if any HTTP endpoint returns 5xx.**
- **Always test at least one end-to-end data flow** — writing and reading back from the primary data service is the minimum acceptable test.
- **Always clean up test data** — delete or TTL-expire test records after the test passes.
- **If any check fails**, write `## Status: FAILED` at the top of the report and include the error message.
- **Run the check that matches your deployed service** — do not run Blob Storage checks if the workload uses Cosmos DB as its primary store.

## Outputs

- `outputs/deployment-validation/smoke-test-report.md` — contains `## Status: PASSED` or `## Status: FAILED`, plus a results table for each check

---

## Scripts

| Script | Purpose |
|---|---|
| `scripts/smoke-test.ps1` | Runs all 5 smoke test categories and writes `outputs/deployment-validation/smoke-test-report.md` |

Run immediately after a successful deployment:

```powershell
./scripts/smoke-test.ps1 \
    -ResourceGroup "rg-dev-migration" \
    -Environment dev \
    -FunctionAppName "dev-myapp-func" \
    -KeyVaultName "dev-myapp-kv" \
    -StorageAccountName "devmyappstor"
```

The script exits 1 if any check fails, making it safe to use as a CI gate.

---

## References

### Microsoft / Azure Documentation

| Topic | Link |
|---|---|
| Azure CLI reference index | https://learn.microsoft.com/en-us/cli/azure/reference-index |
| `az functionapp` CLI reference | https://learn.microsoft.com/en-us/cli/azure/functionapp |
| `az containerapp` CLI reference | https://learn.microsoft.com/en-us/cli/azure/containerapp |
| `az storage blob` CLI reference | https://learn.microsoft.com/en-us/cli/azure/storage/blob |
| `az cosmosdb` CLI reference | https://learn.microsoft.com/en-us/cli/azure/cosmosdb |
| `az keyvault secret` CLI reference | https://learn.microsoft.com/en-us/cli/azure/keyvault/secret |
| `az servicebus` CLI reference | https://learn.microsoft.com/en-us/cli/azure/servicebus |
| `az monitor log-analytics query` | https://learn.microsoft.com/en-us/cli/azure/monitor/log-analytics#az-monitor-log-analytics-query |
| Azure Functions monitoring overview | https://learn.microsoft.com/en-us/azure/azure-functions/monitor-functions |
| Managed Identity verification | https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/how-to-use-vm-token |
| Azure Static Web Apps deployment | https://learn.microsoft.com/en-us/azure/static-web-apps/deploy-web-framework |
| Application Insights availability tests | https://learn.microsoft.com/en-us/azure/azure-monitor/app/availability-overview |

### Best Practices

- **Always clean up smoke test data** — use TTL fields in Cosmos DB (`_ttl`) or set short TTLs on Service Bus messages; storage blobs should be deleted explicitly after the test.
- **5xx is always a failure; 401 is acceptable** for authenticated endpoints when testing without credentials — it proves the function is running and rejecting unauthenticated requests.
- **Test from within the VNet** when private endpoints are used — external curl calls will fail even if the service is healthy.
- **Log Analytics ingestion lag:** After first deployment, it may take 5–10 minutes for activity data to appear in Log Analytics. If the query returns empty, wait and retry before marking as failed.
- **Application Insights availability tests** can replace manual curl-based health checks for ongoing monitoring after migration completes.

---

## Runtime Detection

This skill supports both Bash and PowerShell. Use the following detection order:

| Priority | Runtime | Condition | Script |
|---|---|---|---|
| 1 (preferred) | Bash | `curl` and `jq` available on PATH | `scripts/<name>.sh` |
| 2 | PowerShell 7+ | `pwsh` available on PATH | `scripts/<name>.ps1` |
| 3 (fallback) | Windows PowerShell 5.1 | `powershell.exe` available | `scripts/<name>.ps1 -ExecutionPolicy RemoteSigned` |

**Detection snippet (Bash):**
```bash
if command -v curl &>/dev/null && command -v jq &>/dev/null; then
  bash scripts/<name>.sh [args]
elif command -v pwsh &>/dev/null; then
  pwsh -File scripts/<name>.ps1 [args]
elif command -v powershell.exe &>/dev/null; then
  powershell.exe -ExecutionPolicy RemoteSigned -File scripts/<name>.ps1 [args]
else
  echo "ERROR: Requires curl+jq (Bash) or PowerShell 7+ (pwsh)"
  exit 1
fi
```

**Parameter naming convention:** Bash uses `--kebab-case`; PowerShell uses `-PascalCase`. Both produce identical output.

