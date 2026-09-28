# Complexity Scoring

## Effort Estimates by Service

**Lambda Functions:**

| Tier | Criteria | Effort |
|---|---|---|
| Basic | Reads S3 only, no VPC, no layers | 2 days |
| Standard | S3 + DynamoDB, standard triggers | 3–4 days |
| Complex | Multiple services, VPC, custom layers | 5–7 days |
| Very Complex | EKS integration, custom runtime, custom libraries | 8–10 days |

**RDS Databases:**

| Tier | Criteria | Effort |
|---|---|---|
| Small | < 10 GB | 2–3 days |
| Medium | 10–100 GB | 4–7 days |
| Large | > 100 GB | 8–14 days |
| Modifier | Multi-AZ or read replicas | +2–3 days |
| Modifier | Custom parameter group | +1–2 days each |

**EKS / ECS:**

| Tier | Criteria | Effort |
|---|---|---|
| Small | 1–3 nodes / 1–3 pods | 5–7 days |
| Medium | 4–10 nodes / 4–10 pods | 10–15 days |
| Large | 10+ nodes / 10+ pods | 15–20 days |

**S3 Buckets:**

| Tier | Criteria | Effort |
|---|---|---|
| Simple | No special configuration | 1–2 days |
| Versioning + replication | Multi-region or cross-account | 3–5 days |
| Lifecycle policies | Tiered storage transitions | 4–6 days |
| Public / static web hosting | Static site, presigned URLs | 2–3 days |

**EventBridge / SQS / SNS:**

| Tier | Criteria | Effort |
|---|---|---|
| Minimal | 1–2 rules/queues/topics | 1–2 days |
| Standard | 3–5 rules/queues/topics | 2–4 days |
| Moderate | 6–10 rules/queues/topics | 4–6 days |
| Complex | 10+ rules or complex routing/filtering | 6–8 days |

## Composite Complexity Ratings

```
LOW (1–2 weeks total):
- Simple CRUD operations
- Single Lambda + standard DB
- No complex integrations
- < 5 dependencies per resource

MEDIUM (3–5 weeks total):
- Multiple Lambda functions
- Custom business logic
- Medium database size
- 5–15 dependencies
- EventBridge or SQS integration

HIGH (6–10 weeks total):
- EKS/ECS clusters
- Complex event-driven architecture
- Large databases with replication
- 15+ dependencies per resource
- Custom VPC networking (Direct Connect, VPN)
- Multiple regions or accounts

CRITICAL (10+ weeks total):
- Multi-region active-active deployments
- Cross-account IAM access
- Custom CloudFormation constructs requiring re-engineering
- Legacy application modernisation alongside migration
```
