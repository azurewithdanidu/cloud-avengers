# Artifact Checklist Per Phase

A phase is not complete until every listed artifact exists, is non-empty, and meets the minimum content assertion.

| Phase | Required artifact | Minimum assertion |
|---|---|---|
| 1 | `outputs/aws-migration-artifacts/aws-inventory.json` | Valid JSON-like content, not an empty object or empty array |
| 1 | `outputs/aws-migration-artifacts/architecture-diagram.mmd` | Contains `graph` or `flowchart` |
| 1 | `outputs/aws-migration-artifacts/dependency-matrix.csv` | At least a header row plus one dependency row |
| 1 | `outputs/aws-migration-artifacts/migration-assessment.md` | Contains at least one `##` heading and migration findings |
| 2 | `outputs/azure-architecture-output/design-document.md` | Contains all 11 required section headings |
| 2 | `outputs/azure-architecture-output/architecture-diagram-azure.mmd` | Contains Mermaid graph syntax plus at least one `subgraph` |
| 2 | `outputs/azure-architecture-output/cost-comparison.md` | Contains a monthly summary table and break-even section |
| 2 | `outputs/azure-architecture-output/service-mapping.md` | Contains AWS and Azure mapping columns |
| 3a | `outputs/bicep-templates/main.*.bicep` | At least one grouped orchestrator file exists (`main.networking.bicep`, `main.security.bicep`, `main.data.bicep`, `main.monitoring.bicep`, `main.messaging.bicep`, `main.compute.bicep`, or a justified alternative group), each declaring `targetScope = 'subscription'` and containing only AVM module calls (`br/public:avm/...`) — no local `modules/*.bicep` files |
| 3a | `outputs/bicep-templates/parameters/dev/*.bicepparam` | At least one parameter file per deployed group, each referencing its matching `../../main.<group>.bicep` |
| 3b | `outputs/azure-functions/function_app.py` | Contains Azure Functions app definition |
| 3b | `outputs/azure-functions/requirements.txt` | Lists `azure-functions` and needed Azure SDK packages |
| 3b | `outputs/azure-functions/host.json` | Non-empty JSON configuration |
| 3c | `.github/workflows/*.yml` or `.github/workflows/*.yaml` | At least one workflow file exists |
| 3c | one workflow file with `infra` or `deploy` in the file name | Contains Azure login and deployment steps |
| 4 | `outputs/validation-report.md` | Starts with `## Status: PASSED` or `## Status: FAILED` |
