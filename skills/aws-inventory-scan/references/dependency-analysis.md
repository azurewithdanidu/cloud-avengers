# Dependency Analysis

## Dependency Types

**Direct** (resource A directly calls or uses B):
- Lambda → S3 (reads/writes objects)
- Lambda → RDS (database queries)
- Lambda → DynamoDB (item-level access)
- Lambda → Secrets Manager (credential fetch)
- API Gateway → Lambda (invocation)

**Indirect** (A uses B which uses C):
- Lambda → IAM Role → KMS Key
- EventBridge Rule → SNS Topic → SQS Queue → Lambda

**Network** (infrastructure-level relationships):
- EC2 Instance → VPC → Subnet → Route Table
- RDS Instance → DB Subnet Group → VPC
- EKS Cluster → VPC → Subnets → Security Groups

## Relationship Verb Vocabulary

Use exactly these verbs in the dependency matrix:

| Verb | Meaning |
|---|---|
| `reads` | Source reads data from target |
| `writes` | Source writes data to target |
| `queries` | Source queries target (database) |
| `calls` | Source invokes target (function/API) |
| `authenticates` | Source authenticates via target (IAM/Cognito) |
| `encrypts` | Source data encrypted by target (KMS) |
| `depends-on` | Generic dependency (use when none above fit) |
| `network` | Network-level dependency (VPC, subnet, SG) |
