---
name: workflow-generation
description: Generate production-ready GitHub Actions YAML for IaC, Azure Functions, and Static Web App deployments — job structure, artifact handling, and rollback
---


# Workflow Generation Skill

## Purpose

Produce working, secure, idempotent GitHub Actions workflow files that deploy Azure infrastructure and application code across dev/staging/prod environments.

## When to Use

When implementing the workflows specified in `design-document.md` Section 11.

## Inputs

| Path | Why it matters |
|---|---|
| `outputs/azure-architecture-output/design-document.md` | Section 11.1 lists workflows to create; 11.2 defines OIDC config; 11.3 defines per-workflow job/step specs |
| `outputs/bicep-templates/` | IaC artifacts the deploy workflow must reference |
| `outputs/azure-functions/` | Application code the functions deploy workflow must publish |
## Process

1. Read Section 11.1 for the list of workflow files to create.
2. Read Section 11.3 for the per-workflow job/step specification.
3. Apply the patterns below for each workflow type.
4. Pin all action versions explicitly.
5. Write all files under `.github/workflows/`.

**IaC deployment workflow pattern** — there is no single `main.bicep`: deploy every grouped
orchestrator file (`main.networking.bicep`, `main.security.bicep`, `main.data.bicep`,
`main.monitoring.bicep`, `main.messaging.bicep`, `main.compute.bicep`, or whichever groups the
workload uses) in dependency order, each with subscription-scope commands:

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]
    paths: ['outputs/bicep-templates/**']
  workflow_dispatch:
    inputs:
      environment:
        description: Target environment
        required: true
        default: dev
        type: choice
        options: [dev, staging, prod]

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'staging' }}
    steps:
      - uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Validate Bicep (every group file)
        run: |
          for f in outputs/bicep-templates/main.*.bicep; do
            az bicep build --file "$f"
          done

      - name: Deploy every group, in dependency order
        id: deploy
        env:
          ENVIRONMENT: ${{ github.event.inputs.environment || 'staging' }}
        run: |
          set -e
          for GROUP in networking security data monitoring messaging compute; do
            MAIN_BICEP="outputs/bicep-templates/main.${GROUP}.bicep"
            PARAM_FILE="outputs/bicep-templates/parameters/${ENVIRONMENT}/${GROUP}.bicepparam"
            [ -f "$MAIN_BICEP" ] || continue

            echo "=== What-If: $GROUP ==="
            az deployment sub what-if \
              --location ${{ vars.LOCATION }} \
              --template-file "$MAIN_BICEP" \
              --parameters "$PARAM_FILE"

            echo "=== Deploy: $GROUP ==="
            az deployment sub create \
              --name "deploy-${GROUP}-${{ github.run_id }}" \
              --location ${{ vars.LOCATION }} \
              --template-file "$MAIN_BICEP" \
              --parameters "$PARAM_FILE"
          done

      - name: Rollback on failure
        if: failure() && steps.deploy.outcome == 'failure'
        run: |
          # Cancel whichever group's deployment was in flight — name matches deploy-<group>-<run-id>
          az deployment sub list --query "[?starts_with(name, 'deploy-') && contains(name, '${{ github.run_id }}')].name" -o tsv | \
            xargs -I{} az deployment sub cancel --name {} || true
```

**Azure Functions deployment workflow pattern:**

```yaml
name: Deploy Azure Functions

on:
  push:
    branches: [main]
    paths: ['outputs/azure-functions/**']

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: pip install -r outputs/azure-functions/requirements.txt --target .python_packages/lib/site-packages

      - name: Package function app
        run: |
          cd outputs/azure-functions
          zip -r ../../function-app.zip . -x "*.pyc" -x "__pycache__/*"
          cd ../..

      - uses: actions/upload-artifact@v4
        with:
          name: function-app
          path: function-app.zip

      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Deploy to Azure Functions
        run: |
          az functionapp deployment source config-zip \
            --name ${{ vars.FUNCTION_APP_NAME }} \
            --resource-group ${{ vars.RESOURCE_GROUP_NAME }} \
            --src function-app.zip
```

## Rules

- **Always set `permissions: id-token: write`** — without this, OIDC token is not issued.
- **Always pin action versions** — `actions/checkout@v4` not `@latest`. Never use a moving tag.
- **Never put environment-specific values in workflow YAML** — always `${{ secrets.X }}` or `${{ vars.X }}`.
- **Always include a what-if step before any `az deployment sub create`** — never deploy without preview.
- **Deploy every `main.<group>.bicep` in dependency order** (networking → security → data → monitoring → messaging → compute) — never in parallel, and stop the job if an earlier group fails.
- **Always include a rollback step** using `if: failure()` — the step should attempt to cancel the in-flight deployment.
- **Never use `continue-on-error: true`** on deployment steps — fail fast.

## Outputs

- `.github/workflows/deploy-infra.yml` — IaC deployment workflow
- `.github/workflows/deploy-functions.yml` — Function App deployment workflow
- Additional workflows as specified in `design-document.md` Section 11.1

---

## References

### GitHub Documentation

| Topic | Link |
|---|---|
| GitHub Actions workflow syntax | https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions |
| GitHub Actions trigger events | https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows |
| GitHub Actions path filters | https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#onpushpull_requestpull_request_targetpathspaths-ignore |
| GitHub Actions concurrency control | https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#concurrency |
| `actions/checkout` | https://github.com/actions/checkout |
| `actions/setup-python` | https://github.com/actions/setup-python |
| `actions/upload-artifact` | https://github.com/actions/upload-artifact |
| `actions/github-script` | https://github.com/actions/github-script |

### Microsoft / Azure Documentation

| Topic | Link |
|---|---|
| Deploy Azure Functions with GitHub Actions | https://learn.microsoft.com/en-us/azure/azure-functions/functions-how-to-github-actions |
| `Azure/functions-action` | https://github.com/Azure/functions-action |
| Deploy Static Web Apps with GitHub Actions | https://learn.microsoft.com/en-us/azure/static-web-apps/github-actions-workflow |
| `Azure/static-web-apps-deploy` | https://github.com/Azure/static-web-apps-deploy |
| Bicep CI/CD with GitHub Actions | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-github-actions |
| `azure/login` action | https://github.com/Azure/login |
| Azure Function App deployment slots | https://learn.microsoft.com/en-us/azure/azure-functions/functions-deployment-slots |
| Static Web Apps — index.html requirement | https://learn.microsoft.com/en-us/azure/static-web-apps/configuration |

### Best Practices

- **Use `paths:` filters** to avoid triggering infra deployments when only app code changes and vice versa — this reduces unnecessary deployments and pipeline minutes.
- **`cancel-in-progress: false` for deployments** — cancelling a running deployment can leave resources in a partially-provisioned state. Always let in-flight deploys finish.
- **Tag every deployment with `github.run_id`** — this makes it easy to correlate a deployment failure in Azure with the specific GitHub Actions run that caused it.
- **Rollback is not automatic rollback:** `az functionapp deployment slot swap` reverts app code but not infrastructure. If Bicep changes were part of the same deployment, a separate template rollback is needed.
- **SWA deployment token rotation:** The Static Web Apps deployment token does not expire but should be rotated if a team member with access leaves. Regenerate from the Azure portal and update the GitHub secret.

