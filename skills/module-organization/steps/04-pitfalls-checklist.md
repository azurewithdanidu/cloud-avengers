# Step 4 — Common Pitfalls Checklist

Run through these before declaring Bicep complete. Requires modules already written per [Step 3](03-resolve-module-versions.md).

## 1. App Service Plan Must Set `kind` and `reserved` for Linux

```bicep
module plan 'br/public:avm/res/web/serverfarm:0.7.0' = {
  name: 'appPlanAvmDeploy'
  params: {
    name: planName
    skuName: 'Y1'
    kind: 'linux'    // REQUIRED for Linux
    reserved: true   // REQUIRED for Linux
  }
}
```
Omitting `kind: 'linux'` and `reserved: true` silently creates a Windows plan — Function App deploys but fails at runtime.

## 2. Set `linuxFxVersion` Explicitly

```bicep
siteConfig: {
  linuxFxVersion: 'PYTHON|3.11'   // uppercase, pipe-separated
  appSettings: [
    { name: 'FUNCTIONS_WORKER_RUNTIME', value: 'python' }
  ]
}
```
Azure defaults to oldest registered runtime (Python 3.6) when `linuxFxVersion` is blank.

## 3. Storage Account Name Length (≤ 24 chars, alphanumeric only)

```bicep
// ✅ CORRECT — take(16) + 8 suffix = 24 chars max
var storageAccountName = '${take(toLower(replace(resourceNamePrefix, '-', '')), 16)}funcstor'
```
No hyphens in storage account names — they are alphanumeric only.

## 4. Role Assignment Name and Scope Cannot Use Module Outputs

ARM resolves `name` and `scope` at deployment start — module outputs are not available yet:

```bicep
// ✅ GOOD — compute locally using same formula as the module
var storageAccountName = '${take(toLower(replace(resourceNamePrefix, '-', '')), 16)}store'
resource containerRef 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' existing = {
  name: '${storageAccountName}/default/images'
}
resource ra 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, resourceNamePrefix, 'storage-blob-data-contributor')
  scope: containerRef
}
```

## 5. Subscription-Scope Deployments Require `scope: rg` on Modules

```bicep
targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module networking 'modules/networking.bicep' = {
  name: 'networkingDeploy'
  scope: rg   // ← required
  params: { ... }
}
```

## 6. Duplicate Deployment ID — Append `Avm` to Inner Module Names

Every module `name:` is an ARM nested deployment ID. If the name in `main.bicep` matches a name inside a child module, ARM throws a duplicate deployment ID error.

**Convention:** Append `Avm` to all inner AVM module `name:` values:
- Outer in `main.bicep`: `name: 'storageAccountDeploy'`
- Inner in `modules/storage.bicep`: `name: 'storageAccountAvmDeploy'`

## 7. Known Breaking Version Changes

| Module | Version | Breaking Change |
|---|---|---|
| `avm/res/web/serverfarm` | `0.7.0` | `skuTier` removed — use `skuName` only |
| `avm/res/storage/storage-account` | `0.32.0` | `deleteRetentionPolicy.{enabled,days}` flattened to `deleteRetentionPolicyEnabled` + `deleteRetentionPolicyDays` |

## 8. Do Not Set `experimentalFeaturesEnabled` in bicepconfig.json

```json
// ❌ Causes build warnings — remove this section entirely
{
  "experimentalFeaturesEnabled": { "extensibility": true }
}
```

Also see [CloudFormation → Bicep syntax mapping](../references/cloudformation-to-bicep-mapping.md) if translating from an existing CloudFormation/SAM template.
