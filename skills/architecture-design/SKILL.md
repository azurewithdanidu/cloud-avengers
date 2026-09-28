---
name: architecture-design
description: 'Design the Azure target architecture from AWS discovery artifacts. Use when: creating outputs/azure-architecture-output/design-document.md, choosing Azure services, documenting WAF tradeoffs, or defining Bicep, function, security, networking, monitoring, and CI/CD specifications.'
---

# Architecture Design Skill

## Purpose

Convert AWS discovery evidence into a complete Azure target design that downstream IaC, code-refactor, pipeline, cost, and validation phases can implement without ambiguity.

## When to Use

- During Phase 2, immediately after discovery artifacts are ready
- Before any Bicep, Azure Functions, workflow, or validation work starts
- When a resume run needs to rebuild or repair `design-document.md`
- When Azure service selection, SKU choice, or WAF tradeoffs need to be documented explicitly

## Inputs

| Path | Role |
|---|---|
| `outputs/aws-migration-artifacts/aws-inventory.json` | AWS service inventory and configuration baseline |
| `outputs/aws-migration-artifacts/architecture-diagram.mmd` | Current-state topology clues |
| `outputs/aws-migration-artifacts/dependency-matrix.csv` | Upstream/downstream dependency evidence |
| `outputs/aws-migration-artifacts/migration-assessment.md` | Constraints, blockers, and migration strategy notes |
| `source-app/` | Read-only application code and documentation |
| `skills/aws-to-azure-mapping/SKILL.md` | Service mapping guidance |
| `skills/architecture-diagramming/SKILL.md` | Diagram contract for Section 4 |
| `skills/bicep-generation/SKILL.md` | Module contract for Section 5 |
| `skills/cost-analysis/SKILL.md` | Cost contract for Section 10 |
| `skills/multi-env-strategy/SKILL.md` | CI/CD and environment contract for Section 11 |

## Outputs

| Path | Result |
|---|---|
| `outputs/azure-architecture-output/design-document.md` | Primary design handoff document with all 11 sections |
| `outputs/azure-architecture-output/architecture-diagram-azure.mmd` | Azure Mermaid diagram derived from Section 4 |
| `outputs/azure-architecture-output/cost-comparison.md` | Cost document derived from Section 10 |
| `outputs/azure-architecture-output/service-mapping.md` | Detailed AWS-to-Azure mapping companion artifact |

## Process

### 1. Build the design from evidence, not memory

1. Read all four Phase 1 artifacts first.
2. Enumerate every discovered AWS service and workload interaction.
3. For each service, choose the Azure equivalent using the mapping skill and current Azure documentation.
4. Record the reason for each decision, including the primary WAF pillar it optimizes and any tradeoff it creates.
5. Populate `design-document.md` before creating any downstream artifacts.

### 2. Required `design-document.md` sections

The final document must contain these exact top-level sections and enough detail that downstream phases can implement without asking follow-up questions.

| Section | Required content |
|---|---|
| `## 1. Executive Summary` | Migration scope, target Azure pattern, business outcome, success criteria, and major non-goals |
| `## 2. Current State` | AWS workload summary, source regions, integration boundaries, dependencies, pain points, and migration drivers |
| `## 3. Service Mapping` | One row per AWS service showing Azure equivalent, SKU, rationale, and migration notes |
| `## 4. Target Architecture` | Narrative of the Azure topology, ingress path, trust boundaries, data flow, and reference to the Mermaid diagram |
| `## 5. Bicep Module Spec` | One subsection per module with parameters, resources, outputs, security controls, environment differences, and dependencies |
| `## 6. Function Rewrite Spec` | One subsection per Lambda-to-Function rewrite with triggers, SDK changes, env vars, auth, retries, and test notes |
| `## 7. Security Design` | Identity, RBAC, Key Vault, encryption, WAF, secret handling, and compliance controls |
| `## 8. Networking Design` | VNets, subnets, private endpoints, DNS, egress path, ingress path, and boundary decisions |
| `## 9. Monitoring Design` | Logging, metrics, tracing, dashboards, alert thresholds, and ownership |
| `## 10. Cost Estimate` | Cost summary, assumptions, sensitivity ranges, reservation scenarios, and link to `cost-comparison.md` |
| `## 11. CI/CD Spec` | Workflow files, triggers, OIDC, environments, approvals, promotion order, rollback steps, and secrets/variables |


### 3. Design document template

Use the full template in [references/design-document-template.md](references/design-document-template.md) as the starting structure for `outputs/azure-architecture-output/design-document.md`. Fill in every section — do not leave placeholder bullets unaddressed.

### 4. WAF decision tables by service type

See [references/waf-decision-tables.md](references/waf-decision-tables.md) to justify service selection per Well-Architected Framework pillar. Document the chosen row or the reason for deviating.

### 5. Service-specific design rules

See [references/service-specific-design-rules.md](references/service-specific-design-rules.md) for default configuration rules per service (Functions, Blob Storage, Service Bus, Cosmos DB, PostgreSQL, Key Vault, Front Door).

### 6. Edge Cases / Failure Modes

- **Unknown traffic profile:** Provide low / expected / peak assumptions and call out the uncertainty in Section 10.
- **Unsupported direct service mapping:** Document the bridge pattern or redesign needed instead of forcing a false one-to-one mapping.
- **Conflicting RTO/RPO vs budget:** Prefer the documented business requirement, then surface the cost tradeoff explicitly.
- **Multi-region pressure without evidence:** Default to single-region plus zone redundancy unless discovery or policy requires more.
- **Security requirement blocks serverless default:** Upgrade to Premium or another service only when the requirement is concrete and documented.

## Rules

- **Serverless-first:** prefer Azure Functions unless the source workload proves a different compute model is required.
- **Single-region by default:** multi-region is opt-in, not assumed.
- **Design document before build artifacts:** Bicep, workflow, and code generation depend on it.
- **Cite the evidence source:** each major choice should trace back to a discovery artifact, a skill, or current Azure documentation.
- **Do not invent AWS facts:** if a value is missing, state the assumption and mark it in the cost and risk sections.

## Best Practices

- Keep Section 5 granular enough that each Bicep module has one clear responsibility.
- Keep Section 6 concrete enough that a refactor agent can translate code without rediscovering triggers or SDKs.
- Mirror Section 4 and the Mermaid file so diagram and prose never diverge.
- Capture both the default decision and the reason not to choose the obvious alternative when the tradeoff matters.
- Write the CI/CD section as implementation guidance, not a conceptual summary.

---

## References

### Microsoft / Azure Documentation

| Topic | Link |
|---|---|
| Azure Well-Architected Framework | https://learn.microsoft.com/en-us/azure/well-architected/ |
| WAF Reliability pillar | https://learn.microsoft.com/en-us/azure/well-architected/reliability/ |
| WAF Security pillar | https://learn.microsoft.com/en-us/azure/well-architected/security/ |
| WAF Cost Optimization pillar | https://learn.microsoft.com/en-us/azure/well-architected/cost-optimization/ |
| WAF Operational Excellence pillar | https://learn.microsoft.com/en-us/azure/well-architected/operational-excellence/ |
| WAF Performance Efficiency pillar | https://learn.microsoft.com/en-us/azure/well-architected/performance-efficiency/ |
| Azure Architecture Center | https://learn.microsoft.com/en-us/azure/architecture/ |
| Cloud design patterns | https://learn.microsoft.com/en-us/azure/architecture/patterns/ |
| Azure for AWS professionals | https://learn.microsoft.com/en-us/azure/architecture/aws-professional/ |
| Azure Functions hosting options | https://learn.microsoft.com/en-us/azure/azure-functions/functions-scale |
| Azure Container Apps vs AKS decision guide | https://learn.microsoft.com/en-us/azure/container-apps/compare-options |
| Azure regions availability | https://azure.microsoft.com/en-us/explore/global-infrastructure/products-by-region/ |
| Azure availability zones | https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview |
| Azure Front Door documentation | https://learn.microsoft.com/en-us/azure/frontdoor/front-door-overview |
| Azure Key Vault best practices | https://learn.microsoft.com/en-us/azure/key-vault/general/best-practices |

### AWS Documentation

| Topic | Link |
|---|---|
| AWS Well-Architected Framework | https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html |
| AWS Architecture Center | https://aws.amazon.com/architecture/ |
| AWS Migration whitepaper | https://docs.aws.amazon.com/whitepapers/latest/aws-migration-whitepaper/welcome.html |

### Best Practices

- **Security is a gating pillar, not a tie-breaker** — reject architectures that require long-lived secrets or uncontrolled public exposure.
- **Document module and function contracts explicitly** — they are the backbone of downstream automation.
- **State assumptions where facts are missing** — hidden assumptions become failed deployments later.
- **Keep service mapping, architecture narrative, and cost model aligned** — mismatches between the three cause cascading Phase 3 failures.
