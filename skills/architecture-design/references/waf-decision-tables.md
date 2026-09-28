# WAF Decision Tables by Service Type

Use these tables to justify service selection. Document the chosen row or the reason for deviating.

| Service type | Default Azure choice | Security decision | Reliability decision | Cost decision | Performance decision | Operational decision |
|---|---|---|---|---|---|---|
| Public HTTP ingress | Azure Front Door Standard or Premium | WAF, origin shielding, TLS termination | Global edge presence and health probes | Use Standard unless Premium features are required | Edge caching and routing reduce latency | Centralized ingress policy and cert management |
| Stateless API / event handler | Azure Functions | Managed identity, least privilege, no secrets in code | Consumption for bursty traffic, Premium for VNet or low cold-start tolerance | Serverless-first to minimize idle cost | Scale on demand | Simple deploy and strong platform integration |
| Async messaging | Azure Service Bus | RBAC over connection strings | Dead-lettering and duplicate detection if needed | Standard unless Premium isolation/features are required | Reliable queue/topic throughput | Mature ops model and diagnostics |
| Object storage | Azure Blob Storage | Disable public access, use private endpoints | Redundancy tier based on RPO/RTO | Hot/Cool/Archive chosen by access pattern | High throughput for binary payloads | Native lifecycle policies |
| Document / event store | Azure Cosmos DB | RBAC or managed identity access where supported | Multi-region only if explicitly required | Serverless/autoscale for variable load | Low-latency global data model | Rich diagnostics and backup options |
| Relational database | Azure Database for PostgreSQL Flexible Server | Private access, Entra auth where feasible | Zone redundancy only if justified | Burstable or General Purpose sized from evidence | Right-size compute and storage independently | Managed backups and patching |
| Secret store | Azure Key Vault | Purge protection, soft delete, RBAC | Geo-redundancy only if required | Low infrastructure overhead | Acceptable performance for secret lookups | Centralized secret and certificate lifecycle |
