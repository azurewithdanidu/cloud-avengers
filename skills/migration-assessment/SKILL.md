---
name: migration-assessment
description: Score each AWS service for migration complexity, flag risks, and produce the Service Complexity Matrix in migration-assessment.md
---


# Migration Assessment Skill

## Purpose

Produce a risk-annotated migration assessment report so the azure-architect agent can make informed design decisions and the project manager can sequence work correctly.

## When to Use

After `aws-inventory-scan` is complete and `aws-inventory.json` exists.

## Process

1. Read `outputs/aws-migration-artifacts/aws-inventory.json`.
2. For each service, assign a complexity score using the **Complexity Scoring** section.
3. Flag risk factors using the **Risk Flag Catalogue**.
4. Sequence migration phases using the dependency matrix.
5. Write `outputs/aws-migration-artifacts/migration-assessment.md` using the template below.

---


## Reference Files

| File | Load when |
|---|---|
| [references/complexity-scoring.md](references/complexity-scoring.md) | Scoring effort per service (Lambda, RDS, EKS/ECS, S3, EventBridge/SQS/SNS) and computing the composite LOW/MEDIUM/HIGH/CRITICAL rating |
| [references/risk-flag-catalogue.md](references/risk-flag-catalogue.md) | Flagging known high-risk migration patterns (Lambda layers, DynamoDB Streams, custom VPC, etc.) |
| [references/resource-documentation-template.md](references/resource-documentation-template.md) | Per-resource documentation block used inside `migration-assessment.md` |
| [references/assessment-report-template.md](references/assessment-report-template.md) | Full `migration-assessment.md` file structure (Executive Summary, Service Complexity Matrix, Risk Register, etc.) |

## Rules

- **Never assign Low complexity to any Lambda function** — all Lambda → Functions conversions require at minimum Medium due to handler signature changes.
- **Never omit services from the matrix** — every service in `aws-inventory.json` must appear in the Service Complexity Matrix.
- **Always include a phase sequencing recommendation** — dependencies must come before the services that depend on them.
- **Flag any service with no clear Azure equivalent** as High complexity with a note in "Open Questions / Gaps".
- **Effort estimates must match the scoring tables** — do not invent numbers.

## Scripts

| Script | When to run |
|---|---|
| `./scripts/score-complexity.sh` | Run on Bash/macOS/Linux/WSL after `aws-inventory.json` exists to print a quick complexity summary; it prefers the `Service Complexity Matrix` in `migration-assessment.md` when present. |
| `./scripts/score-complexity.ps1` | Run the same reporting flow on PowerShell 7+ environments, including Windows developer workstations and CI runners. |

## Output

- `outputs/aws-migration-artifacts/migration-assessment.md` — non-empty, contains all required sections

---

## References

### AWS Documentation

| Topic | Link |
|---|---|
| AWS Migration Hub | https://docs.aws.amazon.com/migrationhub/latest/ug/whatishub.html |
| AWS Application Discovery Service | https://docs.aws.amazon.com/application-discovery/latest/userguide/what-is-appdiscovery.html |
| AWS Well-Architected Framework | https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html |
| AWS Lambda pricing | https://aws.amazon.com/lambda/pricing/ |
| Amazon RDS pricing | https://aws.amazon.com/rds/pricing/ |
| Amazon EKS pricing | https://aws.amazon.com/eks/pricing/ |
| Amazon S3 pricing | https://aws.amazon.com/s3/pricing/ |

### Microsoft / Azure Documentation

| Topic | Link |
|---|---|
| Azure Migrate overview | https://learn.microsoft.com/en-us/azure/migrate/migrate-services-overview |
| Azure Well-Architected Framework | https://learn.microsoft.com/en-us/azure/well-architected/ |
| AWS-to-Azure service comparison | https://learn.microsoft.com/en-us/azure/architecture/aws-professional/services |
| Azure architecture center — migration | https://learn.microsoft.com/en-us/azure/architecture/aws-professional/ |

### Best Practices

- **Use AWS Migration Hub** to import discovery data and track migration status across tools.
- **Dependency mapping is mandatory** before scoring complexity — an apparently simple Lambda may depend on 10 services.
- **Always document IAM Permission Boundaries and custom VPC configurations** separately — they are the highest-risk migration blockers.
- **DynamoDB Streams → Cosmos DB Change Feed** is not a 1:1 migration — always flag this as HIGH complexity.
