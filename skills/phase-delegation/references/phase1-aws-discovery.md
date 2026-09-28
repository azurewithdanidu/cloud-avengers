# Phase 1 — AWS Discovery → `@aws-discovery`

**Copy-paste prompt**

```text
You are executing Phase 1 — AWS Discovery for the AWS-to-Azure migration factory.

Inputs:
- AWS Account ID: <AWS_ACCOUNT_ID>
- AWS Region: <AWS_REGION>
- Read-only source application: source-app/
- Shared task plan: outputs/migration-task-plan.md

Required outputs:
- outputs/aws-migration-artifacts/aws-inventory.json
- outputs/aws-migration-artifacts/architecture-diagram.mmd
- outputs/aws-migration-artifacts/dependency-matrix.csv
- outputs/aws-migration-artifacts/migration-assessment.md

Requirements:
1. Use AWS discovery MCP capabilities only. Do not use AWS CLI commands.
2. Read source-app/ and any available documentation before writing outputs.
3. Update only your Phase 1 row and Phase 1 task list in outputs/migration-task-plan.md.
4. Generate all four outputs even if one output reveals blockers.
5. If a blocker prevents a complete discovery, mark Phase 1 as failed and record the blocker in the task plan.
```

**Artifact acceptance checks**

| Path | Minimum assertion |
|---|---|
| `outputs/aws-migration-artifacts/aws-inventory.json` | Exists, non-empty, and contains structured JSON content with at least one discovered service or resource record |
| `outputs/aws-migration-artifacts/architecture-diagram.mmd` | Exists, non-empty, and contains `graph` or `flowchart` |
| `outputs/aws-migration-artifacts/dependency-matrix.csv` | Exists, non-empty, and contains at least two lines (header + one data row) |
| `outputs/aws-migration-artifacts/migration-assessment.md` | Exists, non-empty, and contains at least one `##` heading plus findings or recommendations |
