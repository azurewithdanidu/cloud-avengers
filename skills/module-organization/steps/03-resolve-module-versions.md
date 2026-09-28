# Step 3 — Resolve Module Versions

Requires: AVM module identified in [Step 2](02-select-avm-modules.md).

**Never hardcode a version without verifying it exists.** Always resolve from the official CHANGELOG:

```
CHANGELOG URL pattern:
https://raw.githubusercontent.com/Azure/bicep-registry-modules/main/avm/res/<provider>/<module>/CHANGELOG.md

Examples:
https://raw.githubusercontent.com/Azure/bicep-registry-modules/main/avm/res/storage/storage-account/CHANGELOG.md
https://raw.githubusercontent.com/Azure/bicep-registry-modules/main/avm/res/web/site/CHANGELOG.md
```

Use the script at `../scripts/resolve-avm-version.sh` to automate:
```bash
./scripts/resolve-avm-version.sh storage/storage-account
# Returns: 0.32.0
```

**Confirmed working versions (May 2026 — verify before use):**

| Module | Version |
|---|---|
| `avm/res/operational-insights/workspace` | `0.15.0` |
| `avm/res/insights/component` | `0.7.1` |
| `avm/res/web/serverfarm` | `0.7.0` |
| `avm/res/web/site` | `0.22.0` |
| `avm/res/key-vault/vault` | `0.13.3` |
| `avm/res/web/static-site` | `0.9.3` |
| `avm/res/storage/storage-account` | `0.32.0` |

Always run `./scripts/resolve-avm-version.sh` to get the latest — the table above is a starting point, not a substitute for checking.

## After Writing Bicep — Restore and Validate

```bash
# Pull modules into local .bicep/modules cache
az bicep restore --file outputs/bicep-templates/main.bicep --force

# Validate compilation — must exit 0 with no errors
az bicep build --file outputs/bicep-templates/main.bicep
```

## Module File Structure

Create one module per logical resource group:

| Module file | Responsibility |
|---|---|
| `modules/networking.bicep` | VNet, subnets, NSGs, private DNS zones |
| `modules/storage.bicep` | Storage accounts, private endpoints for storage |
| `modules/security.bicep` | Key Vault, private endpoints for KV, RBAC assignments |
| `modules/compute.bicep` | Function App, App Service Plan, App Insights |
| `modules/messaging.bicep` | Service Bus namespace and queues (if used) |
| `modules/monitoring.bicep` | Log Analytics workspace, diagnostic settings |

Root `main.bicep` — only parameters, module calls, and outputs:

```bicep
param environment string
param location string = resourceGroup().location
param workload string

module networking 'modules/networking.bicep' = {
  name: 'networking'
  params: { environment: environment, location: location, workload: workload }
}

module security 'modules/security.bicep' = {
  name: 'security'
  params: {
    environment: environment
    location: location
    subnetId: networking.outputs.appSubnetId
  }
}

module compute 'modules/compute.bicep' = {
  name: 'compute'
  params: {
    environment: environment
    location: location
    keyVaultName: security.outputs.keyVaultName
    storageAccountName: storage.outputs.storageAccountName
  }
  dependsOn: [security, storage]
}
```

Dependency order (deploy in this sequence):
1. `networking` — no deps
2. `security` — depends on networking (subnet IDs)
3. `storage` — depends on networking (subnet IDs)
4. `monitoring` — no deps
5. `compute` — depends on security, storage, monitoring
6. `messaging` — depends on networking

Next: [Step 4 — Common Pitfalls Checklist](04-pitfalls-checklist.md)
