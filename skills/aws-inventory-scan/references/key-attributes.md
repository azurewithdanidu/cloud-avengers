# Key Attributes

For EVERY discovered resource capture these attributes without exception:

| Attribute | Description |
|---|---|
| `identifier` | Full ARN, resource ID, and human-readable name |
| `type` | AWS service name + resource type (e.g., `lambda/function`) |
| `region` | AWS region(s) the resource exists in |
| `configuration` | Key settings and properties specific to that resource type |
| `tags` | All resource tags (cost allocation, compliance, ownership) |
| `dependencies` | Other resources this resource calls, reads from, or writes to |
| `used_by` | Resources that depend on this resource (reverse dependencies) |
| `criticality` | Business importance: `CRITICAL` / `HIGH` / `MEDIUM` / `LOW` |
| `compliance` | Compliance tags or requirements (PCI, HIPAA, SOC2) |
| `monthly_cost_usd` | Estimated monthly cost from Cost Explorer if available |
| `source_path` | For Lambda: path to source files under `source-app/` |

## Service-Specific Additional Attributes

For Lambda specifically also capture: `runtime`, `memory_mb`, `timeout_s`, `handler`, `environment_variables`, `layers`, `triggers`, `vpc_config`.

For RDS also capture: `engine`, `engine_version`, `instance_class`, `allocated_storage_gb`, `multi_az`, `backup_retention_days`, `encryption_enabled`.

For S3 also capture: `versioning_enabled`, `lifecycle_policies`, `public_access_blocked`, `replication_rules`.

## Required Compliance Tags

Always capture and surface these tags if present:

| Tag Key | Values |
|---|---|
| `Environment` | development, staging, production |
| `Application` | service/component name |
| `Owner` | team or person responsible |
| `CostCenter` | cost allocation code |
| `Compliance` | PCI, HIPAA, SOC2, etc. |
| `DataClassification` | public, internal, confidential, restricted |
