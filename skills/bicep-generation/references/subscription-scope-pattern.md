# Subscription-Scope main.bicep Pattern (Mandatory)

When main.bicep creates a resource group (which is the standard pattern for this migration factory), the template **MUST** be subscription-scoped. This is a hard rule — not optional.

## Why this matters

A `targetScope = 'resourceGroup'` template cannot create its own resource group because the resource group must already exist before `az deployment group create` runs. Attempting to do so produces a 404 or "resource group not found" error mid-deployment.

## Required structure for main.bicep

```bicep
/*
  Module: main.bicep
  Purpose: Subscription-scope orchestration — creates resource group and delegates to modules.
  Source: outputs/azure-architecture-output/design-document.md Section 5
  Inputs: environment, location, resourceGroupName, workload, tags
  Outputs: (none — consumed by caller/CI)
  Notes: targetScope MUST be 'subscription'. Every module call MUST carry scope: rg.
*/

targetScope = 'subscription'

@description('Deployment environment.')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Azure region for all resources.')
param location string = 'australiaeast'

@description('Resource group name.')
param resourceGroupName string = 'rg-${workload}-${environment}'

@description('Short workload identifier.')
param workload string

@description('Tags applied to every resource.')
param tags object = {
  Environment: environment
  Application: workload
}

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module storageModule 'modules/storage.bicep' = {
  name: 'deploy-storage'
  scope: rg          // ← mandatory on EVERY module call
  params: {
    workload: workload
    environment: environment
    location: location
    tags: tags
  }
}

module functionModule 'modules/function-app.bicep' = {
  name: 'deploy-function'
  scope: rg          // ← mandatory on EVERY module call
  params: {
    workload: workload
    environment: environment
    tags: tags
  }
}
```

## Required parameter file entries

Every `.bicepparam` file must include `location` and `resourceGroupName`:

```bicep
using '../main.bicep'

param environment = 'dev'
param location = 'australiaeast'
param resourceGroupName = 'rg-migration-dev'
param workload = 'migration'
```

## Correct deployment commands

```bash
# Deploy (subscription scope)
az deployment sub create \
  --location australiaeast \
  --template-file outputs/bicep-templates/main.bicep \
  --parameters @outputs/bicep-templates/parameters/dev.bicepparam

# What-if preview (subscription scope)
az deployment sub what-if \
  --location australiaeast \
  --template-file outputs/bicep-templates/main.bicep \
  --parameters @outputs/bicep-templates/parameters/dev.bicepparam
```

## FORBIDDEN commands for subscription-scoped templates

```bash
# ❌ WRONG — cannot create resource groups at group scope
az deployment group create --resource-group rg-migration-dev --template-file main.bicep ...

# ❌ WRONG — same problem
az deployment group what-if --resource-group rg-migration-dev --template-file main.bicep ...
```

See also [module-skeleton-example.md](module-skeleton-example.md) for the corresponding child-module pattern.
