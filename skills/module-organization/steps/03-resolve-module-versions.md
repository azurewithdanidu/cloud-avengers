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

Run restore/build for **every** group file — there is no single root template anymore:

```bash
# Pull modules into local .bicep/modules cache, then validate compilation — must exit 0 with no errors
for f in outputs/bicep-templates/main.*.bicep; do
  az bicep restore --file "$f" --force
  az bicep build --file "$f"
done
```

Next: [Step 4 — Group Assignment](04-group-assignment.md)

