# Step 1 — Pre-Deployment Checklist

Requires: the subscription-scope gate at the top of `../SKILL.md` has been checked first.

Run every check below **for each `main.<group>.bicep` file** in deployment order (networking → security → data → monitoring → messaging → compute) — there is no single template to validate.

## 1. Bicep Syntax Validation

```bash
# Bicep syntax check — must exit 0, repeat for every group file
for f in outputs/bicep-templates/main.*.bicep; do
  az bicep build --file "$f"
done

# ARM validation — subscription-scoped (each group file creates the resource group idempotently)
az deployment sub validate \
  --location australiaeast \
  --template-file outputs/bicep-templates/main.data.bicep \
  --parameters outputs/bicep-templates/parameters/prod/data.bicepparam
# Expected: validationState: "Valid"
```

**Gate:** Deployment MUST NOT proceed if `az bicep build` exits non-zero for any group file, or if `validate` returns errors for any group file.

## 2. What-If Dry Run

For each environment (dev, staging, prod) **and each group**, run:

```bash
az deployment sub what-if \
  --location australiaeast \
  --template-file outputs/bicep-templates/main.<group>.bicep \
  --parameters outputs/bicep-templates/parameters/<env>/<group>.bicepparam \
  --output json > /tmp/whatif-<group>-<env>.json
```

Parse the output for **blocking conditions** — stop and alert the user if any are found:
- Any operation with `changeType: "Delete"` on a data resource (Storage Account, Key Vault, Database, Service Bus)
- Any change to a role assignment at subscription scope
- Any NSG security rule with `access: "Deny"` being removed
- Any `changeType: "Modify"` on `publicNetworkAccess` from `Disabled` to `Enabled`

Parse for **warning conditions** — log and continue:
- New resources being created (expected)
- Tag changes (expected)
- SKU upgrades (log for cost awareness)
- A downstream group's `existing` lookup resolving against a resource that hasn't deployed yet (fix deployment order, don't ignore)

## 3. Policy Compliance Check

```bash
az policy state summarize --resource-group $RESOURCE_GROUP
# Expected: no resources in "Non-compliant" state for Deny policies
```

Pre-deploy compliance checklist:
- [ ] All resources will have required tags: `Environment`, `Application`, `Owner`, `CostCenter`
- [ ] No public IPs on services that should be private
- [ ] Private endpoints configured for PaaS services requiring network isolation
- [ ] Encryption at rest enabled for all data services
- [ ] Managed Identity configured for all compute resources
- [ ] TLS 1.2+ enforced on all endpoints

## 4. Quota / Service Limit Check

```bash
az provider show --namespace Microsoft.Web \
  --query "resourceTypes[?resourceType=='sites']"
az provider show --namespace Microsoft.Storage \
  --query "resourceTypes[?resourceType=='storageAccounts']"
```

Quota checklist:
- [ ] Storage account count within subscription limit (250 per region)
- [ ] Function App count within region limits
- [ ] Container App environment quota available (if using Container Apps)
- [ ] Database SKU available in target region

Next (after every group deploys successfully, in order): [Step 2 — Post-Deployment Checklist](02-post-deployment-checklist.md).

