---
name: cost-analysis
description: 'Produce a defendable AWS-versus-Azure cost model. Use when: generating outputs/azure-architecture-output/cost-comparison.md, estimating unknown AWS costs, calculating egress or reservation scenarios, or computing break-even and ROI for the migration.'
---

# Cost Analysis Skill

## Purpose

Create a transparent, evidence-based cost comparison that shows current AWS spend, projected Azure spend, migration one-time cost, break-even timing, reservation scenarios, and the assumptions behind every number.

## When to Use

- After the architecture design defines the target Azure services
- When writing `outputs/azure-architecture-output/cost-comparison.md`
- When current AWS billing data is incomplete and must be estimated from technical evidence
- When stakeholders need pay-as-you-go versus reservation scenarios

## Inputs

| Path | Why it matters |
|---|---|
| `outputs/aws-migration-artifacts/aws-inventory.json` | Source workload inventory for AWS baseline estimation |
| `outputs/aws-migration-artifacts/migration-assessment.md` | Traffic, scale, and risk assumptions |
| `outputs/azure-architecture-output/design-document.md` | Section 10 target-cost assumptions and Section 3 mapping |
| `source-app/doc/` | Existing billing exports, architecture notes, or runbooks |

## Outputs

| Path | Result |
|---|---|
| `outputs/azure-architecture-output/cost-comparison.md` | Complete cost comparison artifact |

## Process

### 1. Build the AWS baseline

1. Look for actual cost exports or documented monthly spend in `source-app/doc/`.
2. If real cost data exists, use it as the primary baseline.
3. If real cost data is incomplete, estimate missing services from `aws-inventory.json` and the source architecture.
4. Record every missing-data assumption in the cost report.


### 2. Estimate unknown AWS costs

See [references/cost-formulas.md](references/cost-formulas.md) for the fallback estimation formulas by AWS service (EC2, Lambda, S3, RDS, DynamoDB, NAT Gateway, CloudWatch) when actual billing data is unavailable.

### 3. Azure monthly costing workflow

1. Map each AWS service to the Azure target service from `design-document.md` Section 3.
2. Use current Azure pricing sources for the chosen service tier.
3. Show at least one pay-as-you-go scenario.
4. Show reservation scenarios when the service is eligible and the workload has a stable baseline.
5. Include egress and ancillary costs such as monitoring, DNS, and Front Door where applicable.


### 4-6. Egress, reservation, and break-even formulas

See [references/cost-formulas.md](references/cost-formulas.md) for the data egress cost formulas, Azure Reservations savings calculations, and the break-even formula — each with a worked example.

### 7. Complete `cost-comparison.md` template

Use the full template in [references/cost-comparison-template.md](references/cost-comparison-template.md) for `outputs/azure-architecture-output/cost-comparison.md`.

### 8. Edge Cases / Failure Modes

- **Shared AWS account costs:** allocate only the migration workload share and document the allocation method.
- **Bursty traffic:** show at least expected and peak scenarios for Functions or event-driven costs.
- **Missing network volume data:** estimate from request volume and average payload size, then document the formula.
- **Unsupported reservation for a service:** leave it in PAYG and explain why.
- **Azure architecture still changing:** do not finalize a cost recommendation until the target service list is stable enough to compare.

## Rules

- **Never use placeholders such as `$X` or `TBD` in the final cost report.**
- **Always include egress and transfer costs.**
- **Always state whether a number is actual, estimated, or modeled.**
- **Always compute break-even explicitly when migration cost is known.**
- **Always show reservation scenarios when eligible baseline spend exists.**

## Best Practices

- Keep the pricing date visible so readers know when to refresh the analysis.
- Separate one-time migration cost from monthly run cost; mixing them obscures break-even.
- Use a sensitivity range when traffic or storage growth is uncertain.
- Keep the cost report aligned with Section 10 of the design document and the service mapping table.
- Treat unknown AWS costs as an estimation problem, not a reason to omit a line item.

---

## References

### Microsoft / Azure Documentation

| Topic | Link |
|---|---|
| Azure Pricing Calculator | https://azure.microsoft.com/en-us/pricing/calculator/ |
| Azure Retail Prices API | https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices |
| Azure Functions pricing | https://azure.microsoft.com/en-us/pricing/details/functions/ |
| Azure Blob Storage pricing | https://azure.microsoft.com/en-us/pricing/details/storage/blobs/ |
| Azure Service Bus pricing | https://azure.microsoft.com/en-us/pricing/details/service-bus/ |
| Azure Database for PostgreSQL pricing | https://azure.microsoft.com/en-us/pricing/details/postgresql/flexible-server/ |
| Azure Cosmos DB pricing | https://azure.microsoft.com/en-us/pricing/details/cosmos-db/autoscale-provisioned/ |
| Azure Front Door pricing | https://azure.microsoft.com/en-us/pricing/details/frontdoor/ |
| Azure DNS pricing | https://azure.microsoft.com/en-us/pricing/details/dns/ |
| Azure Cost Management overview | https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/overview-cost-management |
| Azure Reservations (savings vs pay-as-you-go) | https://learn.microsoft.com/en-us/azure/cost-management-billing/reservations/save-compute-costs-reservations |

### AWS Documentation

| Topic | Link |
|---|---|
| AWS Pricing Calculator | https://calculator.aws/pricing/2/home |
| AWS Lambda pricing | https://aws.amazon.com/lambda/pricing/ |
| Amazon S3 pricing | https://aws.amazon.com/s3/pricing/ |
| Amazon RDS pricing | https://aws.amazon.com/rds/pricing/ |
| Amazon DynamoDB pricing | https://aws.amazon.com/dynamodb/pricing/ |
| AWS Cost Explorer | https://aws.amazon.com/aws-cost-management/aws-cost-explorer/ |
| AWS data transfer pricing | https://aws.amazon.com/ec2/pricing/on-demand/#Data_Transfer |

### Best Practices

- **Model the network explicitly** — egress surprises destroy confidence in otherwise solid comparisons.
- **Document estimate provenance** — each line item should say whether it came from billing data, architecture evidence, or a pricing calculator assumption.
- **Show commitment options separately** — reserved pricing improves the business case only when the workload is stable enough to justify it.
- **A cost report is a decision memo, not just a table** — include recommendation, risk, and next validation step.
