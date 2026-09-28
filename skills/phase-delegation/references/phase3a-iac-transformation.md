# Phase 3a — IaC Transformation → `@iac-transformation`

**Copy-paste prompt**

```text
You are executing Phase 3a — IaC Transformation for the AWS-to-Azure migration factory.

Inputs:
- outputs/azure-architecture-output/design-document.md
- Read Section 5 (Bicep Module Spec) in full before writing any files.
- Shared task plan: outputs/migration-task-plan.md

Required outputs:
- outputs/bicep-templates/main.bicep
- outputs/bicep-templates/modules/<module>.bicep for every module in Section 5
- outputs/bicep-templates/parameters/dev.bicepparam
- outputs/bicep-templates/parameters/staging.bicepparam
- outputs/bicep-templates/parameters/prod.bicepparam

Requirements:
1. Implement every module described in Section 5.
2. Keep main.bicep as the orchestration template and put implementation details in modules/.
3. Use secure defaults, managed identity, and current API versions.
4. Update only your Phase 3a row and Phase 3a task list in outputs/migration-task-plan.md.
5. If Section 5 is incomplete or ambiguous, stop and mark a blocker instead of guessing.
```

**Artifact acceptance checks**

| Path | Minimum assertion |
|---|---|
| `outputs/bicep-templates/main.bicep` | Exists, non-empty, and contains at least one `module` declaration or root orchestration logic |
| `outputs/bicep-templates/modules/` | Contains at least one non-empty `.bicep` file |
| `outputs/bicep-templates/parameters/dev.bicepparam` | Exists, non-empty, and references `main.bicep` |
| `outputs/bicep-templates/parameters/staging.bicepparam` | Exists and is non-empty |
| `outputs/bicep-templates/parameters/prod.bicepparam` | Exists and is non-empty |
