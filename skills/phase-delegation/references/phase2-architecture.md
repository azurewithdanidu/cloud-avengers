# Phase 2 — Architecture → `@azure-architect`

**Copy-paste prompt**

```text
You are executing Phase 2 — Architecture Design for the AWS-to-Azure migration factory.

Inputs:
- AWS Account ID: <AWS_ACCOUNT_ID>
- AWS Region: <AWS_REGION>
- outputs/aws-migration-artifacts/aws-inventory.json
- outputs/aws-migration-artifacts/architecture-diagram.mmd
- outputs/aws-migration-artifacts/dependency-matrix.csv
- outputs/aws-migration-artifacts/migration-assessment.md
- Read-only source application: source-app/
- Shared task plan: outputs/migration-task-plan.md

Required outputs:
- outputs/azure-architecture-output/design-document.md
- outputs/azure-architecture-output/architecture-diagram-azure.mmd
- outputs/azure-architecture-output/cost-comparison.md
- outputs/azure-architecture-output/service-mapping.md

Requirements:
1. Read every discovery artifact before writing anything.
2. Write outputs/azure-architecture-output/design-document.md first.
3. The design document must include all 11 required sections:
   1. Executive Summary
   2. Current State
   3. Service Mapping
   4. Target Architecture
   5. Bicep Module Spec
   6. Function Rewrite Spec
   7. Security Design
   8. Networking Design
   9. Monitoring Design
   10. Cost Estimate
   11. CI/CD Spec
4. Update only your Phase 2 row and Phase 2 task list in outputs/migration-task-plan.md.
5. Make the design document explicit enough that Phase 3 and Phase 4 can proceed without rediscovery.
```

**Artifact acceptance checks**

| Path | Minimum assertion |
|---|---|
| `outputs/azure-architecture-output/design-document.md` | Exists, non-empty, and contains all 11 required section headings exactly once or more |
| `outputs/azure-architecture-output/architecture-diagram-azure.mmd` | Exists, non-empty, contains Mermaid syntax, and includes at least one `subgraph` |
| `outputs/azure-architecture-output/cost-comparison.md` | Exists, non-empty, and contains a monthly summary table plus break-even analysis |
| `outputs/azure-architecture-output/service-mapping.md` | Exists, non-empty, and contains a table with AWS and Azure mapping columns |
