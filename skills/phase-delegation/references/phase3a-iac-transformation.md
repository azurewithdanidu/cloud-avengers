# Phase 3a — IaC Transformation → `@iac-transformation`

**Copy-paste prompt**

```text
You are executing Phase 3a — IaC Transformation for the AWS-to-Azure migration factory.

Inputs:
- outputs/azure-architecture-output/design-document.md
- Read Section 5 (Bicep Module Spec) in full before writing any files.
- Shared task plan: outputs/migration-task-plan.md

Required outputs:
- outputs/bicep-templates/main.<group>.bicep for every group in Section 5
  (main.networking.bicep, main.security.bicep, main.data.bicep, main.monitoring.bicep,
  main.messaging.bicep, main.compute.bicep, or a justified alternative group set)
- outputs/bicep-templates/parameters/dev/<group>.bicepparam for every deployed group
- outputs/bicep-templates/parameters/staging/<group>.bicepparam for every deployed group
- outputs/bicep-templates/parameters/prod/<group>.bicepparam for every deployed group

Requirements:
1. Implement every resource described in Section 5, assigned to its group.
2. No local module files — call AVM modules (`br/public:avm/...`) directly inside each
   main.<group>.bicep. Every group file is subscription-scoped and ensures the resource group.
3. Use `existing` resource lookups (matching naming formula) for cross-group references —
   never module outputs across separate deployments.
4. Use secure defaults, managed identity, and current API versions.
5. Update only your Phase 3a row and Phase 3a task list in outputs/migration-task-plan.md.
6. If Section 5 is incomplete or ambiguous, stop and mark a blocker instead of guessing.
```

**Artifact acceptance checks**

| Path | Minimum assertion |
|---|---|
| `outputs/bicep-templates/main.*.bicep` | At least one grouped orchestrator file exists, each declaring `targetScope = 'subscription'` and containing only AVM module calls (`br/public:avm/...`) — no local `modules/*.bicep` files |
| `outputs/bicep-templates/parameters/dev/` | Contains at least one non-empty `.bicepparam` file per deployed group |
| `outputs/bicep-templates/parameters/staging/` | Contains at least one non-empty `.bicepparam` file per deployed group |
| `outputs/bicep-templates/parameters/prod/` | Contains at least one non-empty `.bicepparam` file per deployed group |
| each `parameters/<env>/<group>.bicepparam` | References its matching `../../main.<group>.bicep` |
