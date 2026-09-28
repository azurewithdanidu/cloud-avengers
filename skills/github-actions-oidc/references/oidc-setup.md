# OIDC Authentication Setup (One-Time Per Environment)

Document these steps in `outputs/pipeline/setup-oidc.md` for a human with Azure AD permissions to execute:

```bash
# 1. Create app registration
APP_ID=$(az ad app create --display-name "gh-<repo>-<env>" --query appId -o tsv)

# 2. Create service principal
SP_ID=$(az ad sp create --id $APP_ID --query id -o tsv)

# 3. Assign Contributor on the resource group (for app deploys)
az role assignment create \
  --assignee $SP_ID \
  --role "Contributor" \
  --scope /subscriptions/<subscription-id>/resourceGroups/rg-<env>-migration

# 4. Assign User Access Administrator on RG (needed if Bicep creates role assignments)
az role assignment create \
  --assignee $SP_ID \
  --role "User Access Administrator" \
  --scope /subscriptions/<subscription-id>/resourceGroups/rg-<env>-migration

# 5. Create federated credential (repeat for each branch/environment)
az ad app federated-credential create --id $APP_ID --parameters - <<EOF
{
  "name": "gh-actions-<env>",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:<org>/<repo>:environment:<env>",
  "audiences": ["api://AzureADTokenExchange"]
}
EOF

# 6. Note these values for GitHub Secrets:
echo "AZURE_CLIENT_ID = $APP_ID"
echo "AZURE_TENANT_ID = $(az account show --query tenantId -o tsv)"
echo "AZURE_SUBSCRIPTION_ID = $(az account show --query id -o tsv)"
```

## Subject Filter Patterns

| Trigger | Subject string |
|---|---|
| Push to branch `main` | `repo:<org>/<repo>:ref:refs/heads/main` |
| GitHub Environment `prod` | `repo:<org>/<repo>:environment:prod` |
| Pull Request | `repo:<org>/<repo>:pull_request` |

## Required GitHub Secrets

Add these to GitHub Settings → Secrets and Variables → Actions:

| Secret | Scope | Value |
|---|---|---|
| `AZURE_CLIENT_ID` | Repo | App Registration client ID |
| `AZURE_TENANT_ID` | Repo | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Repo | Target subscription ID |
| `STATIC_WEB_APP_TOKEN` | Repo or Environment | SWA deployment token from Bicep output |

## Workflow Permissions Block (Always Include)

```yaml
permissions:
  id-token: write   # Required for OIDC token request
  contents: read
```

## Login Step

```yaml
- name: Azure Login (OIDC)
  uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```
