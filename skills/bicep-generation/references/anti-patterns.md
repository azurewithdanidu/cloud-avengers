# Anti-Patterns to Reject

Do not accept any of the following:

- Hardcoded subscription IDs, tenant IDs, secrets, or passwords
- Inline string interpolation directly in resource `name:` properties
- API versions older than 2023
- One giant module that mixes networking, security, compute, and data responsibilities
- Public network access enabled on sensitive data services without an explicit design exception
- Output omission for `resourceId`, `name`, or `principalId`
- Environment-specific literals embedded in module code when they belong in parameter files
- **`targetScope = 'resourceGroup'` in main.bicep when the template creates its own resource group** — this makes `az deployment group create` fail because the resource group does not yet exist
- **`az deployment group create` against a subscription-scoped template** — always use `az deployment sub create`
- **Module calls in main.bicep without `scope: rg`** — every module call must be scoped to the resource group resource
- **`resourceGroup().location` inside a subscription-scoped template** — the `resourceGroup()` function is unavailable at subscription scope; use the `location` parameter instead

See [subscription-scope-pattern.md](subscription-scope-pattern.md) for the correct pattern.
