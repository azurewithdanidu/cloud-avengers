---
name: bicep-generation
description: 'Generate secure Azure Bicep templates as grouped, subscription-scoped orchestrator files (main.<group>.bicep) that call AVM modules directly. Use when: writing outputs/bicep-templates/main.*.bicep, defining parameters and outputs, applying naming conventions, or validating that IaC matches the architecture design contract. No local module files.'
---

# Bicep Generation Skill

## Purpose

Produce deployment-ready Azure Bicep that is secure, environment-aware, and explicit enough for human review and automated deployment — organized as a small number of grouped, subscription-scoped orchestrator files (see `module-organization` skill for the group boundaries) rather than a single `main.bicep` plus local `modules/*.bicep` wrapper files.

## When to Use

- When translating Section 5 of `design-document.md` into `main.<group>.bicep` files
- When reviewing or repairing generated Bicep
- When creating environment parameter files for dev, staging, and prod
- When validation finds drift between design and IaC

## Inputs

| Path | Why it matters |
|---|---|
| `outputs/azure-architecture-output/design-document.md` | Source of truth for Section 5 resource specifications |
| `outputs/bicep-templates/` | Target output directory — flat, no `modules/` subdirectory |
| `outputs/bicep-templates/parameters/<env>/` | Target directory for per-group, per-environment parameter files |

## Outputs

| Path | Result |
|---|---|
| `outputs/bicep-templates/main.networking.bicep`, `main.security.bicep`, `main.data.bicep`, `main.monitoring.bicep`, `main.messaging.bicep`, `main.compute.bicep` | Subscription-scoped orchestrator files — see `module-organization` skill for group boundaries |
| `outputs/bicep-templates/parameters/dev/<group>.bicepparam` | Dev parameter file per group |
| `outputs/bicep-templates/parameters/staging/<group>.bicepparam` | Staging parameter file per group |
| `outputs/bicep-templates/parameters/prod/<group>.bicepparam` | Prod parameter file per group |

## Process

### 1. Start from the architecture contract

1. Read Section 5 of `outputs/azure-architecture-output/design-document.md` in full.
2. List every resource required.
3. Assign each resource to a group file per the `module-organization` skill.
4. Decide which parameters belong at the group-file level (most of them — each group file is self-contained).
5. Write the header block, parameters, variables, resources/AVM module calls, and outputs in that order.

### 2. Required Bicep file header comment block

Put this header at the top of every `main.<group>.bicep` file:

```bicep
/*
  File: main.<group>.bicep
  Purpose: <what this group deploys, e.g. "Storage accounts, Cosmos DB, PostgreSQL">
  Source: outputs/azure-architecture-output/design-document.md Section 5
  Inputs: <comma-separated parameter names>
  Outputs: <one resourceId/name/principalId triplet per resource other groups may reference>
  Notes: No hardcoded secrets, no inline resource-name interpolation, API versions 2023 or newer.
    No local module files — every resource below is an AVM module call or an `existing` lookup.
*/
```

### 3. Mandatory parameter decorator patterns

Every public parameter must include a description. Apply range or allowed-value decorators where the contract requires them.

```bicep
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

@description('Azure region short code such as aue or ause.')
@minLength(2)
param regionCode string

@description('Tags applied to every resource in this module.')
param tags object
```

Recommended additional decorators when the contract needs them:

- `@maxLength()` for globally constrained names
- `@secure()` for secrets or protected values
- `@minValue()` / `@maxValue()` for numeric capacity settings


### 4. Naming, outputs, and anti-patterns

- **Naming conventions:** derive every resource name deterministically from `workload`/`environment`/`region` parameters — see [references/naming-conventions.md](references/naming-conventions.md) for the pattern table. Use the **exact same formula** in every group file that needs an `existing` lookup for that resource.
- **Required outputs:** every resource another group or a downstream agent may need must output `resourceId` (string), `name` (string), and `principalId` (string, empty if the resource has no identity). Add `hostname`, `endpoint`, `privateEndpointId`, or `connectionSettingName` when relevant.
- **Anti-patterns:** see [references/anti-patterns.md](references/anti-patterns.md) for the full reject list (hardcoded IDs/secrets, old API versions, missing `scope: rg`, local module files, etc.).

### 5. Subscription-scope, grouped orchestrator pattern (Mandatory)

Every `main.<group>.bicep` creates (idempotently ensures) the shared resource group and **MUST** be subscription-scoped — see [references/subscription-scope-pattern.md](references/subscription-scope-pattern.md) for the required structure, parameter file entries, and correct vs. forbidden deployment commands.

### 6. Example: direct AVM module call + cross-group `existing` lookup

See [references/module-skeleton-example.md](references/module-skeleton-example.md) for a complete example showing the header block, decorators, naming, an AVM module call, and an `existing` lookup into another group's resource.

### 7. Validation workflow

1. Ensure every group file has the required header block.
2. Ensure every parameter has `@description`.
3. Ensure any bounded string or enum-like parameter also has `@minLength` or `@allowed` as applicable.
4. Ensure every resource other groups may reference emits `resourceId`, `name`, and `principalId`.
5. Ensure every group file declares `targetScope = 'subscription'` and that every AVM module call has `scope: rg`.
6. Build and sanity-check every group file — there is no single template to check.

```bash
# Syntax check — repeat for every group file
for f in outputs/bicep-templates/main.*.bicep; do
  az bicep build --file "$f"
done

# Subscription-scope what-if (must use sub — not group) — one group at a time
az deployment sub what-if \
  --location australiaeast \
  --template-file outputs/bicep-templates/main.compute.bicep \
  --parameters @outputs/bicep-templates/parameters/dev/compute.bicepparam
```

### 8. Edge Cases / Failure Modes

- **No managed identity on a resource:** still output `principalId` as an empty string to keep the contract stable.
- **Global naming collision:** introduce a suffix variable or parameter rather than changing the naming scheme ad hoc.
- **One resource type needs an older API version:** escalate to architecture or document the exception explicitly; the default rule is 2023 or newer.
- **Design document omits a required resource:** do not invent its purpose; route the issue back to architecture.
- **Private endpoint requirements absent:** if the security design says private networking is mandatory, treat the omission as a contract issue.
- **A group needs a resource from another group that hasn't deployed yet:** this is a deployment-order defect, not a Bicep defect — fix the CI/CD sequencing (see `module-organization` skill's deployment order), never add a local module or cross-file `dependsOn` to work around it.

## Rules

- **No local module files.** Call AVM modules directly inside the relevant `main.<group>.bicep`.
- **Every public parameter must have `@description`.**
- **Use `@minLength` and `@allowed` whenever the contract implies them.**
- **No inline interpolation in resource names; compute names in variables first.**
- **No API versions older than 2023.**
- **Every resource other groups may reference must output `resourceId`, `name`, and `principalId`.**
- **Every `main.<group>.bicep` MUST declare `targetScope = 'subscription'`.** Using `targetScope = 'resourceGroup'` makes `az deployment group create` fail because the group doesn't exist yet.
- **Every AVM module call MUST include `scope: rg`.** Omitting it silently deploys to the wrong scope and causes cryptic errors.
- **Deploy each group file with `az deployment sub create --location <region>`.** Never use `az deployment group create`.
- **Never use `resourceGroup().location` inside a subscription-scoped template.** Use the `location` parameter instead.
- **Never pass values between group files via module outputs.** Use `existing` resource lookups with a matching naming formula instead.

## Best Practices

- Keep each `main.<group>.bicep` focused on its one group — split further if a group grows unwieldy (see `module-organization` skill's default-group deviation guidance).
- Put environment differences in `.bicepparam` files instead of branching inside a group file.
- Prefer consistent variable names like `functionAppName`, `serviceBusNamespaceName`, and `keyVaultName` — reused verbatim across group files for `existing` lookups.
- Reuse the same `tags` object shape across group files for auditability.
- Make outputs predictable so other group files and CI/CD workflows can compute matching `existing` lookups without file-specific logic.

---

## References

### Microsoft / Azure Documentation

| Topic | Link |
|---|---|
| Bicep overview | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview |
| Bicep best practices | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/best-practices |
| Bicep parameters | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/parameters |
| Bicep variables | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/variables |
| Bicep modules | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/modules |
| Bicep outputs | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/outputs |
| Bicep decorators | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/parameters#parameter-decorators |
| bicepconfig.json reference | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-config |
| `az bicep build` CLI reference | https://learn.microsoft.com/en-us/cli/azure/bicep#az-bicep-build |
| `az deployment sub create` CLI | https://learn.microsoft.com/en-us/cli/azure/deployment/sub#az-deployment-sub-create |
| `az deployment sub what-if` CLI | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-what-if |
| `uniqueString()` function | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-string#uniquestring |
| Azure Verified Modules (AVM) | https://azure.github.io/Azure-Verified-Modules/ |
| AVM Bicep resource modules index | https://azure.github.io/Azure-Verified-Modules/indexes/bicep/bicep-resource-modules/ |
| AVM Bicep pattern modules index | https://azure.github.io/Azure-Verified-Modules/indexes/bicep/bicep-pattern-modules/ |
| ARM API versions per resource type | https://learn.microsoft.com/en-us/azure/templates/ |

### Best Practices

- **Module contracts matter as much as resources** — the outputs drive downstream workflows and composition.
- **Name once, reuse everywhere** — deterministic names reduce review errors and environment drift.
- **Header comments help human review** — they keep module purpose and contract visible at the top of the file.
- **Reject obsolete API versions by default** — old versions quietly remove needed capabilities and policy support.
