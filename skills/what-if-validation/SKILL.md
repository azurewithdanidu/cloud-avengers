---
name: what-if-validation
description: Run pre-deployment validation (Bicep syntax, policy compliance, quota, what-if) and security checks, then write a full validation report
---


# What-If Validation Skill

## Purpose

Catch dangerous infrastructure changes before they are deployed and verify all pre-deployment conditions are met. Covers Bicep syntax, what-if blocking conditions, policy compliance, quota, security, performance, and cost validation.

## When to Use

Before any Bicep deployment and after deployment to validate the deployed state. Always run what-if first — never skip it even for dev.

---

## ⚠️ Subscription-scope Mandatory Gate

**If `main.bicep` declares `targetScope = 'subscription'`, ALL az deployment commands MUST use `sub create` / `sub what-if`. Using `group create` or `group what-if` on a subscription-scoped template will fail because the resource group does not yet exist at deployment time. This is a hard gate — block deployment if the wrong command is used.**

| Template scope | Correct deploy command | Correct what-if command | FORBIDDEN |
|---|---|---|---|
| `subscription` | `az deployment sub create --location <region>` | `az deployment sub what-if --location <region>` | `az deployment group create/what-if` |
| `resourceGroup` | `az deployment group create --resource-group <rg>` | `az deployment group what-if --resource-group <rg>` | `az deployment sub create/what-if` |

**Detection rule:** Read the first 10 lines of `outputs/bicep-templates/main.bicep`. If `targetScope = 'subscription'` is present, enforce sub-scope commands everywhere. Reject any CI/CD step, script, or agent prompt that uses `group create` or `group validate` against this template.

---


## Process

| Step | File | Runs when |
|---|---|---|
| 1 | [steps/01-pre-deployment-checklist.md](steps/01-pre-deployment-checklist.md) | Before every deployment — Bicep syntax, what-if dry run, policy compliance, quota |
| 2 | [steps/02-post-deployment-checklist.md](steps/02-post-deployment-checklist.md) | After a deployment completes — resource status, connectivity, managed identity, Key Vault access |
| 3 | [steps/03-security-validation.md](steps/03-security-validation.md) | After Step 2 passes — network security, identity & access, encryption, compliance tagging |
| 4 | [steps/04-performance-validation.md](steps/04-performance-validation.md) | After Step 3 passes — response time and throughput vs. AWS baseline |
| 5 | [steps/05-cost-validation.md](steps/05-cost-validation.md) | After Step 4 passes — actual vs. projected cost |

Each step file states its prerequisite and links to the next. Write the final report with
[references/validation-report-template.md](references/validation-report-template.md) once all steps pass.

---

## Rules

- **Never proceed past a blocking what-if condition** without explicit user confirmation.
- **Always run what-if for all three environments** before declaring validation complete.
- **If `main.bicep` is subscription-scoped, always use `az deployment sub what-if` and `az deployment sub create`.** Using `group` variants against a subscription-scoped template is a hard failure — block deployment immediately.
- **Never mark a check `[x] PASS`** unless the underlying validation actually succeeded.
- **Always save what-if JSON output** to `/tmp/whatif-<env>.json` for inspection.
- **The detailed report goes to `outputs/validation-report.md`** — the task plan summary is separate.

## Output

- `outputs/deployment-validation/what-if-report.md` — what-if results per environment (PASS/BLOCKED)
- `outputs/validation-report.md` — full validation report using the template above

---

## Companion Scripts

| Script | Purpose |
|---|---|
| `scripts/run-what-if.ps1` | Full pre-deployment validation gate: syntax → ARM validate → what-if → policy → quota |

Run before every environment deployment:

```powershell
./scripts/run-what-if.ps1 \
    -ResourceGroup "rg-dev-migration" -Environment dev
```

The script blocks on destructive what-if changes (deletes of data resources, `publicNetworkAccess` re-enabled).  It writes `outputs/deployment-validation/what-if-<env>.json` and `what-if-report.md`.

---

## References

### Microsoft / Azure Documentation

| Topic | Link |
|---|---|
| Bicep what-if overview | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-what-if |
| `az deployment sub what-if` CLI | https://learn.microsoft.com/en-us/cli/azure/deployment/sub#az-deployment-sub-what-if |
| `az deployment sub validate` CLI | https://learn.microsoft.com/en-us/cli/azure/deployment/sub#az-deployment-sub-validate |
| `az deployment sub create` CLI | https://learn.microsoft.com/en-us/cli/azure/deployment/sub#az-deployment-sub-create |
| `az bicep build` CLI | https://learn.microsoft.com/en-us/cli/azure/bicep#az-bicep-build |
| Azure Policy overview | https://learn.microsoft.com/en-us/azure/governance/policy/overview |
| `az policy state summarize` CLI | https://learn.microsoft.com/en-us/cli/azure/policy/state#az-policy-state-summarize |
| Azure subscription limits and quotas | https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits |
| Azure Monitor Activity Log | https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/activity-log |
| Azure Security Benchmark | https://learn.microsoft.com/en-us/security/benchmark/azure/introduction |
| Azure Advisor cost recommendations | https://learn.microsoft.com/en-us/azure/advisor/advisor-cost-recommendations |
| `az consumption usage list` CLI | https://learn.microsoft.com/en-us/cli/azure/consumption/usage#az-consumption-usage-list |
| ARM Incremental vs Complete mode | https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-modes |

### Best Practices

- **Always use subscription-scope commands for subscription-scoped templates** — `az deployment sub create/what-if`. For resource-group-scoped module templates use `az deployment group create` with an existing RG. Mixing scopes causes 403 or 404 errors and is a common source of deployment failures.
- **Block on `changeType: Delete` for data resources** — accidental deletion of storage accounts, Key Vaults, or databases is not easily recoverable even with soft-delete enabled.
- **What-if is not a guarantee:** ARM what-if output can differ from actual deployment results in edge cases (e.g., resource provider bugs, concurrent changes). Always review what-if output before approving.
- **Policy compliance must be checked pre-deployment:** Deploying a non-compliant resource in `Deny` policy mode causes a 403 error mid-deployment and leaves the stack in a partial state.

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

