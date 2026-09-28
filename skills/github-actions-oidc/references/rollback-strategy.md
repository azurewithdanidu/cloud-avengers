# Rollback Strategy

## Azure Functions — Slot Swap Rollback

```yaml
- name: Rollback Function App
  if: failure()
  run: |
    az functionapp deployment slot swap \
      --resource-group ${{ vars.RESOURCE_GROUP_NAME }} \
      --name ${{ vars.FUNCTION_APP_NAME }} \
      --slot staging \
      --target-slot production
    echo "Rollback complete — production reverted to previous deployment"
```

## Bicep — Redeploy Previous Template

Roll back one group at a time (the group that failed, or every group deployed in this run) —
subscription scope, since each `main.<group>.bicep` creates the resource group itself:

```yaml
- name: Rollback IaC to previous commit
  if: failure()
  run: |
    PREV_SHA=$(git rev-parse HEAD~1)
    GROUP=${{ vars.FAILED_GROUP }}   # e.g. compute — the group that failed
    git show $PREV_SHA:outputs/bicep-templates/main.$GROUP.bicep > /tmp/main-$GROUP-prev.bicep
    az deployment sub create \
      --location ${{ vars.LOCATION }} \
      --template-file /tmp/main-$GROUP-prev.bicep \
      --parameters outputs/bicep-templates/parameters/${{ vars.ENV }}/$GROUP.bicepparam \
      --name "rollback-$GROUP-${{ github.run_id }}"
```

## General Rollback Rules

- Every deployment job must have an `if: failure()` rollback step
- Tag the rollback deployment: `--name "rollback-${{ github.run_id }}"`
- Never use `--no-wait` on deployment commands — wait for completion to detect failures
