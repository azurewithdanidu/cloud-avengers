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

```yaml
- name: Rollback IaC to previous commit
  if: failure()
  run: |
    PREV_SHA=$(git rev-parse HEAD~1)
    git show $PREV_SHA:outputs/bicep-templates/main.bicep > /tmp/main-prev.bicep
    az deployment group create \
      --resource-group ${{ vars.RESOURCE_GROUP_NAME }} \
      --template-file /tmp/main-prev.bicep \
      --parameters outputs/bicep-templates/parameters/${{ vars.ENV }}.bicepparam \
      --name "rollback-${{ github.run_id }}"
```

## General Rollback Rules

- Every deployment job must have an `if: failure()` rollback step
- Tag the rollback deployment: `--name "rollback-${{ github.run_id }}"`
- Never use `--no-wait` on deployment commands — wait for completion to detect failures
