# migration-assessment.md Output File Structure

`outputs/aws-migration-artifacts/migration-assessment.md` must contain all of these sections:

```markdown
# AWS to Azure Migration Assessment

**Assessment Date:** <ISO date>
**Account:** <account_id>
**Assessed By:** AWS Discovery Agent

## Executive Summary
- Total Resources: N
- Services count: N
- Complexity rating: LOW | MEDIUM | HIGH | CRITICAL
- Estimated effort: N weeks (team of N)
- Recommended approach: lift-and-shift modernisation / replatform / rearchitect

## Service Complexity Matrix

| Service | Logical ID | Count | Complexity | Effort (Days) | Risk Flags | Azure Equivalent | Notes |
|---|---|---|---|---|---|---|---|
| Lambda | UploadFunction | 1 | Medium | 3–4 | Custom layer | Azure Functions | Rewrite handler |
| S3 | UploadsBucket | 1 | Low | 1–2 | None | Azure Blob Storage | Config change |

## Dependency Risk Analysis
- Critical path resources (resources that block the most others)
- Cross-service dependency chains
- Network isolation requirements

## Migration Phases (Recommended)

Ordered by dependency (dependencies before dependents):
1. Networking (VPC → VNet, subnets, NSGs)
2. Security (IAM → Managed Identity, Secrets Manager → Key Vault)
3. Storage (S3 → Blob Storage)
4. Database (RDS/DynamoDB → PostgreSQL Flexible/Cosmos DB)
5. Messaging (SQS/SNS → Service Bus/Event Grid)
6. Compute (Lambda → Azure Functions)
7. API Layer (API Gateway → (Azure Functions HTTP trigger / APIM))
8. Monitoring (CloudWatch → Azure Monitor, X-Ray → App Insights)

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Lambda layer re-packaging | Medium | High | Extract to requirements.txt |
| DynamoDB Streams → Change Feed | High | Medium | Use Cosmos DB Change Feed processor |

## Open Questions / Gaps
- [Any service with no clear Azure equivalent]
- [Any information needed from the azure-architect agent]

## Next Steps
1. [Specific, actionable item for azure-architect]
2. [...]
```
