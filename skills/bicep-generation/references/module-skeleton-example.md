# Example Bicep Module Skeleton (module files — not main.bicep)

```bicep
/*
  Module: modules/function-app.bicep
  Purpose: Deploy the Azure Function App and its managed identity.
  Source: outputs/azure-architecture-output/design-document.md Section 5
  Inputs: workload, environment, location, tags, storageAccountName, appInsightsConnectionString
  Outputs: resourceId, name, principalId
  Notes: No hardcoded secrets, no inline resource-name interpolation, API versions 2023 or newer
*/

targetScope = 'resourceGroup'

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

@description('Azure location for the resource group deployment.')
param location string = resourceGroup().location

@description('Tags applied to the Function App resources.')
param tags object

@description('Existing storage account name used by the Function App.')
@minLength(3)
param storageAccountName string

@description('Application Insights connection string.')
@secure()
param appInsightsConnectionString string

var functionAppName = 'func-${workload}-${environment}'
var siteConfigAppSettings = [
  {
    name: 'APPINSIGHTS_CONNECTION_STRING'
    value: appInsightsConnectionString
  }
]

resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
  properties: {
    httpsOnly: true
    siteConfig: {
      appSettings: siteConfigAppSettings
    }
  }
}

output resourceId string = functionApp.id
output name string = functionApp.name
output principalId string = functionApp.identity.principalId ?? ''
```

This module is deployed from `main.bicep` with `scope: rg` — see [subscription-scope-pattern.md](subscription-scope-pattern.md).
