---
name: parameter-management
description: Create environment-specific .bicepparam files, one per grouped orchestrator file (parameters/<env>/<group>.bicepparam) for dev, staging, and production — derive parameter names from deployed services, apply correct SKUs and replication by environment
---


# Parameter Management Skill

## Purpose

Produce environment-specific parameter files that allow the same grouped Bicep orchestrator files (`main.<group>.bicep` — see `module-organization` skill) to be deployed consistently across dev, staging, and prod without any manual value changes.

## When to Use

After the `main.<group>.bicep` files are written, before any deployment validation.

## Universal Parameter Discovery Process

1. **Enumerate deployed resources per group** — Read `design-document.md` Section 5 (resource list) and the group assignment from the `module-organization` skill. For each resource, look up which parameters it contributes using the **Service Parameter Catalog** below, and note which group file (`networking`/`security`/`data`/`monitoring`/`messaging`/`compute`) it belongs to.
2. **Read per-environment values** — Read `design-document.md` Section 7 (Environment Configuration table). Record the target `location` and `workload` name.
3. **Assemble one parameter set per group** — Each group's `.bicepparam` gets `environment`, `location`, `workload`, `resourceGroupName`, plus only the service-specific parameters for resources assigned to that group.
4. **Apply environment sizing rules** — Use the **Default Sizing by Environment** table to fill in SKU, replication, and tier values not explicitly specified in Section 7.
5. **Write one `.bicepparam` file per group, per environment** — `parameters/dev/<group>.bicepparam`, `parameters/staging/<group>.bicepparam`, `parameters/prod/<group>.bicepparam`. Skip a group entirely if the workload has no resources in it.
6. **Verify each file resolves:** `az deployment sub what-if --location <region> --template-file outputs/bicep-templates/main.<group>.bicep --parameters outputs/bicep-templates/parameters/<env>/<group>.bicepparam`

### Service Parameter Catalog

Use this table to identify which parameters to include, and which group file they belong in, based on which resources are deployed:

| Deployed Service | Group | Parameters to Add | Dev default | Staging default | Prod default |
|---|---|---|---|---|---|
| **Azure Functions** (Consumption) | `compute` | `functionPlanSku` | `'Y1'` | `'Y1'` | `'Y1'` |
| **Azure Functions** (Premium) | `compute` | `functionPlanSku` | `'EP1'` | `'EP1'` | `'EP2'` |
| **Container Apps** | `compute` | `containerAppCpu`, `containerAppMemory` | `'0.25'`, `'0.5Gi'` | `'0.5'`, `'1.0Gi'` | `'1.0'`, `'2.0Gi'` |
| **App Service** | `compute` | `appServicePlanSku` | `'B1'` | `'S2'` | `'P2v3'` |
| **Blob Storage** | `data` | `storageReplication` | `'LRS'` | `'ZRS'` | `'GRS'` |
| **PostgreSQL Flexible Server** | `data` | `databaseSku` | `'Standard_B1ms'` | `'Standard_D2s_v3'` | `'Standard_D4s_v3'` |
| **Cosmos DB** | `data` | `cosmosThroughputMode` | `'serverless'` | `'manual'` | `'autoscale'` |
| **Azure SQL** | `data` | `sqlSku` | `'Basic'` | `'S2'` | `'S4'` |
| **Azure Cache for Redis** | `data` | `redisSku` | `'Basic'` | `'Standard'` | `'Premium'` |
| **Key Vault** | `security` | `keyVaultSku` | `'standard'` | `'standard'` | `'premium'` |
| **Service Bus** | `messaging` | `serviceBusSku` | `'Basic'` | `'Standard'` | `'Premium'` |
| **Event Hubs** | `messaging` | `eventHubsSku`, `eventHubsCapacity` | `'Basic'`, `1` | `'Standard'`, `2` | `'Premium'`, `4` |
| **API Management** | `messaging` | `apimSku`, `apimCapacity` | `'Consumption'`, `0` | `'Developer'`, `1` | `'Standard'`, `1` |
| **Log Analytics** | `monitoring` | `logRetentionDays` | `30` | `60` | `90` |
| **Application Insights** | `monitoring` | (shared — no separate SKU param) | — | — | — |
| **Static Web Apps** | `compute` | `staticWebAppSku` | `'Free'` | `'Standard'` | `'Standard'` |
| **VNet + Private Endpoints** | `networking` | `vnetAddressPrefix` | `'10.0.0.0/16'` | `'10.1.0.0/16'` | `'10.2.0.0/16'` |

### Generic `.bicepparam` Template

Use this template structure for every group/environment combination. Populate only the parameters that match resources assigned to that group:

```bicepparam
using '../../main.<group>.bicep'   // e.g. ../../main.compute.bicep

// ── Core identity (always present in every group's parameter file) ─────────
param environment       = '<dev|staging|prod>'
param location          = '<azure-region>'          // e.g. 'australiaeast', 'eastus', 'westeurope'
param workload          = '<workload-short-name>'   // e.g. 'orders', 'imgproc', 'portal'
param resourceGroupName = 'rg-<workload>-<environment>'

// ── Compute group only ──────────────────────────────────────────────────────
// param functionPlanSku    = '<Y1|EP1|EP2|EP3>'
// param appServicePlanSku  = '<B1|S2|P2v3>'
// param containerAppCpu    = '<0.25|0.5|1.0|2.0>'
// param containerAppMemory = '<0.5Gi|1.0Gi|2.0Gi|4.0Gi>'

// ── Data group only ──────────────────────────────────────────────────────────
// param storageReplication = '<LRS|ZRS|GRS|GZRS>'
// param databaseSku        = '<Standard_B1ms|Standard_D2s_v3|Standard_D4s_v3>'
// param cosmosThroughputMode = '<serverless|manual|autoscale>'
// param sqlSku             = '<Basic|S2|S4>'
// param redisSku           = '<Basic|Standard|Premium>'

// ── Messaging group only ──────────────────────────────────────────────────────
// param serviceBusSku      = '<Basic|Standard|Premium>'
// param eventHubsSku       = '<Basic|Standard|Premium>'
// param eventHubsCapacity  = <1|2|4>

// ── Security group only ───────────────────────────────────────────────────────
// param keyVaultSku        = '<standard|premium>'

// ── Monitoring group only ─────────────────────────────────────────────────────
// param logRetentionDays   = <30|60|90>
```

### Filled Example — dev environment (Compute + Data + Security groups)

Folder layout:
```
parameters/
├── dev/
│   ├── compute.bicepparam
│   ├── data.bicepparam
│   └── security.bicepparam
├── staging/
│   └── ...same group files...
└── prod/
    └── ...same group files...
```

**`parameters/dev/compute.bicepparam`:**
```bicepparam
using '../../main.compute.bicep'

param environment       = 'dev'
param location          = '<region>'
param workload          = '<workload>'
param resourceGroupName = 'rg-<workload>-dev'
param functionPlanSku   = 'Y1'
```

**`parameters/dev/data.bicepparam`:**
```bicepparam
using '../../main.data.bicep'

param environment         = 'dev'
param location            = '<region>'
param workload            = '<workload>'
param resourceGroupName   = 'rg-<workload>-dev'
param storageReplication  = 'LRS'
```

**`parameters/dev/security.bicepparam`:**
```bicepparam
using '../../main.security.bicep'

param environment       = 'dev'
param location          = '<region>'
param workload          = '<workload>'
param resourceGroupName = 'rg-<workload>-dev'
param keyVaultSku       = 'standard'
```

Repeat the same three files under `parameters/staging/` and `parameters/prod/` with the environment-appropriate values from the **Service Parameter Catalog** above (e.g. prod's `data.bicepparam` uses `storageReplication = 'GRS'`).

## Rules

- **Never hardcode secrets or passwords in `.bicepparam` files** — use Key Vault references or deployment-time secure parameters.
- **Always include `environment`, `location`, and `resourceGroupName` in every group's `.bicepparam` file** — every `main.<group>.bicep` needs all three to ensure the shared resource group.
- **Never mix parameters from two groups in the same `.bicepparam` file** — a group's parameter file must `using` only that group's `main.<group>.bicep`.
- **Always use LRS for dev, ZRS for staging, GRS for prod** storage replication unless `design-document.md` specifies otherwise.
- **Always use Burstable SKU for dev databases, General Purpose for prod** — never swap these.
- **Never commit `.bicepparam` files with actual secret values** — `@secure()` params must be passed at deploy time or via Key Vault.

## Output

- `outputs/bicep-templates/parameters/dev/<group>.bicepparam` — one per deployed group
- `outputs/bicep-templates/parameters/staging/<group>.bicepparam` — one per deployed group
- `outputs/bicep-templates/parameters/prod/<group>.bicepparam` — one per deployed group
- Each file passes `az deployment sub what-if --template-file outputs/bicep-templates/main.<group>.bicep --parameters outputs/bicep-templates/parameters/<env>/<group>.bicepparam` without errors

---

## Companion Scripts

| Script | Purpose |
|---|---|
| `scripts/validate-bicep.ps1` | Validates all `.bicep` files and runs what-if against each `.bicepparam` environment file |

Run after generating or updating `.bicepparam` files to verify all parameter values resolve correctly:

```powershell
./scripts/validate-bicep.ps1 \
    -ResourceGroup "rg-dev-migration" -Environment dev
```

---

## References

### Microsoft / Azure Documentation

| Topic | Link |
|---|---|
| Bicep parameter files (.bicepparam) | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/parameter-files |
| Bicep parameter decorators | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/parameters#parameter-decorators |
| Secure parameters in Bicep | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/scenarios-secrets |
| Azure Functions hosting plans and SKUs | https://learn.microsoft.com/en-us/azure/azure-functions/functions-scale |
| Azure Blob Storage redundancy options | https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy |
| Azure Database for PostgreSQL SKUs | https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-compute-storage |
| Azure Cosmos DB throughput modes | https://learn.microsoft.com/en-us/azure/cosmos-db/how-to-choose-offer |
| Azure Service Bus tiers | https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-premium-messaging |
| Azure Event Hubs pricing tiers | https://learn.microsoft.com/en-us/azure/event-hubs/event-hubs-faq#what-are-event-hubs-tiers |
| Log Analytics data retention | https://learn.microsoft.com/en-us/azure/azure-monitor/logs/data-retention-configure |
| `az deployment sub what-if` | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-what-if |

### Best Practices

- **Dev uses Consumption plan (Y1), prod uses Premium (EP2+):** Consumption plan has cold starts up to 3 seconds — Premium eliminates cold starts for latency-sensitive workloads.
- **LRS for dev, ZRS for staging, GRS for prod:** GRS replicates data to a secondary region for disaster recovery but costs ~2× LRS. ZRS provides zone-level redundancy within a single region at a moderate premium.
- **Burstable SKUs for dev databases:** `Standard_B1ms` is sufficient for development but should never be used in production — it has limited CPU credits and will throttle under sustained load.
- **Log retention: 30/60/90 day pattern** is a common regulatory baseline. Increase to 365+ days if your workload has compliance requirements (HIPAA, PCI-DSS, SOC 2).
- **Never commit actual secret values in `.bicepparam` files** — mark `@secure()` params and pass them at deploy time via `az deployment sub create --parameters key=value` or reference Key Vault secrets.

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

