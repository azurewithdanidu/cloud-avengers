# Step 5 — Common Pitfalls Checklist

Run through these before declaring Bicep complete. Requires group files already written per [Step 4](04-group-assignment.md).

## 1. App Service Plan Must Set `kind` and `reserved` for Linux

```bicep
module plan 'br/public:avm/res/web/serverfarm:0.7.0' = {
  name: 'appPlanAvmDeploy'
  scope: rg
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
No hyphens in storage account names — they are alphanumeric only. Use this exact formula in every group file that references this storage account via an `existing` lookup.

## 4. Role Assignment Name and Scope Cannot Use Module Outputs

ARM resolves `name` and `scope` at deployment start — module outputs (including outputs from another group file) are not available yet:

```bicep
// ✅ GOOD — compute locally using same formula the owning group file uses
var storageAccountName = '${take(toLower(replace(resourceNamePrefix, '-', '')), 16)}store'
resource containerRef 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' existing = {
  name: '${storageAccountName}/default/images'
}
resource ra 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, resourceNamePrefix, 'storage-blob-data-contributor')
  scope: containerRef
}
```

## 5. Every Group File Requires `targetScope = 'subscription'` and `scope: rg` on Every AVM Module Call

```bicep
targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
}

module storageAccount 'br/public:avm/res/storage/storage-account:0.32.0' = {
  name: 'storageAccountAvmDeploy'
  scope: rg   // ← required on every AVM module call, in every group file
  params: { /* ... */ }
}
```

## 6. Duplicate Deployment ID — Append `Avm` to Module Names

Every module `name:` is an ARM nested deployment ID. Two AVM module calls in the *same* group file (or across group files deployed in the same run) must not share a name.

**Convention:** Append `Avm` to every AVM module `name:` value, e.g. `name: 'storageAccountAvmDeploy'`, `name: 'keyVaultAvmDeploy'`.

## 7. Known Breaking Version Changes

| Module | Version | Breaking Change |
|---|---|---|
| `avm/res/web/serverfarm` | `0.7.0` | `skuTier` removed — use `skuName` only |
| `avm/res/storage/storage-account` | `0.32.0` | `deleteRetentionPolicy.{enabled,days}` flattened to `deleteRetentionPolicyEnabled` + `deleteRetentionPolicyDays` |

## 8. Cross-Group Naming Drift

If a group file's naming formula changes (e.g. a suffix length tweak in `main.data.bicep`), every other group file with an `existing` lookup for that resource silently breaks — the lookup will fail at deployment time with a "resource not found" error rather than a compile-time error. When changing a naming formula, grep every `main.*.bicep` file for the old pattern and update all of them in the same change.
