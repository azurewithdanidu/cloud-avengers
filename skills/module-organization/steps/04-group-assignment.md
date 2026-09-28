# Step 4 — Group Assignment and Cross-Group References

Requires: AVM module and version identified in [Step 2](02-select-avm-modules.md) / [Step 3](03-resolve-module-versions.md).

There is **no root `main.bicep`** and **no `modules/` folder**. Every resource is assigned to one of a small number of grouped, subscription-scoped orchestrator files, each named `main.<group>.bicep`, and the AVM module for that resource is called **directly** inside that file.

## Default Groups

| Group file | Responsibility | Change frequency |
|---|---|---|
| `main.networking.bicep` | VNet, subnets, NSGs, private DNS zones | Rare |
| `main.security.bicep` | Key Vault, Managed Identities, RBAC role assignments | Rare |
| `main.data.bicep` | Storage accounts, Cosmos DB, SQL/PostgreSQL | Rare (stateful — handle with care) |
| `main.monitoring.bicep` | Log Analytics workspace, Application Insights, alerts | Rare |
| `main.messaging.bicep` | Service Bus, Event Grid, Event Hubs | Occasional |
| `main.compute.bicep` | Function Apps, App Service Plans, Container Apps | **Frequent** — isolated so app-level redeploys never touch stable infra |

**Adjust this default set when the workload justifies it** (e.g. split `main.compute.bicep` into `main.compute-api.bicep` and `main.compute-jobs.bicep` if they redeploy independently, or merge `main.monitoring.bicep` into `main.security.bicep` for a very small workload). State the justification in `outputs/bicep-templates/README.md` when you deviate from the default set.

## Per-Group File Skeleton

Every `main.<group>.bicep` is independently deployable and follows this shape:

```bicep
targetScope = 'subscription'

@description('Deployment environment.')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Azure region for all resources.')
param location string = 'australiaeast'

@description('Resource group name — same value in every group file.')
param resourceGroupName string = 'rg-${workload}-${environment}'

@description('Short workload identifier.')
param workload string

@description('Tags applied to every resource.')
param tags object = {
  Environment: environment
  Application: workload
}

// Every group file ensures the same resource group. ARM resource creation
// is idempotent — creating the same RG with the same properties from
// multiple independent deployments is safe and does not conflict.
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// AVM module called DIRECTLY — no local wrapper file.
module storageAccount 'br/public:avm/res/storage/storage-account:0.32.0' = {
  name: 'storageAccountAvmDeploy'
  scope: rg
  params: {
    name: storageAccountName
    location: location
    tags: tags
    // ...
  }
}

output storageAccountName string = storageAccount.outputs.name
```

## Cross-Group References — `existing` Lookups, Not Module Outputs

Because each group file is a separate top-level deployment, `main.compute.bicep` cannot consume `main.data.bicep`'s module outputs directly. Instead, **recompute the same deterministic name** (see `references/aws-to-avm-module-mapping.md` and the naming conventions in `skills/bicep-generation/references/naming-conventions.md`) and declare the resource as `existing`:

```bicep
// Inside main.compute.bicep — referencing a Key Vault created by main.security.bicep
var keyVaultName = 'kv-${workload}-${environment}'

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
  scope: rg
}

// Use keyVault.properties.vaultUri, or assign RBAC against keyVault.id, etc.
```

This is intentional duplication (per the "zero shared helper files" rule) — copy the naming variable into every group file that needs it rather than factoring it into a shared file.

## Deployment Order

Deploy (and re-validate) group files in this sequence — later groups assume earlier groups already exist:

1. `main.networking.bicep` — no cross-group deps
2. `main.security.bicep` — may reference networking (private endpoint subnet IDs)
3. `main.data.bicep` — may reference networking + security (private endpoints, CMK in Key Vault)
4. `main.monitoring.bicep` — no cross-group deps
5. `main.messaging.bicep` — may reference networking
6. `main.compute.bicep` — deployed most often; references security, data, monitoring, messaging as needed

Next: [Step 5 — Common Pitfalls Checklist](05-pitfalls-checklist.md)
