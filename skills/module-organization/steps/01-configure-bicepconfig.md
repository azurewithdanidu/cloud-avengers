# Step 1 — Configure bicepconfig.json (Mandatory First)

Every project that uses AVM modules MUST have this file at the Bicep root (`outputs/bicep-templates/bicepconfig.json`):

```json
{
  "$schema": "https://aka.ms/bicep-config",
  "moduleAliases": {
    "br": {
      "public": {
        "registry": "mcr.microsoft.com",
        "modulePath": "bicep"
      }
    }
  }
}
```

**CRITICAL:** `modulePath` must be `"bicep"` — NOT `"bicep/public"`.
- Correct: `mcr.microsoft.com/bicep/avm/res/storage/storage-account:0.32.0`
- Wrong: `mcr.microsoft.com/bicep/public/avm/res/...` (does not exist — causes "artifact does not exist in registry" error)

Reference syntax in Bicep:
```bicep
module storageAccount 'br/public:avm/res/storage/storage-account:0.32.0' = { ... }
```

**Do not skip:** `az bicep build` fails on every `br/public:avm/...` reference until this file exists with the correct `modulePath`.

Next: [Step 2 — AVM Module Selection](02-select-avm-modules.md)
