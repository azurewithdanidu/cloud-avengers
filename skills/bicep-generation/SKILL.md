---
name: bicep-generation
description: 'Generate secure modular Azure Bicep templates. Use when: writing outputs/bicep-templates/*.bicep, defining module parameters and outputs, applying naming conventions, or validating that IaC matches the architecture design contract.'
---

# Bicep Generation Skill

## Purpose

Produce deployment-ready Azure Bicep that is modular, secure, environment-aware, and explicit enough for human review and automated deployment.

## When to Use

- When translating Section 5 of `design-document.md` into Bicep files
- When reviewing or repairing generated Bicep modules
- When creating environment parameter files for dev, staging, and prod
- When validation finds drift between design and IaC

## Inputs

| Path | Why it matters |
|---|---|
| `outputs/azure-architecture-output/design-document.md` | Source of truth for Section 5 module specifications |
| `outputs/bicep-templates/` | Target output directory |
| `outputs/bicep-templates/modules/` | Target directory for per-module files |
| `outputs/bicep-templates/parameters/` | Target directory for environment parameter files |

## Outputs

| Path | Result |
|---|---|
| `outputs/bicep-templates/main.bicep` | Root orchestration template |
| `outputs/bicep-templates/modules/*.bicep` | One module per infrastructure concern |
| `outputs/bicep-templates/parameters/dev.bicepparam` | Dev parameter file |
| `outputs/bicep-templates/parameters/staging.bicepparam` | Staging parameter file |
| `outputs/bicep-templates/parameters/prod.bicepparam` | Prod parameter file |

## Process

### 1. Start from the architecture contract

1. Read Section 5 of `outputs/azure-architecture-output/design-document.md` in full.
2. List every module required.
3. Assign each module one primary responsibility.
4. Decide which parameters belong in the root template versus module scope.
5. Write the header block, parameters, variables, resources, and outputs in that order.

### 2. Required Bicep file header comment block

Put this header at the top of every `.bicep` file and adjust the values for the specific module:

```bicep
/*
  Module: modules/<file-name>.bicep
  Purpose: <what this module deploys>
  Source: outputs/azure-architecture-output/design-document.md Section 5
  Inputs: <comma-separated parameter names>
  Outputs: resourceId, name, principalId
  Notes: No hardcoded secrets, no inline resource-name interpolation, API versions 2023 or newer
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

- **Naming conventions:** derive every resource name deterministically from `workload`/`environment`/`region` parameters — see [references/naming-conventions.md](references/naming-conventions.md) for the pattern table.
- **Required outputs:** every module must output `resourceId` (string), `name` (string), and `principalId` (string, empty if the module has no identity). Add `hostname`, `endpoint`, `privateEndpointId`, or `connectionSettingName` when relevant.
- **Anti-patterns:** see [references/anti-patterns.md](references/anti-patterns.md) for the full reject list (hardcoded IDs/secrets, old API versions, missing `scope: rg`, etc.).

### 5. Subscription-scope main.bicep pattern (Mandatory)

When main.bicep creates a resource group (the standard pattern for this migration factory), it **MUST** be subscription-scoped — see [references/subscription-scope-pattern.md](references/subscription-scope-pattern.md) for the required `main.bicep` structure, parameter file entries, and correct vs. forbidden deployment commands.

### 6. Example module skeleton

See [references/module-skeleton-example.md](references/module-skeleton-example.md) for a complete child-module example (not `main.bicep`) showing the header block, decorators, naming, and required outputs applied together.

### 7. Validation workflow

1. Ensure every module file has the required header block.
2. Ensure every parameter has `@description`.
3. Ensure any bounded string or enum-like parameter also has `@minLength` or `@allowed` as applicable.
4. Ensure every module emits `resourceId`, `name`, and `principalId`.
5. Ensure main.bicep declares `targetScope = 'subscription'` and that every module call has `scope: rg`.
6. Build and sanity-check the templates using the existing repo or ecosystem validation commands where available.

```bash
# Syntax check
az bicep build --file outputs/bicep-templates/main.bicep

# Subscription-scope what-if (must use sub — not group)
az deployment sub what-if \
  --location australiaeast \
  --template-file outputs/bicep-templates/main.bicep \
  --parameters @outputs/bicep-templates/parameters/dev.bicepparam
```

### 8. Edge Cases / Failure Modes

- **No managed identity on a resource:** still output `principalId` as an empty string to keep the module contract stable.
- **Global naming collision:** introduce a suffix variable or parameter rather than changing the naming scheme ad hoc.
- **One resource type needs an older API version:** escalate to architecture or document the exception explicitly; the default rule is 2023 or newer.
- **Design document omits a required module:** do not invent the module purpose; route the issue back to architecture.
- **Private endpoint requirements absent:** if the security design says private networking is mandatory, treat the omission as a contract issue.

## Rules

- **Every module must have one primary responsibility.**
- **Every public parameter must have `@description`.**
- **Use `@minLength` and `@allowed` whenever the contract implies them.**
- **No inline interpolation in resource names; compute names in variables first.**
- **No API versions older than 2023.**
- **Every module must output `resourceId`, `name`, and `principalId`.**
- **main.bicep MUST declare `targetScope = 'subscription'` when it creates a resource group.** Using `targetScope = 'resourceGroup'` makes `az deployment group create` fail because the group doesn't exist yet.
- **Every module call in main.bicep MUST include `scope: rg`.** Omitting it silently deploys to the wrong scope and causes cryptic errors.
- **Deploy subscription-scoped templates with `az deployment sub create --location <region>`.** Never use `az deployment group create` for templates that create their own resource group.
- **Never use `resourceGroup().location` inside a subscription-scoped template.** Use the `location` parameter instead.

## Best Practices

- Keep root `main.bicep` thin and module-focused.
- Put environment differences in `.bicepparam` files instead of branching inside modules.
- Prefer consistent variable names like `functionAppName`, `serviceBusNamespaceName`, and `keyVaultName`.
- Reuse the same `tags` object across modules for auditability.
- Make module outputs predictable so CI/CD workflows can consume them without file-specific logic.

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
