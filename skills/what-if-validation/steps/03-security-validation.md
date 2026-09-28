# Step 3 — Security Validation

Requires: [Step 2 — Post-Deployment Checklist](02-post-deployment-checklist.md) passed.

## Network Security

```bash
az network nsg rule list \
  --resource-group $RESOURCE_GROUP \
  --nsg-name $NSG_NAME \
  --output table
```

- [ ] Inbound rules: only port 443 (HTTPS) allowed from internet on app subnets
- [ ] All PaaS services accessed via private endpoint where required
- [ ] No `0.0.0.0/0` allow-all inbound rules on database subnets
- [ ] Storage account public access disabled (if using private endpoint)

## Identity & Access

- [ ] No credentials in source code, environment variables, or app settings
- [ ] No long-lived service principal secrets used (OIDC preferred)
- [ ] RBAC assignments scoped to resource group (not subscription) unless IaC requires it
- [ ] All identities use least-privilege roles (not `Owner` or `Contributor` where narrower roles work)

## Data Encryption

- [ ] Storage accounts: encryption at rest enabled (Azure-managed keys minimum)
- [ ] Database: encryption at rest enabled
- [ ] All HTTPS endpoints: TLS 1.2+ only (no TLS 1.0/1.1)
- [ ] Key Vault: soft delete (90 days) and purge protection enabled

## Compliance Tagging

- [ ] All resources tagged with: `Environment`, `Application`, `Owner`, `CostCenter`
- [ ] Audit logs enabled: Azure Activity Log, Diagnostic settings on Key Vault and Storage
- [ ] No diagnostic settings sending logs to public endpoints

Next: [Step 4 — Performance Validation](04-performance-validation.md).
