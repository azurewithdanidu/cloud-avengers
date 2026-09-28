# Step 2 — AVM Module Selection Decision Tree

Requires: [Step 1 — bicepconfig.json](01-configure-bicepconfig.md) already in place.

```
Is there an AVM ptn/ (pattern) module that covers the full scenario?
  YES → Use ptn/ module (preferred — bundles networking, RBAC, monitoring wiring)
  NO  → Is there an AVM res/ (resource) module for the Azure service?
          YES → Use res/ module
          NO  → Write raw Bicep resource declaration
```

Look up the AWS service being replaced and its AVM module in
[references/aws-to-avm-module-mapping.md](../references/aws-to-avm-module-mapping.md).

Next: [Step 3 — Resolve Module Versions](03-resolve-module-versions.md)
