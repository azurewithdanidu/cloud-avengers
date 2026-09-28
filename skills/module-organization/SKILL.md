---
name: module-organization
description: Decide what belongs in root main.bicep vs child modules, AVM module selection, dependency ordering, and how to avoid circular dependencies and common Bicep pitfalls
---


# Module Organization Skill

## Purpose

Structure Bicep templates into focused, reusable modules with clear boundaries so the deployment is maintainable, testable, and free of circular dependencies. Incorporates AVM (Azure Verified Modules) selection guidance.

## When to Use

Before writing any Bicep file — this skill defines the file structure and AVM module choices that all other IaC work follows.

## Process

1. **Configure `bicepconfig.json`** — mandatory first step: [steps/01-configure-bicepconfig.md](steps/01-configure-bicepconfig.md).
2. Read `outputs/azure-architecture-output/design-document.md` Section 5 for the full module list.
3. **Select AVM modules** using the decision tree: [steps/02-select-avm-modules.md](steps/02-select-avm-modules.md).
4. **Resolve module versions** and lay out module files: [steps/03-resolve-module-versions.md](steps/03-resolve-module-versions.md).
5. Create one module file per logical resource group.
6. Write `main.bicep` with parameters, module calls, and outputs only.
7. Run the pitfalls check before declaring templates complete: [steps/04-pitfalls-checklist.md](steps/04-pitfalls-checklist.md).

Each step file states its own prerequisites and links to the next step — follow them in order on first use of this skill; jump directly to the relevant step file when only one stage needs revisiting.

---


## Step & Reference Index

| File | Purpose |
|---|---|
| [steps/01-configure-bicepconfig.md](steps/01-configure-bicepconfig.md) | Mandatory `bicepconfig.json` module alias setup |
| [steps/02-select-avm-modules.md](steps/02-select-avm-modules.md) | Pattern vs resource module decision tree |
| [steps/03-resolve-module-versions.md](steps/03-resolve-module-versions.md) | Version resolution, restore/build validation, module file layout |
| [steps/04-pitfalls-checklist.md](steps/04-pitfalls-checklist.md) | 8-point pre-completion checklist (Linux plan config, naming limits, scope rules) |
| [references/aws-to-avm-module-mapping.md](references/aws-to-avm-module-mapping.md) | AWS service → Azure service → AVM module catalog, by category |
| [references/cloudformation-to-bicep-mapping.md](references/cloudformation-to-bicep-mapping.md) | CloudFormation/SAM syntax → Bicep syntax equivalence table |

---

## Rules

- **Never put resources directly in `main.bicep`** — use modules only.
- **Never create circular module dependencies** — if A needs B and B needs A, extract the shared resource into a third module.
- **Never create a module that exceeds ~150 lines** — split it.
- **Always output `resourceId`, `resourceName`, and `principalId`** (where applicable) from every module.
- **Use output references not `dependsOn`** wherever possible — output references are self-documenting.
- **Use `dependsOn` explicitly** only when the dependency exists but is not expressed through an output reference.
- **Every resource must use an AVM module** (`br/public:avm/res/...` or `br/public:avm/ptn/...`) — no raw `resource` declarations unless no AVM module exists.
- **Never vendor or copy AVM source into the repo** — reference modules via `br/public:avm/...`.
- **Cite the AVM module** in `outputs/bicep-templates/README.md` for each resource: "Selected per module-organization skill — `avm/res/storage/storage-account:0.32.0`".

## Output

- `outputs/bicep-templates/bicepconfig.json` — present with `modulePath: "bicep"`
- `outputs/bicep-templates/main.bicep` — contains only parameters, module declarations, and outputs
- `outputs/bicep-templates/modules/*.bicep` — one file per logical resource group, each under ~150 lines
- `az bicep restore --file outputs/bicep-templates/main.bicep --force` exits 0
- `az bicep build --file outputs/bicep-templates/main.bicep` exits 0

---

## Companion Scripts

| Script | Purpose |
|---|---|
| `scripts/resolve-avm-version.ps1` | Resolves the latest published version tag for any AVM module from its CHANGELOG |
| `scripts/resolve-avm-version.sh` | Bash equivalent of the above |
| `scripts/validate-bicep.ps1` | Runs `az bicep restore` + `az bicep build` on every `.bicep` file; optionally runs what-if per environment |

Agents should run `validate-bicep.ps1` immediately after generating or modifying any Bicep file:

```powershell
./scripts/validate-bicep.ps1 \
    -ResourceGroup "rg-dev-migration" -Environment dev
```

Look up the correct AVM module version before pinning it in a `.bicepparam`:

```powershell
./scripts/resolve-avm-version.ps1 \
    -ModulePath "storage/storage-account"
```

---

## References

### Microsoft / Azure Documentation

| Topic | Link |
|---|---|
| Azure Verified Modules (AVM) home | https://azure.github.io/Azure-Verified-Modules/ |
| AVM Bicep resource modules index | https://azure.github.io/Azure-Verified-Modules/indexes/bicep/bicep-resource-modules/ |
| AVM Bicep pattern modules index | https://azure.github.io/Azure-Verified-Modules/indexes/bicep/bicep-pattern-modules/ |
| AVM versioning and changelog guidance | https://azure.github.io/Azure-Verified-Modules/specs/shared/versioning/ |
| Bicep modules documentation | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/modules |
| bicepconfig.json module aliases | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-config-modules |
| `az bicep restore` command | https://learn.microsoft.com/en-us/cli/azure/bicep#az-bicep-restore |
| ARM role assignment resource | https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments |
| CloudFormation to Bicep migration | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/migrate-template |
| Bicep dependency management | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/resource-dependencies |
| Azure deployment scopes | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-to-subscription |

### AWS Documentation

| Topic | Link |
|---|---|
| CloudFormation resource type reference | https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html |
| CloudFormation intrinsic function reference | https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html |
| SAM resource and property reference | https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-specification-resources-and-properties.html |

### Best Practices

- **Always run `az bicep restore --force` before `az bicep build`** — AVM module references require the cache to be populated first; the build will fail with `artifact does not exist` if the cache is stale.
- **`modulePath: "bicep"` in bicepconfig.json is the only correct value** — `"bicep/public"` does not exist in MCR and causes a confusing registry error.
- **Append `Avm` to all inner AVM module `name:` values** — duplicate deployment IDs cause ARM 409 conflicts when the same name is used at both the outer and inner module level.
- **Always validate breaking changes** between AVM versions before upgrading — check the CHANGELOG at `https://raw.githubusercontent.com/Azure/bicep-registry-modules/main/avm/res/<module>/CHANGELOG.md`.

---

## Runtime Detection

This skill supports both Bash and PowerShell. Use the following detection order:

| Priority | Runtime | Condition | Script |
|---|---|---|---|
| 1 (preferred) | Bash | `curl` and `jq` available on PATH | `scripts/<name>.sh` |
| 2 | PowerShell 7+ | `pwsh` available on PATH | `scripts/<name>.ps1` |
| 3 (fallback) | Windows PowerShell 5.1 | `powershell.exe` available | `scripts/<name>.ps1 -ExecutionPolicy RemoteSigned` |

**Detection snippet (Bash):**
```bash
if command -v curl &>/dev/null && command -v jq &>/dev/null; then
  bash scripts/<name>.sh [args]
elif command -v pwsh &>/dev/null; then
  pwsh -File scripts/<name>.ps1 [args]
elif command -v powershell.exe &>/dev/null; then
  powershell.exe -ExecutionPolicy RemoteSigned -File scripts/<name>.ps1 [args]
else
  echo "ERROR: Requires curl+jq (Bash) or PowerShell 7+ (pwsh)"
  exit 1
fi
```

**Parameter naming convention:** Bash uses `--kebab-case`; PowerShell uses `-PascalCase`. Both produce identical output.

