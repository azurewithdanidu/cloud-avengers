# Service-Specific Design Rules

## Azure Functions

- Default to the Python v2 programming model when the codebase is Python.
- Use Consumption for bursty, internet-facing event workloads; switch to Premium only when private networking, predictable warm instances, or longer-running needs are documented.
- Every Function App must use managed identity for downstream Azure access.
- Do not make API Management the primary ingress unless a separate gateway requirement is explicitly documented.
- Document trigger type, retry model, and idempotency expectations in Section 6.

## Azure Blob Storage

- Disable anonymous public access unless a public object hosting requirement is explicitly documented.
- Choose Hot, Cool, or Archive from measured access patterns, not guesswork.
- Prefer private endpoints and private DNS for application access.
- Record lifecycle policies if uploads, processed artifacts, or logs require retention management.
- Document encryption, replication, and container separation requirements.

## Azure Service Bus

- Prefer queues for point-to-point processing and topics/subscriptions for fan-out patterns.
- Use Standard by default; justify Premium only for throughput isolation, VNet, or advanced feature needs.
- Capture retry, lock duration, dead-letter handling, and poison message behavior.
- Use managed identity or secure secret retrieval for connection details; avoid embedding connection strings in code.
- Make downstream consumers idempotent and document that expectation in Section 6.

## Azure Cosmos DB

- Choose the API and partition key deliberately; both decisions must be documented.
- Use serverless or autoscale when workload shape is variable and the discovery data supports it.
- Document consistency level, backup strategy, and regional distribution explicitly.
- If change feed replaces DynamoDB Streams or other eventing, record the operational tradeoffs.
- Capture private endpoint and network boundary expectations in Section 8.

## Azure Database for PostgreSQL

- Use Flexible Server unless a stronger reason exists.
- Prefer private networking and managed backups by default.
- Size from current CPU, memory, storage, and connection evidence rather than a best guess.
- Document HA, maintenance window, connection pooling, and migration cutover considerations.
- If cost or latency pressure suggests a different data tier, explain why PostgreSQL remains the correct choice.

## Azure Key Vault

- Enable soft delete and purge protection.
- Prefer RBAC authorization mode over legacy access policies unless a specific integration requires otherwise.
- Minimize the number of secrets by preferring managed identity to direct credentials.
- Document certificate, secret rotation, and bootstrap requirements.
- Show every consumer of each secret or certificate in Sections 7 and 11.

## Azure Front Door

- Use Front Door as the default public ingress for global routing, WAF, and TLS termination.
- Choose Standard unless Premium is required for advanced private origin or security features.
- Document custom domains, health probes, origin failover, and caching behavior.
- Label every edge to Front Door in the architecture diagram with protocol and auth context.
- Capture WAF rules, rate limiting, and bot or geo protections in Section 7.
