# AWS → Azure → AVM Module Mapping

Use this catalog to select the correct Azure Verified Module for each AWS service found in the design document.

## Compute

| AWS Service | Azure Equivalent | AVM Module |
|---|---|---|
| Lambda (event-driven) | Azure Functions | `res/web/site` + `res/web/serverfarm` (kind='functionapp,linux') |
| Lambda (container) | Azure Container Apps Job | `res/app/job` |
| ECS Fargate | Azure Container Apps | `res/app/container-app` + `res/app/managed-environment` |
| EKS | AKS | `res/container-service/managed-cluster` or `ptn/azd/aks` |
| EC2 | Azure Virtual Machine | `res/compute/virtual-machine` |
| Elastic Beanstalk | App Service | `res/web/site` + `res/web/serverfarm` (kind='app') |

## Storage

| AWS Service | Azure Equivalent | AVM Module |
|---|---|---|
| S3 | Azure Blob Storage | `res/storage/storage-account` (kind='StorageV2') |
| S3 Static Website | Static Web App | `res/web/static-site` |
| EFS | Azure Files | `res/storage/storage-account` (fileServices enabled) |
| EBS | Managed Disk | `res/compute/disk` |

## Database

| AWS Service | Azure Equivalent | AVM Module |
|---|---|---|
| RDS PostgreSQL | Azure Database for PostgreSQL Flexible | `res/db-for-postgre-sql/flexible-server` |
| RDS MySQL | Azure Database for MySQL Flexible | `res/db-for-my-sql/flexible-server` |
| RDS SQL Server | Azure SQL Database | `res/sql/server` |
| DynamoDB | Cosmos DB | `res/document-db/database-account` (NoSQL API) |
| ElastiCache Redis | Azure Cache for Redis | `res/cache/redis` |

## Messaging & Events

| AWS Service | Azure Equivalent | AVM Module |
|---|---|---|
| SQS | Azure Service Bus (queue) | `res/service-bus/namespace` |
| SNS | Azure Service Bus (topic) or Event Grid | `res/service-bus/namespace` or `res/event-grid/topic` |
| EventBridge | Azure Event Grid | `res/event-grid/namespace` or `res/event-grid/topic` |
| Kinesis Data Streams | Azure Event Hubs | `res/event-hub/namespace` |

## Security & Identity

| AWS Service | Azure Equivalent | AVM Module |
|---|---|---|
| IAM Role (service) | Managed Identity | `res/managed-identity/user-assigned-identity` |
| IAM Role (user) | Azure RBAC role assignment | `ptn/authorization/role-assignment` |
| Secrets Manager | Azure Key Vault | `res/key-vault/vault` |
| KMS | Azure Key Vault (keys) | `res/key-vault/vault` |
| SSM Parameter Store | App Configuration or Key Vault | `res/app-configuration/configuration-store` |

## Networking

| AWS Service | Azure Equivalent | AVM Module |
|---|---|---|
| VPC | Virtual Network | `res/network/virtual-network` |
| Security Group | Network Security Group | `res/network/network-security-group` |
| ALB | Application Gateway | `res/network/application-gateway` |
| Route 53 (public) | Azure DNS Zone | `res/network/dns-zone` |
| Route 53 (private) | Private DNS Zone | `res/network/private-dns-zone` |
| VPC Endpoint | Private Endpoint | `res/network/private-endpoint` |
| NAT Gateway | NAT Gateway | `res/network/nat-gateway` |
| CloudFront | Azure Front Door | `res/cdn/profile` |
| VPC Peering | VNet Peering | `res/network/virtual-network-peering` |
| Direct Connect | ExpressRoute | `res/network/express-route-circuit` |

## Monitoring

| AWS Service | Azure Equivalent | AVM Module |
|---|---|---|
| CloudWatch Logs | Log Analytics Workspace | `res/operational-insights/workspace` |
| CloudWatch Alarms | Azure Monitor Alerts | `res/insights/metric-alert` |
| X-Ray | Application Insights | `res/insights/component` |
| CloudTrail | Azure Monitor Activity Log | `res/insights/diagnostic-setting` |

## Pattern Modules (Prefer When Available)

- Multi-spoke hub networking → `ptn/network/hub-networking`
- AKS full cluster → `ptn/azd/aks`
- Container Apps full stack → `ptn/azd/container-apps-stack`
- Private DNS zones for Private Link → `ptn/network/private-link-private-dns-zones`
- RBAC role assignment (cross-scope) → `ptn/authorization/role-assignment`
- AI Foundry stack → `ptn/ai-ml/ai-foundry`
