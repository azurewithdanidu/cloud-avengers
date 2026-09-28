# Step 5 — Cost Validation

Requires: [Step 4 — Performance Validation](04-performance-validation.md) passed.

```bash
az consumption usage list \
  --billing-period-name $(az billing period list --query "[0].name" -o tsv) \
  --query "[?resourceGroup=='$RESOURCE_GROUP'].[instanceName,pretaxCost,currency]" \
  --output table
```

- [ ] Actual cost ≤ projected cost + 20% (within first month)
- [ ] No unexpected resource types incurring charges
- [ ] Consumption-plan Functions not charged when idle
- [ ] Storage lifecycle policies applied (Hot → Cool after 30 days)

Once all 5 steps pass, write the final report using
[../references/validation-report-template.md](../references/validation-report-template.md).
