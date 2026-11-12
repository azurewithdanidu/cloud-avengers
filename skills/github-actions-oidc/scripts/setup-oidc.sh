#!/usr/bin/env bash
# setup-oidc.sh — Create an Azure App Registration with Workload Identity Federation
#                 for GitHub Actions OIDC deployments.  No service principal secrets.
#
# Usage:
#   ./setup-oidc.sh <github-org> <github-repo> <environment> <subscription-id> <resource-group>
#
# Example:
#   ./setup-oidc.sh azurewithdanidu ai-assisted-aws-to-azure-migration prod \
#       00000000-0000-0000-0000-000000000000 rg-prod-migration
#
# Prerequisites: az login, jq

set -euo pipefail

GITHUB_ORG="${1:?Arg 1 required: GitHub org}"
GITHUB_REPO="${2:?Arg 2 required: GitHub repo}"
ENVIRONMENT="${3:?Arg 3 required: GitHub environment (dev|staging|prod)}"
SUBSCRIPTION="${4:?Arg 4 required: Azure subscription ID}"
RESOURCE_GROUP="${5:?Arg 5 required: Azure resource group}"

APP_NAME="gh-${GITHUB_REPO}-${ENVIRONMENT}"
SCOPE="/subscriptions/${SUBSCRIPTION}/resourceGroups/${RESOURCE_GROUP}"

case "$ENVIRONMENT" in
  dev|staging|prod) ;;
  *) echo "ERROR: Environment must be dev, staging, or prod." >&2; exit 1 ;;
esac
echo "OIDC bootstrap: ${GITHUB_ORG}/${GITHUB_REPO}, environment ${ENVIRONMENT}, scope ${SCOPE}"
echo "Creates an app, service principal, federated credential, Contributor and User Access Administrator assignments."
if [[ ! -t 0 ]]; then
  echo "ERROR: Interactive human confirmation is required; OIDC bootstrap was not started." >&2
  exit 1
fi
read -r -p "Type APPROVE to bootstrap OIDC; any other response cancels: " CONFIRMATION
if [[ "$CONFIRMATION" != "APPROVE" ]]; then
  echo "ERROR: OIDC bootstrap cancelled." >&2
  exit 1
fi

echo "==> Creating app registration: ${APP_NAME}"
APP_ID=$(az ad app create --display-name "${APP_NAME}" --query appId -o tsv)
echo "    App ID (client ID): ${APP_ID}"

echo "==> Creating service principal"
SP_ID=$(az ad sp create --id "${APP_ID}" --query id -o tsv)
echo "    SP Object ID: ${SP_ID}"

echo "==> Assigning Contributor on ${RESOURCE_GROUP}"
az role assignment create \
  --assignee "${SP_ID}" \
  --role "Contributor" \
  --scope "${SCOPE}"

echo "==> Assigning User Access Administrator on ${RESOURCE_GROUP}"
echo "    (required for Bicep to create RBAC role assignments)"
az role assignment create \
  --assignee "${SP_ID}" \
  --role "User Access Administrator" \
  --scope "${SCOPE}"

echo "==> Creating federated credential for environment: ${ENVIRONMENT}"
az ad app federated-credential create --id "${APP_ID}" --parameters - <<EOF
{
  "name": "gh-actions-${ENVIRONMENT}",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:${GITHUB_ORG}/${GITHUB_REPO}:environment:${ENVIRONMENT}",
  "audiences": ["api://AzureADTokenExchange"]
}
EOF

TENANT_ID=$(az account show --query tenantId -o tsv)

echo ""
echo "==> DONE. Add these values as GitHub repository secrets:"
echo ""
echo "    AZURE_CLIENT_ID       = ${APP_ID}"
echo "    AZURE_TENANT_ID       = ${TENANT_ID}"
echo "    AZURE_SUBSCRIPTION_ID = ${SUBSCRIPTION}"
echo ""
echo "    Environment-level variable:"
echo "    RESOURCE_GROUP_NAME   = ${RESOURCE_GROUP}"
echo ""
echo "    See outputs/pipeline/setup-oidc.md for full instructions."
