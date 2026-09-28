# Migration Task Plan — Initial Template

If `outputs/migration-task-plan.md` does not exist, create it with this full template:

```markdown
# Migration Task Plan

Generated: <UTC-ISO-8601>
Last Updated: <UTC-ISO-8601>
Current Resume Point: discovery

## Migration Scope

| Field | Value |
|---|---|
| AWS Account ID | <aws-account-id> |
| AWS Region | <aws-region> |
| Source Application Root | `source-app/` |
| Output Root | `outputs/` |
| Workflow Root | `.github/workflows/` |

## Status Legend

| Symbol | Meaning |
|---|---|
| ⏳ | Not started |
| 🔄 | In progress |
| ✅ | Complete |
| ❌ | Failed / Blocked |

## Phase Summary

| Phase | Owner | Artifact Root | Status | Completed At |
|---|---|---|---|---|
| 1 — Discovery | aws-discovery | `outputs/aws-migration-artifacts/` | ⏳ | — |
| 2 — Architecture | azure-architect | `outputs/azure-architecture-output/` | ⏳ | — |
| 3a — IaC Transformation | iac-transformation | `outputs/bicep-templates/` | ⏳ | — |
| 3b — Code Refactor | code-refactor | `outputs/azure-functions/` | ⏳ | — |
| 3c — Pipeline Build | pipeline-builder-agent | `.github/workflows/` | ⏳ | — |
| 4 — Validation | deployment-validation | `outputs/validation-report.md` | ⏳ | — |

## Detailed Task List

### Phase 1 — AWS Discovery
- [ ] Discover AWS services, regions, and dependencies from the source workload
- [ ] Write `outputs/aws-migration-artifacts/aws-inventory.json`
- [ ] Write `outputs/aws-migration-artifacts/architecture-diagram.mmd`
- [ ] Write `outputs/aws-migration-artifacts/dependency-matrix.csv`
- [ ] Write `outputs/aws-migration-artifacts/migration-assessment.md`

### Phase 2 — Azure Architecture
- [ ] Read all artifacts in `outputs/aws-migration-artifacts/`
- [ ] Write `outputs/azure-architecture-output/design-document.md`
- [ ] Write `outputs/azure-architecture-output/architecture-diagram-azure.mmd`
- [ ] Write `outputs/azure-architecture-output/cost-comparison.md`
- [ ] Write `outputs/azure-architecture-output/service-mapping.md`
- [ ] Replace Phase 3 placeholders using Sections 5, 6, and 11 of `design-document.md`

### Phase 3a — IaC Transformation
- [ ] Read Section 5 of `outputs/azure-architecture-output/design-document.md`
- [ ] Write `outputs/bicep-templates/main.<group>.bicep` for each group (networking, security, data, monitoring, messaging, compute — or a justified alternative), calling AVM modules directly (no local module files)
- [ ] Write `outputs/bicep-templates/parameters/dev/<group>.bicepparam` for each deployed group
- [ ] Write `outputs/bicep-templates/parameters/staging/<group>.bicepparam` for each deployed group
- [ ] Write `outputs/bicep-templates/parameters/prod/<group>.bicepparam` for each deployed group

### Phase 3b — Code Refactor
- [ ] Read Section 6 of `outputs/azure-architecture-output/design-document.md`
- [ ] Write `outputs/azure-functions/function_app.py`
- [ ] Write `outputs/azure-functions/host.json`
- [ ] Write `outputs/azure-functions/requirements.txt`
- [ ] Add one task per function rewrite from Section 6 when the design document is available

### Phase 3c — Pipeline Build
- [ ] Read Section 11 of `outputs/azure-architecture-output/design-document.md`
- [ ] Write workflow files under `.github/workflows/`
- [ ] Add one task per workflow from Section 11.1 when the design document is available
- [ ] Configure OIDC authentication in the workflow YAML
- [ ] Configure GitHub Environments for `dev`, `staging`, and `prod`

### Phase 4 — Validation
- [ ] Re-check Phase 1 through Phase 3 artifacts before validation starts
- [ ] Validate architecture, security, networking, monitoring, and deployment assumptions
- [ ] Write `outputs/validation-report.md`
- [ ] Record final PASSED or FAILED result and any remediation items

## Blockers

- None
```
