# Phase 4 — Validation → `@deployment-validation`

**Copy-paste prompt**

```text
You are executing Phase 4 — Validation for the AWS-to-Azure migration factory.

Inputs:
- outputs/azure-architecture-output/design-document.md
- outputs/azure-architecture-output/architecture-diagram-azure.mmd
- outputs/azure-architecture-output/cost-comparison.md
- outputs/bicep-templates/
- outputs/azure-functions/
- .github/workflows/
- Shared task plan: outputs/migration-task-plan.md

Required output:
- outputs/validation-report.md

Requirements:
1. Validate the generated solution against the architecture, security, networking, monitoring, and CI/CD specifications in the design document.
2. Confirm that the report begins with either `## Status: PASSED` or `## Status: FAILED`.
3. Summarize what was checked, what passed, what failed, and what must be remediated next.
4. Update only your Phase 4 row and Phase 4 task list in outputs/migration-task-plan.md.
5. If prerequisite artifacts are missing, mark the phase as failed and name the missing prerequisite explicitly.
```

**Artifact acceptance checks**

| Path | Minimum assertion |
|---|---|
| `outputs/validation-report.md` | Exists, non-empty, and begins with `## Status: PASSED` or `## Status: FAILED` |
| `outputs/validation-report.md` | Contains a summary of checks performed and remediation notes for failures |
