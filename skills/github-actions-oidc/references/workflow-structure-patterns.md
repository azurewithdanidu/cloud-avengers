# Workflow Structure Patterns

## File Naming Convention

```
.github/workflows/
  deploy-infra.yml         # Bicep IaC
  deploy-functions.yml     # Azure Functions
  deploy-staticweb.yml     # Static Web Apps
  deploy-containers.yml    # Container Apps / AKS (if applicable)
  validate-pr.yml          # PR validation (lint + what-if, no deploy)
```

## Multi-Environment Trigger Pattern

```yaml
on:
  push:
    branches:
      - main        # → deploy to staging
    paths:
      - 'outputs/azure-functions/**'
      - '.github/workflows/deploy-functions.yml'
  pull_request:
    branches: [main]   # → validate only (no deploy)
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        type: choice
        options: [dev, staging, prod]
```

## Concurrency Control (Prevents Overlapping Deploys)

```yaml
concurrency:
  group: deploy-${{ github.ref }}-${{ inputs.environment || 'auto' }}
  cancel-in-progress: false   # Do NOT cancel in-progress deploys — let them finish
```

## Resource Tagging on Every Deploy

```yaml
- name: Tag deployment
  run: |
    az tag create \
      --resource-id "/subscriptions/${{ secrets.AZURE_SUBSCRIPTION_ID }}/resourceGroups/${{ vars.RESOURCE_GROUP_NAME }}" \
      --tags environment=${{ vars.ENV }} deployedBy=github-actions repo=${{ github.repository }} runId=${{ github.run_id }}
```
