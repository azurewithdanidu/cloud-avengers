---
name: github-actions-oidc
description: Configure OIDC/Workload Identity Federation, workflow structure patterns, concurrency, SWA deployment, rollback strategy, and quality gates for GitHub Actions → Azure pipelines
---


# GitHub Actions OIDC Skill

## Purpose

Set up Azure Workload Identity Federation and produce production-ready GitHub Actions workflows that deploy to Azure using short-lived OIDC tokens — no service principal secrets stored in GitHub.

## When to Use

Before writing any GitHub Actions workflow that deploys to Azure.

**When NOT to use:**
- Do not run `scripts/setup-oidc.*` without explicit approval from someone holding Azure AD
  Application Administrator and RBAC assignment permissions — it creates an app registration,
  service principal, federated credential, and resource-group role assignments. This is a
  one-time, privileged, human-approved bootstrap step, not an unattended part of pipeline generation.
- Do not use this skill to grant `Owner` or subscription-scoped roles — see Rules below.

---

## Inputs

| Path | Why it matters |
|---|---|
| `outputs/azure-architecture-output/design-document.md` | Section 11 defines the CI/CD spec: workflow files, OIDC environment names, and deployment targets |
| `outputs/bicep-templates/` | IaC artifacts the workflows must deploy |
| `outputs/azure-functions/` | Application code the workflows must build and publish |

## Process

1. Read `design-document.md` Section 11.1 for the list of workflows to create.
2. Set up OIDC for each GitHub Environment using the **OIDC Authentication Setup** steps below.
3. Apply the **Workflow Structure Patterns** for each workflow type.
4. Pin all action versions explicitly.
5. Validate that every workflow references a named GitHub Environment, not a raw secret.
6. Write all files under `.github/workflows/`.

---
## OIDC Authentication Setup (One-Time Per Environment)

## Reference Files

Load only the file relevant to the current task — do not load all of them:

| File | Load when |
|---|---|
| [references/oidc-setup.md](references/oidc-setup.md) | Bootstrapping OIDC for a new environment: app registration, federated credential, required GitHub secrets, login step |
| [references/workflow-structure-patterns.md](references/workflow-structure-patterns.md) | Naming new workflow files, setting up multi-environment triggers, concurrency control, or deployment tagging |
| [references/static-web-apps-deployment.md](references/static-web-apps-deployment.md) | Writing a Static Web Apps deployment job |
| [references/rollback-strategy.md](references/rollback-strategy.md) | Adding a rollback step to a deployment job (Functions slot swap or Bicep redeploy) |
| [references/pr-validation-workflow.md](references/pr-validation-workflow.md) | Writing the PR validation workflow (lint + what-if, no deploy) |
| [references/action-version-pinning.md](references/action-version-pinning.md) | Checking or updating `uses:` version pins in any workflow |

---

## Rules

- **Never use client secrets or certificates** — OIDC federated credentials only.
- **Never assign Owner or User Access Administrator at subscription scope** — scope to the resource group.
- **Always add a separate federated credential per branch/environment** that needs to deploy.
- **Always set `permissions: id-token: write`** — without it, the OIDC token is not issued.
- **Never store `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, or `AZURE_SUBSCRIPTION_ID` as environment-level secrets** — these are shared and belong as repo-level secrets.
- **Never auto-deploy to prod on push** — require manual `workflow_dispatch` with approval gate.
- **Never hardcode resource group names or resource names in workflow YAML** — always use `${{ vars.RESOURCE_GROUP_NAME }}` or equivalent.
- **Always pin action versions** — never use `@latest` or a moving tag.

## Outputs

- `outputs/pipeline/setup-oidc.md` — exact `az` commands for human to run
- `outputs/pipeline/setup-environments.md` — GitHub Environment protection rules to configure
- Every workflow file uses `azure/login@v2` with OIDC parameters
- GitHub secrets documented in `design-document.md` Section 11.2

---

## Scripts

| Script | Purpose |
|---|---|
| `scripts/setup-oidc.ps1` | Creates App Registration, Service Principal, federated credential, and RBAC assignments |
| `scripts/setup-oidc.sh` | Bash equivalent of the above |

**Approval gate:** this script performs multiple privileged, mutating operations (`az ad app
create`, `az ad sp create`, `az role assignment create`, `az ad app federated-credential create`).
Document the intended command in `outputs/pipeline/setup-oidc.md` first and get explicit user
confirmation of the org, repo, environment, subscription, and resource group before running it.
Run once per environment before creating GitHub workflows:

```powershell
./scripts/setup-oidc.ps1 \
    -GitHubOrg "azurewithdanidu" \
    -GitHubRepo "ai-assisted-aws-to-azure-migration" \
    -Environment prod \
    -Subscription "<subscription-id>" \
    -ResourceGroup "rg-prod-migration"
```

The script prints the three GitHub Secrets values (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`) and writes `outputs/pipeline/setup-oidc.md`.

---

## References

### GitHub Documentation

| Topic | Link |
|---|---|
| About OIDC security hardening | https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect |
| Configuring OIDC in Azure | https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-azure |
| GitHub Actions permissions | https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#permissions |
| GitHub Actions concurrency | https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#concurrency |
| Encrypted secrets in GitHub Actions | https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions |
| GitHub Actions OIDC subject claims | https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect#understanding-the-oidc-token |

### Microsoft / Azure Documentation

| Topic | Link |
|---|---|
| Azure Workload Identity Federation | https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation |
| Configure federated identity credential | https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust |
| `azure/login` GitHub Action | https://github.com/Azure/login |
| `Azure/functions-action` | https://github.com/Azure/functions-action |
| `Azure/static-web-apps-deploy` | https://github.com/Azure/static-web-apps-deploy |
| Least-privilege OIDC setup | https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect |
| `az ad app federated-credential` CLI | https://learn.microsoft.com/en-us/cli/azure/ad/app/federated-credential |
| GitHub Actions OIDC with Azure tutorial | https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure |

### Best Practices

- **One federated credential per branch/environment** — never use a wildcard subject like `repo:*:*`. Scope to `environment:prod` or `ref:refs/heads/main` to limit blast radius.
- **Scope role assignments to resource group, not subscription** — `Contributor` at subscription scope grants access to all resources in the subscription. Scope to `rg-<env>-migration` only.
- **`User Access Administrator` is required when Bicep creates role assignments** — this allows the pipeline to assign RBAC roles to managed identities as part of IaC deployment.
- **Pin action versions to full SHA for highest security** — tag-based pinning (`@v2`) is vulnerable to tag mutation attacks. Use commit SHA pinning in production pipelines.

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
