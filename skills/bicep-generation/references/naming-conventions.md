# Naming Convention Rules

Use deterministic names derived from parameters or variables, not ad hoc literals.

| Resource type | Pattern | Example |
|---|---|---|
| Resource group | `rg-{workload}-{env}-{region}` | `rg-orders-dev-aue` |
| Function App | `func-{workload}-{env}` | `func-orders-dev` |
| App Service plan / Functions plan | `plan-{workload}-{env}` | `plan-orders-dev` |
| Storage account | `st{workload}{env}{region}{suffix}` | `stordersdevaue01` |
| Service Bus namespace | `sb-{workload}-{env}` | `sb-orders-dev` |
| Cosmos DB account | `cosmos-{workload}-{env}` | `cosmos-orders-dev` |
| PostgreSQL server | `psql-{workload}-{env}` | `psql-orders-dev` |
| Key Vault | `kv-{workload}-{env}` | `kv-orders-dev` |
| Log Analytics workspace | `log-{workload}-{env}` | `log-orders-dev` |
| Application Insights | `appi-{workload}-{env}` | `appi-orders-dev` |

Naming rules:

- Compute names once in variables or parameters.
- Keep storage account names lowercase and globally unique.
- Avoid inline interpolation inside resource `name:` properties; assign the final string to a variable first.
- Reuse the same workload, environment, and region tokens everywhere for reviewability.
