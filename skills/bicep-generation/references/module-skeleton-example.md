# Example: Direct AVM Module Call Inside `main.compute.bicep`

This is an excerpt of `main.compute.bicep` — not a separate local module file. The Function App is
declared by calling the AVM module directly, and the storage account and Application Insights
connection string it needs (owned by `main.data.bicep` and `main.monitoring.bicep`) are read via
`existing` lookups instead of module outputs.

```bicep
/*
  File: main.compute.bicep
  Purpose: Function Apps, App Service Plans, Container Apps.
  Source: outputs/azure-architecture-output/design-document.md Section 5
  Inputs: workload, environment, location, resourceGroupName, tags
  Outputs: functionAppResourceId, functionAppName, functionAppPrincipalId
  Notes: No hardcoded secrets, no inline resource-name interpolation, API versions 2023 or newer.
    No local module files — the AVM module is called directly below.
*/

targetScope = 'subscription'

@description('Short workload identifier used in resource naming.')
@minLength(2)
param workload string

@description('Deployment environment.')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string

@description('Azure region for all resources.')
param location string = 'australiaeast'

@description('Resource group name — identical value across every group file.')
param resourceGroupName string = 'rg-${workload}-${environment}'

@description('Tags applied to the Function App resources.')
param tags object

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Must match the naming formula main.data.bicep and main.monitoring.bicep use.
var storageAccountName = '${take(toLower(replace(workload, '-', '')), 16)}${environment}store'
var appInsightsName = 'appi-${workload}-${environment}'
var functionAppName = 'func-${workload}-${environment}'

resource existingStorage 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
  scope: rg
}

resource existingAppInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
  scope: rg
}

module functionApp 'br/public:avm/res/web/site:0.22.0' = {
  name: 'functionAppAvmDeploy'
  scope: rg
  params: {
    name: functionAppName
    location: location
    tags: tags
    kind: 'functionapp,linux'
    managedIdentities: {
      systemAssigned: true
    }
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_CONNECTION_STRING'
          value: existingAppInsights.properties.ConnectionString
        }
        {
          name: 'AZURE_STORAGE_ACCOUNT_NAME'
          value: existingStorage.name
        }
      ]
    }
  }
}

output functionAppResourceId string = functionApp.outputs.resourceId
output functionAppName string = functionApp.outputs.name
output functionAppPrincipalId string = functionApp.outputs.?systemAssignedMIPrincipalId ?? ''
```

Deployed with `az deployment sub create --template-file outputs/bicep-templates/main.compute.bicep ...` — see [subscription-scope-pattern.md](subscription-scope-pattern.md).

