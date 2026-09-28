# Design Document Template

Use this as the starting structure for `outputs/azure-architecture-output/design-document.md`.

```markdown
# Azure Architecture Design Document

## 1. Executive Summary
- Migration scope:
- Target Azure architecture pattern:
- Primary business outcomes:
- Success criteria:
- Non-goals:

## 2. Current State
### 2.1 Workload Summary
- Business capability:
- Current AWS regions:
- Runtime model:
- Current operational pain points:

### 2.2 AWS Services and Dependencies
| AWS Service | Count / Size | Region | Dependency Notes |
|---|---|---|---|

### 2.3 Constraints and Risks
- Security and compliance constraints:
- Availability / RTO / RPO constraints:
- Data residency constraints:
- Unknowns requiring assumptions:

## 3. Service Mapping
| AWS Service | Current Configuration | Azure Equivalent | Azure SKU / Tier | Decision Rationale | Migration Notes |
|---|---|---|---|---|---|

## 4. Target Architecture
### 4.1 Architecture Overview
- Ingress pattern:
- Compute pattern:
- Data pattern:
- Messaging pattern:
- Secret and identity pattern:

### 4.2 Mermaid Diagram Reference
- File: `outputs/azure-architecture-output/architecture-diagram-azure.mmd`
- Inline summary of subgraphs and flows:

### 4.3 Data Flow Narrative
1. User request path:
2. Async processing path:
3. Observability path:
4. Failure and retry path:

## 5. Bicep Module Spec
### 5.1 `<module-name>` (`modules/<file>.bicep`)
- Purpose:
- Parameters:
- Resources and API versions:
- Required outputs:
- Security controls:
- Environment differences:
- Dependencies:

### 5.n Repeat for every module

## 6. Function Rewrite Spec
### 6.1 `<function-name>`
- Original AWS source path:
- Azure Function trigger type:
- Entry point:
- boto3 to Azure SDK mapping:
- Environment variable mapping:
- Secret retrieval pattern:
- Error handling and retry behavior:
- Required code/config files:

### 6.n Repeat for every function

## 7. Security Design
- Managed identity model:
- RBAC assignments by resource:
- Key Vault secret inventory:
- Encryption at rest / in transit:
- WAF / ingress protection:
- Threats and mitigations:

## 8. Networking Design
- Region and availability zone decision:
- VNet and subnet layout:
- Private endpoints and private DNS zones:
- Public ingress path:
- Outbound egress path:
- Network policy / NSG expectations:

## 9. Monitoring Design
- Application Insights plan:
- Log Analytics workspace plan:
- Metrics and alerts:
- Distributed tracing coverage:
- Dashboard and ownership model:

## 10. Cost Estimate
- Monthly Azure pay-as-you-go estimate:
- 1-year reservation scenario:
- 3-year reservation scenario:
- Top cost drivers:
- Assumptions and sensitivity notes:
- Companion report: `outputs/azure-architecture-output/cost-comparison.md`

## 11. CI/CD Spec
### 11.1 Workflow Inventory
| Workflow File | Trigger | Purpose | Target Environment |
|---|---|---|---|

### 11.2 Authentication and Secrets
- OIDC / workload identity details:
- Required secrets:
- Required variables:
- RBAC needed by the GitHub principal:

### 11.3 Deployment Jobs
- Infra workflow steps:
- App workflow steps:
- Validation / smoke test workflow steps:

### 11.4 Environment Promotion Model
- `dev` gate:
- `staging` gate:
- `prod` gate:

### 11.5 Rollback and Failure Handling
- Rollback triggers:
- Rollback actions:
- Human approval points:
```
