# Anti-Patterns to Reject

Do not accept any of the following:

- Hardcoded subscription IDs, tenant IDs, secrets, or passwords
- Inline string interpolation directly in resource `name:` properties
- API versions older than 2023
- **Any local `modules/*.bicep` wrapper file** — call the AVM module directly inside the relevant `main.<group>.bicep`; there is no local module layer in this convention
- **A shared naming/helper `.bicep` file reused via a `module` call across group files** — inline the naming variables in every group file that needs them instead
- One group file that mixes networking, security, compute, and data responsibilities — split per the `module-organization` skill's default groups
- Public network access enabled on sensitive data services without an explicit design exception
- Output omission for `resourceId`, `name`, or `principalId` on any resource another group may need
- Environment-specific literals embedded directly in a group file when they belong in parameter files
- **`targetScope = 'resourceGroup'` in any `main.<group>.bicep`** — every group file creates its own (idempotent) copy of the resource group, so it must be subscription-scoped
- **`az deployment group create` against a subscription-scoped template** — always use `az deployment sub create`
- **AVM module calls without `scope: rg`** — every AVM module call must be scoped to the resource group resource
- **`resourceGroup().location` inside a subscription-scoped template** — the `resourceGroup()` function is unavailable at subscription scope; use the `location` parameter instead
- **Passing values between group files via module outputs or cross-file `dependsOn`** — use `existing` resource lookups with a matching deterministic naming formula instead

See [subscription-scope-pattern.md](subscription-scope-pattern.md) for the correct pattern.

