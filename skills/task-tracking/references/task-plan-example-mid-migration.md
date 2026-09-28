# Mid-Migration Example

This is what a filled-in plan should look like after Phase 2 is complete and the parallel Phase 3 wave is underway:

```markdown
# Migration Task Plan

Generated: 2026-07-14T00:14:16Z
Last Updated: 2026-07-14T01:06:54Z
Current Resume Point: parallel

## Migration Scope

| Field | Value |
|---|---|
| AWS Account ID | 123456789012 |
| AWS Region | ap-southeast-2 |
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
| 1 — Discovery | aws-discovery | `outputs/aws-migration-artifacts/` | ✅ | 2026-07-14T00:28:04Z |
| 2 — Architecture | azure-architect | `outputs/azure-architecture-output/` | ✅ | 2026-07-14T00:54:41Z |
| 3a — IaC Transformation | iac-transformation | `outputs/bicep-templates/` | 🔄 | — |
| 3b — Code Refactor | code-refactor | `outputs/azure-functions/` | 🔄 | — |
| 3c — Pipeline Build | pipeline-builder-agent | `.github/workflows/` | ✅ | 2026-07-14T01:05:12Z |
| 4 — Validation | deployment-validation | `outputs/validation-report.md` | ⏳ | — |

## Detailed Task List

### Phase 1 — AWS Discovery
- [x] Discover AWS services, regions, and dependencies from the source workload — completed 2026-07-14T00:18:50Z
- [x] Write `outputs/aws-migration-artifacts/aws-inventory.json` — completed 2026-07-14T00:21:39Z
- [x] Write `outputs/aws-migration-artifacts/architecture-diagram.mmd` — completed 2026-07-14T00:24:18Z
- [x] Write `outputs/aws-migration-artifacts/dependency-matrix.csv` — completed 2026-07-14T00:25:02Z
- [x] Write `outputs/aws-migration-artifacts/migration-assessment.md` — completed 2026-07-14T00:27:44Z

### Phase 2 — Azure Architecture
- [x] Read all artifacts in `outputs/aws-migration-artifacts/` — completed 2026-07-14T00:32:10Z
- [x] Write `outputs/azure-architecture-output/design-document.md` — completed 2026-07-14T00:43:22Z
- [x] Write `outputs/azure-architecture-output/architecture-diagram-azure.mmd` — completed 2026-07-14T00:46:19Z
- [x] Write `outputs/azure-architecture-output/cost-comparison.md` — completed 2026-07-14T00:49:10Z
- [x] Write `outputs/azure-architecture-output/service-mapping.md` — completed 2026-07-14T00:52:51Z
- [x] Replace Phase 3 placeholders using Sections 5, 6, and 11 of `design-document.md` — completed 2026-07-14T00:54:41Z

### Phase 3a — IaC Transformation
- [x] Read Section 5 of `outputs/azure-architecture-output/design-document.md` — completed 2026-07-14T00:56:18Z
- [x] Write `main.networking.bicep` — virtual network, subnets, private DNS — completed 2026-07-14T00:58:37Z
- [x] Write `main.compute.bicep` — function app, plan, identity — completed 2026-07-14T01:01:12Z
- [ ] Write `outputs/bicep-templates/main.data.bicep`
- [ ] Write `outputs/bicep-templates/parameters/dev/networking.bicepparam`

### Phase 3b — Code Refactor
- [x] Read Section 6 of `outputs/azure-architecture-output/design-document.md` — completed 2026-07-14T00:55:49Z
- [ ] Refactor `upload-handler` to HTTP-trigger Azure Function
- [ ] Refactor `processor-handler` to Service Bus-trigger Azure Function
- [ ] Write `outputs/azure-functions/requirements.txt`
- [ ] Write `outputs/azure-functions/host.json`

### Phase 3c — Pipeline Build
- [x] Read Section 11 of `outputs/azure-architecture-output/design-document.md` — completed 2026-07-14T00:55:11Z
- [x] Create `.github/workflows/deploy-infra.yml` — completed 2026-07-14T00:59:26Z
- [x] Create `.github/workflows/deploy-functions.yml` — completed 2026-07-14T01:02:40Z
- [x] Configure OIDC authentication in the workflow YAML — completed 2026-07-14T01:04:18Z
- [x] Configure GitHub Environments for `dev`, `staging`, and `prod` — completed 2026-07-14T01:05:12Z

### Phase 4 — Validation
- [ ] Re-check Phase 1 through Phase 3 artifacts before validation starts
- [ ] Validate architecture, security, networking, monitoring, and deployment assumptions
- [ ] Write `outputs/validation-report.md`
- [ ] Record final PASSED or FAILED result and any remediation items

## Blockers

- None
```
