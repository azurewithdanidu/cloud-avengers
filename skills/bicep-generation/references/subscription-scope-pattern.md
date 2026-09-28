# Subscription-Scope, Grouped Orchestrator Pattern (Mandatory)

Every `main.<group>.bicep` file creates (idempotently ensures) the shared resource group and calls AVM modules directly. This is a hard rule — not optional, and there is no local module layer.

## Why this matters

A `targetScope = 'resourceGroup'` template cannot create its own resource group because the resource group must already exist before `az deployment group create` runs. Attempting to do so produces a 404 or "resource group not found" error mid-deployment. Since **every** `main.<group>.bicep` file independently ensures the resource group exists (ARM resource creation is idempotent — recreating the same RG with the same properties from multiple deployments does not conflict), every group file must be subscription-scoped.

## Required structure for `main.<group>.bicep`

This example is `main.data.bicep` — the same shape applies to every group:

```bicep
/*
  File: main.data.bicep
  Purpose: Storage accounts, Cosmos DB, PostgreSQL — subscription-scope orchestration.
  Source: outputs/azure-architecture-output/design-document.md Section 5
  Inputs: environment, location, resourceGroupName, workload, tags
  Outputs: storageAccountName, storageAccountId
  Notes: targetScope MUST be 'subscription'. Every AVM module call MUST carry scope: rg.
    No local module files — the AVM module is called directly below.
*/

targetScope = 'subscription'

@description('Deployment environment.')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Azure region for all resources.')
param location string = 'australiaeast'

@description('Resource group name — identical value across every group file.')
param resourceGroupName string = 'rg-${workload}-${environment}'

@description('Short workload identifier.')
param workload string

@description('Tags applied to every resource.')
param tags object = {
  Environment: environment
  Application: workload
}

// Idempotent — every group file ensures this same resource group.
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

var storageAccountName = '${take(toLower(replace(workload, '-', '')), 16)}${environment}store'

module storageAccount 'br/public:avm/res/storage/storage-account:0.32.0' = {
  name: 'storageAccountAvmDeploy'
  scope: rg          // ← mandatory on EVERY AVM module call
  params: {
    name: storageAccountName
    location: location
    tags: tags
  }
}

output storageAccountName string = storageAccount.outputs.name
output storageAccountId string = storageAccount.outputs.resourceId
```

And `main.compute.bicep` references `main.data.bicep`'s storage account via an `existing` lookup — never a module output, since these are separate top-level deployments:

```bicep
targetScope = 'subscription'
// ...same environment/location/resourceGroupName/workload/tags parameters...

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Must match main.data.bicep's naming formula EXACTLY.
var storageAccountName = '${take(toLower(replace(workload, '-', '')), 16)}${environment}store'

resource existingStorage 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
  scope: rg
}

module functionApp 'br/public:avm/res/web/site:0.22.0' = {
  name: 'functionAppAvmDeploy'
  scope: rg
  params: {
    // ...
    appSettingsKeyValuePairs: {
      STORAGE_ACCOUNT_NAME: existingStorage.name
    }
  }
}
```

## Required parameter file entries

Every `.bicepparam` file (one per group, per environment — see `parameter-management` skill) must include `location` and `resourceGroupName`:

```bicep
using '../../main.data.bicep'

param environment = 'dev'
param location = 'australiaeast'
param resourceGroupName = 'rg-migration-dev'
param workload = 'migration'
```

## Correct deployment commands

Deploy each group file independently, in dependency order (networking → security → data → monitoring → messaging → compute):

```bash
# Deploy (subscription scope) — one group at a time
az deployment sub create \
  --location australiaeast \
  --template-file outputs/bicep-templates/main.data.bicep \
  --parameters @outputs/bicep-templates/parameters/dev/data.bicepparam

# What-if preview (subscription scope)
az deployment sub what-if \
  --location australiaeast \
  --template-file outputs/bicep-templates/main.data.bicep \
  --parameters @outputs/bicep-templates/parameters/dev/data.bicepparam
```

## FORBIDDEN commands for subscription-scoped templates

```bash
# ❌ WRONG — cannot create resource groups at group scope
az deployment group create --resource-group rg-migration-dev --template-file main.data.bicep ...

# ❌ WRONG — same problem
az deployment group what-if --resource-group rg-migration-dev --template-file main.data.bicep ...
```

See also [module-skeleton-example.md](module-skeleton-example.md) for the corresponding direct-AVM-call and cross-group `existing`-lookup pattern.

