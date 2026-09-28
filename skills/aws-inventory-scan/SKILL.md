---
name: aws-inventory-scan
description: Read the source AWS application and produce a structured JSON inventory of every AWS service in use, plus a Mermaid architecture diagram and dependency matrix
---


# AWS Inventory Scan Skill

## Purpose

Produce a complete, structured inventory of all AWS services used by the source application so downstream agents have accurate inputs for architecture design and code refactoring.

## When to Use

As the first action in Phase 1, before any other discovery work.

## Inputs

| Path | Why it matters |
|---|---|
| `source-app/app-code/template.yaml` | CloudFormation/SAM template to cross-check deployed resources |
| `source-app/app-code/lambda/` | Lambda source files to discover implicit boto3 SDK dependencies |
| `source-app/doc/` | Architectural context and any existing runbooks |
## Process

**Primary source: live AWS environment via AWS MCP Server.** Local files in `source-app/` are supplementary — use them to enrich Lambda source paths and confirm implicit SDK dependencies, not as a substitute for live data.

1. **Authenticate & orient** — Use the AWS MCP Server to call `sts:GetCallerIdentity` and obtain the AWS account ID and active regions. Record the account ID in `aws-inventory.json`.
2. **Live resource enumeration** — For each region, use the AWS MCP Server to enumerate all resources across every service category in the **AWS Services Catalogue** section. Use `resourcegroupstaggingapi:GetResources` first to get a broad tagged-resource baseline, then make service-specific API calls (e.g., `lambda:ListFunctions`, `s3:ListBuckets`, `dynamodb:ListTables`, `iam:ListRoles`, `apigateway:GetRestApis`, `cloudformation:DescribeStacks`) to fill in untagged resources and full configuration details.
3. **Supplement with local source** — Read `source-app/app-code/template.yaml` to cross-check deployed resource names, verify SAM/CloudFormation-declared resources are present in the live inventory, and catch any resources not yet deployed. Read Lambda source files under `source-app/app-code/lambda/` to identify implicit boto3 SDK calls that reveal service dependencies not declared in the template. Read `source-app/doc/` for architectural context.
4. **Capture attributes** — For each discovered resource, capture every attribute defined in the **Key Attributes** section using live API response data as the authoritative value.
5. **Map dependencies** — Use the live IAM role-to-resource bindings, environment variable references, and event source mappings returned by the AWS MCP Server to build the dependency graph. Supplement with boto3 call analysis from step 3.
6. **Write output files** — Write the four output files using the schemas in this skill.
7. **Run the Validation Checklist** before marking Phase 1 complete.

---


## Reference Files

| File | Load when |
|---|---|
| [references/aws-services-catalogue.md](references/aws-services-catalogue.md) | Enumerating resources — the minimum service list to scan across every category |
| [references/key-attributes.md](references/key-attributes.md) | Capturing per-resource attributes, service-specific fields, and required compliance tags |

## References

### AWS Documentation

| Topic | Link |
|---|---|
| AWS Lambda developer guide | https://docs.aws.amazon.com/lambda/latest/dg/welcome.html |
| AWS SAM template specification | https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-specification.html |
| CloudFormation resource type reference | https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html |
| boto3 SDK reference | https://boto3.amazonaws.com/v1/documentation/api/latest/index.html |
| AWS Cost Explorer | https://docs.aws.amazon.com/cost-management/latest/userguide/ce-what-is.html |
| Amazon S3 developer guide | https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html |
| Amazon DynamoDB developer guide | https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html |
| Amazon EKS user guide | https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html |
| Amazon EventBridge user guide | https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-what-is.html |
| AWS IAM user guide | https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html |
| AWS Secrets Manager user guide | https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html |
| Amazon API Gateway developer guide | https://docs.aws.amazon.com/apigateway/latest/developerguide/welcome.html |

### Best Practices

- **Always scan implicit dependencies** — boto3 calls in Lambda code often reveal service usage not declared in CloudFormation/SAM templates.
- **Tag-based discovery:** Use `aws resourcegroupstaggingapi get-resources` to find all tagged resources across services before relying on template parsing alone.
- **Multi-region awareness:** Run inventory scans in every region the account is active in — not just `us-east-1`.
- **AWS Well-Architected Tool:** Cross-reference findings against the Well-Architected review at https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html

---

## Reference Files (continued)

| File | Load when |
|---|---|
| [references/dependency-analysis.md](references/dependency-analysis.md) | Mapping resource dependencies — direct/indirect/network types and the fixed relationship-verb vocabulary |
| [references/output-schemas.md](references/output-schemas.md) | Writing `aws-inventory.json`, `architecture-diagram.mmd`, `dependency-matrix.csv`, or the IAM documentation block |

## Rules

- **Never modify anything in `source-app/`** — read only.
- **Never skip implicit dependencies** — scan Lambda source code for all boto3 client calls, revealing services not declared in the template.
- **Never omit the `implicit_dependencies` array** — even if empty, include it as `[]`.
- **Always include `source_path`** for every Lambda function so code-refactor can locate the source.
- **Never invent resource counts** — only report what is actually in the template or code.
- **All relationships must be bidirectional** — if A depends on B, B's `used_by` must include A.
- **Do NOT capture actual secret values** — names and metadata only.

---


## Validation Checklist

See [references/validation-checklist.md](references/validation-checklist.md) for the full completeness, accuracy, dependency, and output-quality checklist. Every item must pass before marking Phase 1 complete.

## Scripts

| Script | When to run |
|---|---|
| `./scripts/validate-inventory.sh` | Run on Bash/macOS/Linux/WSL immediately after generating `outputs/aws-migration-artifacts/aws-inventory.json` to validate the schema before downstream agents consume it. |
| `./scripts/validate-inventory.ps1` | Run the same validation on PowerShell 7+ environments, including Windows runners and GitHub Actions jobs using `pwsh`. |

## Outputs

- `outputs/aws-migration-artifacts/aws-inventory.json` — valid JSON, non-empty
- `outputs/aws-migration-artifacts/architecture-diagram.mmd` — valid Mermaid syntax
- `outputs/aws-migration-artifacts/dependency-matrix.csv` — header + data rows
- `outputs/aws-migration-artifacts/migration-assessment.md` — see `migration-assessment` skill
