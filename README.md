# AI-Assisted AWS to Azure Migration Factory

**Version:** 1.6.0 · [CHANGELOG](CHANGELOG.md) · [AGENTS.md](AGENTS.md)

A publishable plugin providing **10 specialist migration agents** and **22 skills** for an AWS-to-Azure migration workflow focused on Python serverless workloads and CloudFormation — from live account discovery through architecture design, code refactoring, IaC generation, CI/CD pipelines, and deployment validation. This is not a general-purpose migration engine for every AWS workload; see [Supported Workloads](#supported-workloads).

Installable as a plugin in Copilot CLI, Claude Code, and VS Code. All skill scripts run on macOS, Linux, WSL, and Windows (Bash + PowerShell 5.1 / 7+).

---

## Install

### Copilot CLI or Claude Code (recommended)
```
/plugin install azurewithdanidu/cloud-avengers
```

### Any agent runtime — latest `main`
```
npx skills add azurewithdanidu/cloud-avengers-skill
```

After installing, start a migration with:
```
/run-migration
```

---

## Quick Start (VS Code / Copilot Chat)

**Prerequisites:**
- VS Code with the GitHub Copilot extension (agent mode enabled)
- AWS credentials configured for the AWS MCP server with read access to the source account (AWS CLI may be used for local credential setup, not as a discovery fallback)
- Explicit AWS account ID and primary region; there is no default region. Discovery still scans all enabled regions.
- Azure CLI with Contributor access to the target subscription
- MCP servers configured and authenticated: AWS Cloud Control API · AWS Knowledge · Microsoft Learn · Azure · Mermaid Chart (see [MCP Requirements and Recovery](#mcp-requirements-and-recovery))
- Source code and CloudFormation/SAM template staged under read-only `source-app/` (expected paths: `app-code/template.yaml`, `app-code/lambda/`, and optional `doc/`)

**Option 1 — Slash command (recommended):**
```
/run-migration
```
The slash command collects your AWS account ID and primary region, then hands off to `@migration-project-manager`. Confirm the target Azure subscription and review generated artifacts before deployment.

**Option 2 — Invoke the orchestrator directly:**
```
@migration-project-manager Run the migration pipeline for AWS account <your-account-id> in region <your-aws-region>
```

**Option 3 — Run individual phases:**

| Step | Agent | Sample prompt |
|------|-------|---------------|
| 1 — Discovery | `@aws-discovery` | `Discover all resources in AWS account <id> and produce the inventory artifacts` |
| 2 — Architecture | `@azure-architect` | `Design Azure architecture based on the discovery outputs in outputs/aws-migration-artifacts/` |
| 3a — IaC | `@iac-transformation` | `Convert the CloudFormation template to Bicep using AVM modules` |
| 3b — Code | `@code-refactor` | `Refactor all Lambda functions to Azure Functions v2 (Python 3.11)` |
| 3c — Pipelines | `@pipeline-builder-agent` | `Create GitHub Actions CI/CD pipelines for infra, functions, and static web app` |
| 3d — Deploy | `@azure-deployer` | `Deploy the generated Bicep and Azure Functions to the target subscription` |
| 4 — Validation | `@deployment-validation` | `Validate all generated artifacts and produce a validation report` |

---

## Supported Workloads

These tiers describe the implemented guidance, not a guarantee of functional parity. Review and test all generated artifacts before deployment.

| Tier | Workloads | Boundary |
|---|---|---|
| Green - primary path | Python Lambda, API Gateway, S3, DynamoDB, CloudFormation/SAM | Python Lambda to Azure Functions v2 and CloudFormation to grouped Bicep are the strongest paths. DynamoDB mapping requires application-specific validation; automated data transfer is not provided. |
| Yellow - limited/manual | Node.js Lambda, simple networking | Partial guidance only; expect manual refactoring and validation, not an established end-to-end path. |
| Red - outside the automated path | EC2/VMs, ECS/EKS/containers, complex databases and data migration, Step Functions, complex networking, multi-account Organizations, .NET and other runtimes, Terraform and other non-CloudFormation IaC | Discovery or mapping guidance may exist, but automated transformation, deployment, and parity validation are not established. Use workload-specific migration tooling and engineering review. |

## MCP Requirements and Recovery

The current workflow depends on **AWS Cloud Control API**, **AWS Knowledge**, **Microsoft Learn**, **Azure**, and **Mermaid Chart** MCP servers for its respective phases. See [MCP Servers](#mcp-servers) for responsibilities. Verify connectivity, credentials, permissions, and required API/tool availability before starting a live run.

- **Missing or misconfigured AWS MCP:** stop Phase 1, install/configure the server in your host runtime, and reconnect. Local templates do not substitute for a live inventory.
- **Authentication failure:** configure SSO or short-lived credentials locally for the MCP server, then retry `sts:GetCallerIdentity` through MCP. Never paste credentials into chat or commit them.
- **Throttling or partial discovery:** report the failing calls and affected regions/services, wait for the provider's retry window, and retry the incomplete enumeration. Do not mark Phase 1 complete or pass a partial inventory downstream.
- **Other required MCP unavailable:** stop the affected phase, report the dependency, restore access, and resume that phase after its prerequisites have passed.

**No automatic AWS CLI, Config, or Resource Explorer discovery fallback is implemented.** If MCP cannot be restored, use separate read-only tooling for manual assessment; do not report that assessment as a completed plugin migration.

## Validation and Mutation Safeguards

- Inventory must pass the Bash or PowerShell inventory validator, including typed fields and exact resource-count agreement.
- Grouped Bicep validators require successful restore/build. Environment-specific what-if fails on missing group parameters, failed CLI calls, malformed results, or blocking data-resource deletes.
- RBAC and OIDC helper scripts require interactive `APPROVE` confirmation. Their PowerShell implementations require PowerShell 7+; `-WhatIf` makes no Azure calls.
- The project manager and deployer must obtain explicit approval for the specific Azure mutation, including changed targets, repair, fallback, and rollback.
- **Prompt instructions and script confirmation are not a non-bypassable security boundary.** Enforce host tool permissions and protected deployment environments externally; otherwise have a human execute the proposed commands.

Structural validation does not establish live inventory completeness or application parity. Formal schemas for every artifact, data-changing smoke-test hardening, and real-account integration tests remain separate work.

---

## Repository Structure

See [AGENTS.md](AGENTS.md) for the complete canonical reference. Summary:

```
.claude-plugin/
└── plugin.json             ← Canonical version source (semver). All release scripts read from here.

agents/                     ← USER-FACING PRODUCT. All 10 migration agents live here.
│                             Each agent is self-contained: instructions baked into the file.
├── migration-project-manager.agent.md   ← Orchestrator — invoke first
├── aws-discovery.agent.md               ← Phase 1
├── azure-architect.agent.md             ← Phase 2
├── iac-transformation.agent.md          ← Phase 3a (parallel)
├── code-refactor.agent.md               ← Phase 3b (parallel)
├── pipeline-builder-agent.agent.md      ← Phase 3c (parallel)
├── azure-deployer.agent.md              ← Phase 3d
├── deployment-validation.agent.md       ← Phase 4
├── skill-evolution-engine.agent.md      ← Meta: fix/improve existing skills
└── skill-generator-agent.agent.md       ← Meta: create new skills

commands/
└── run-migration.md        ← /run-migration slash command. Primary user entry point.

skills/                     ← 22 skills, each as skills/<name>/SKILL.md.
├── aws-inventory-scan/     ← aws-discovery
├── migration-assessment/   ← aws-discovery
├── architecture-design/    ← azure-architect
├── architecture-diagramming/ ← azure-architect
├── cost-analysis/          ← azure-architect
├── cost-estimator/         ← azure-architect
├── lambda-to-functions/    ← code-refactor
├── sdk-migration/          ← code-refactor
├── smoke-testing/          ← deployment-validation
├── what-if-validation/     ← deployment-validation
├── module-organization/    ← iac-transformation
├── parameter-management/   ← iac-transformation
├── github-actions-oidc/    ← pipeline-builder
├── multi-env-strategy/     ← pipeline-builder
├── workflow-generation/    ← pipeline-builder
├── orchestration/          ← migration-pm
├── phase-delegation/       ← migration-pm
├── aws-to-azure-mapping/   ← shared
├── azure-auth-patterns/    ← shared
├── azure-security-patterns/ ← shared
├── bicep-generation/       ← shared
└── task-tracking/          ← shared

.github/
├── agents/                 CI-only agents (not shipped). PR reviewers, triage bots.
├── instructions/           Per-agent instruction overlays for VS Code agent mode.
├── workflows/              CI/CD: unit-tests, skill-security-scan, evals, release automation.
├── actions/                Composite actions (install-waza).
├── skills/                 Mirror of skills/ used by CI agents.
└── scripts/
    ├── release/            extract-version.sh · extract-changelog.sh · create-tag-and-release.sh
    ├── security/           run-skillspector-scan.sh · check-skillspector-threshold.sh
    └── test/               Install-Pester.ps1 · install-bats.sh

tests/
├── unit/                   Pester (.Tests.ps1) + bats (.bats) unit tests for all skill scripts
└── evals/                  Waza YAML evaluation task suites

visualizer/                 Migration Dashboard — Vite SPA. Not part of the plugin.
docs/                       Extended documentation and design specs.
```

---

## Migration Pipeline

```
/run-migration
      │
      ▼
migration-project-manager   ← Orchestrates all phases
      │
      ├─► Phase 1:  aws-discovery            → outputs/aws-migration-artifacts/
      │
      ├─► Phase 2:  azure-architect          → outputs/azure-architecture-output/
      │
      ├─► Phase 3a: iac-transformation       → outputs/bicep-templates/        ┐
      ├─► Phase 3b: code-refactor            → outputs/azure-functions/         ├─ parallel
      ├─► Phase 3c: pipeline-builder-agent   → .github/workflows/               ┘
      │
      ├─► Phase 3d: azure-deployer           → deploys to Azure
      │
      └─► Phase 4:  deployment-validation    → outputs/validation-report.md
```

---

## The Agents

All agents live in [`agents/`](agents/). Instructions are baked directly into each agent file — no separate instruction overlays needed for plugin users.

![Agent Orchestration — One Prompt, Full Pipeline](assets/d2f90bf1-f01e-4b82-9ec7-0914d11bedf2.jpg)

### `@migration-project-manager`
The orchestrator. Runs all phases in dependency order (Discovery → Architecture → IaC + Code Refactor + Pipelines in parallel → Deploy → Validation), verifies output artifacts after each phase, and maintains a live task plan at `outputs/migration-task-plan.md`.

### `@aws-discovery`
Read-only discovery of all AWS resources using the AWS Cloud Control API MCP server. Scans all enabled regions and produces:
- `outputs/aws-migration-artifacts/aws-inventory.json` — complete resource list with metadata
- `outputs/aws-migration-artifacts/architecture-diagram.mmd` — Mermaid diagram of the AWS topology
- `outputs/aws-migration-artifacts/dependency-matrix.csv` — service dependency relationships
- `outputs/aws-migration-artifacts/migration-assessment.md` — complexity ratings and effort estimates
- `outputs/aws-migration-artifacts/cloudformation-template.yaml` — captured stack template

![Phase 1: Discovery](assets/Slide12.JPG)

### `@azure-architect`
Maps AWS services to Azure equivalents, produces a full architecture design document (11 sections), and generates Mermaid diagrams, service mapping tables, and cost comparisons using Microsoft Learn MCP. Outputs:
- `outputs/azure-architecture-output/design-document.md`
- `outputs/azure-architecture-output/architecture-diagram-azure.mmd`
- `outputs/azure-architecture-output/service-mapping.md`
- `outputs/azure-architecture-output/cost-comparison.md`

![Phase 2: Architecture Design](assets/Slide13.JPG)

### `@iac-transformation`
Converts AWS CloudFormation to grouped, subscription-scoped Azure Bicep orchestrators (`main.<group>.bicep`) that call AVM modules directly, without local resource modules. Generates per-group parameter files at `parameters/<env>/<group>.bicepparam` for `dev`, `staging`, and `prod`. Outputs write to `outputs/bicep-templates/`.

### `@code-refactor`
Rewrites Python Lambda handlers to Azure Functions v2 (decorator model). Replaces `boto3` with `azure-storage-blob` + `azure-identity`. Updates the frontend to remove AWS SDK dependencies. Outputs write to `outputs/azure-functions/` and `outputs/static-web-app/`.

![Phase 3: Code Refactor](assets/Slide15.JPG)

### `@pipeline-builder-agent`
Designs and builds GitHub Actions CI/CD pipelines for Azure deployment using OIDC / Workload Identity Federation (no long-lived credentials). Generates three workflows for infra, functions, and static web app deployments.

### `@azure-deployer`
Deploys generated Bicep templates and Azure Functions to the target subscription with three fallback strategies: Azure CLI → Azure PowerShell → Bicep direct. Verifies successful deployment via smoke tests.

### `@deployment-validation`
Runs a 15-point static validation checklist across all generated artifacts: Bicep syntax, security posture, policy compliance, RBAC correctness, smoke test readiness, and AWS vs Azure functional parity. Outputs `outputs/validation-report.md`.

![Phase 4: Deploy & Validate](assets/Slide16.JPG)

### `@skill-evolution-engine`
Meta-agent. Diagnoses and fixes issues in existing skills — invoke when a skill produces incorrect output or is missing edge cases.

### `@skill-generator-agent`
Meta-agent. Creates new skill files and wires them into the correct agent. Invoke when a migration scenario needs a new capability not covered by existing skills.

---

## Skills

22 skills distributed across 8 agent categories. Each skill is a structured Markdown file with a description, usage pattern, and embedded cross-platform scripts where needed.

| Domain | Skills |
|---|---|
| AWS Discovery | aws-inventory-scan · migration-assessment |
| Azure Architecture | architecture-design · architecture-diagramming · cost-analysis · cost-estimator |
| Code Refactor | lambda-to-functions · sdk-migration |
| IaC Transformation | module-organization · parameter-management |
| Deployment Validation | smoke-testing · what-if-validation |
| Pipeline Builder | github-actions-oidc · multi-env-strategy · workflow-generation |
| Migration PM | orchestration · phase-delegation |
| Shared | aws-to-azure-mapping · azure-auth-patterns · azure-security-patterns · bicep-generation · task-tracking |

All skills with scripts ship dual implementations:
- **`scripts/<name>.sh`** — Bash (macOS / Linux / WSL)
- **`scripts/<name>.ps1`** — PowerShell (pwsh 7+ recommended; `powershell.exe` 5.1 supported)

Runtime detection order: Bash (preferred) → `pwsh` → `powershell.exe`.

---

## Testing & Quality

### Unit Tests

Tests live in [`tests/unit/`](tests/unit/). Every skill script has both a Pester and a bats test file.

| Framework | Files | Run locally |
|---|---|---|
| bats (Bash) | `*.bats` | `bash tests/unit/run-bats-tests.sh` |
| Pester (PowerShell) | `*.Tests.ps1` | `pwsh tests/unit/Run-PesterTests.ps1` |

### SkillSpector Security Scan

All skill Markdown files are scanned by [NVIDIA SkillSpector](https://github.com/nvidia/skillspector) on every PR to `dev`. The scan checks for prompt injection, jailbreaking patterns, and capability over-claiming. PRs are blocked if the score falls below the configured threshold.

### Waza Evaluations

LLM-in-the-loop evaluations run via [Waza](https://github.com/microsoft/waza). Configuration is in [`.waza.yaml`](.waza.yaml); task suites live in [`tests/evals/`](tests/evals/).

### Eval Metrics Scorecard (Targets + 1:1 Criteria)

- Canonical scorecard: [`tests/evals/cloud-avengers/scorecard.yaml`](tests/evals/cloud-avengers/scorecard.yaml)
- Reusable template: [`tests/evals/cloud-avengers/scorecard-template.yaml`](tests/evals/cloud-avengers/scorecard-template.yaml)
- CI validation: `tests/check-eval-scorecard.sh` enforces one-to-one mapping between eval `task_id`s and scorecard rows.
- Agent coverage is supported through `owner_type: agent` entries and `agent:<agent-name>` task tags.

### Per-Skill Eval Suites

- Each skill has its own eval suite at: `tests/evals/cloud-avengers/skills/<skill-name>/eval.yaml`
- Each skill has at least one dedicated trigger task at: `tests/evals/cloud-avengers/tasks/skills/<skill-name>/should-trigger.yaml`
- Run one skill suite:
  - `bash tests/evals/run-skill-eval.sh <skill-name> [model]`
- Run all skill suites:
  - `bash tests/evals/run-all-skill-evals.sh [model]`

---

## CI/CD (Repository Pipelines)

All PRs to `dev` must pass these checks before merging:

| Workflow | Trigger | What it does |
|---|---|---|
| `unit-tests.yml` | PR to `dev` | Runs bats + Pester unit tests across all skill scripts |
| `skill-security-scan.yml` | PR to `dev` | Runs SkillSpector scan; blocks on threshold failure |
| `skill-security-scan-upload.yml` | Push to `main` | Uploads SkillSpector results to GitHub Advanced Security |
| `eval.yml` | PR to `dev` | Runs Waza LLM mock evaluations |
| `create-release-pr.yml` | PR merge to `dev` (title: `version: `) | Auto-creates a `release: vX.Y.Z` PR from `dev → main` |
| `create-release.yml` | Release PR merge to `main` | Creates git tag + GitHub Release with CHANGELOG notes |

---

## Release Process

Releases are **fully automated**. To cut a new version:

1. Bump `"version"` in [`.claude-plugin/plugin.json`](.claude-plugin/plugin.json) (semver `X.Y.Z`).
2. Add a `## [X.Y.Z] - YYYY-MM-DD` section to [`CHANGELOG.md`](CHANGELOG.md).
3. Open a PR to `dev` with the title prefix `version: ` (e.g. `version: bump to 1.1.0`).
4. When the PR merges, `create-release-pr.yml` auto-creates a `release: vX.Y.Z` PR to `main`.
5. Approve and merge the release PR — `create-release.yml` tags and publishes the GitHub Release automatically.

> **Never** push directly to `main`, create tags manually, or create GitHub Releases by hand.

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the full contribution guide.

---

## Branch Protection Setup

| Branch | Rules |
|---|---|
| `main` | Require PR · 1 required reviewer · All status checks must pass · No direct pushes |
| `dev` | Require PR · All status checks must pass (`unit-tests`, `skill-security-scan`, `eval`) |

Required secrets for CI:

| Secret | Used by | Purpose |
|---|---|---|
| `COPILOT_GITHUB_TOKEN` | `eval.yml` | Fine-grained PAT with "Copilot Requests" permission for Waza |
| `GH_TOKEN` | Release workflows | PAT for creating PRs and GitHub Releases |

---

## The Visualizer

[`visualizer/`](visualizer/) contains a live **Migration Dashboard** — a Vite-powered single-page app that shows the real-time status of any migration run.

- **Phase cards** with status badges (not started / in progress / completed)
- **Artifact file viewer** — opens any generated artifact (JSON, CSV, Markdown, Mermaid, YAML) in the browser
- **Mermaid diagram renderer** — renders AWS and Azure architecture diagrams side-by-side
- **30-second auto-refresh** — polls `outputs/migration-task-plan.md` so the dashboard stays live

```bash
cd visualizer
npm install
npm run dev        # opens at http://localhost:5173
npm run build      # build for static hosting
```

---

## Sample Migration

[`Sample-Migrations/`](Sample-Migrations/) contains a complete worked example: an AWS serverless **Image Upload Service** (4 Lambda functions + S3 + API Gateway) migrated end-to-end to Azure.

```
Sample-Migrations/
  app-code/           # Original AWS Lambda source (Python 3.11) + frontend + SAM template
  outputs/
    aws-migration-artifacts/    # Phase 1: Discovery
    azure-architecture-output/  # Phase 2: Architecture
    azure-functions/            # Phase 3b: Refactored Azure Functions
    bicep-templates/            # Phase 3a: 6 Bicep modules + 3 parameter files
    migration-task-plan.md      # All phases ✅
    validation-report.md        # 15/15 checks PASSED
  doc/                # Extended documentation
```

---

## Design Principles

**Agents operate through MCP servers, not CLI.** All agents use AWS and Azure MCP servers for resource discovery and documentation — no hardcoded shell commands inside agent workflows. This keeps agents portable and cross-platform.

**Managed Identity replaces IAM keys.** AWS IAM roles and access keys are replaced by Azure System-Assigned Managed Identity with fine-grained RBAC. No credentials in environment variables or code.

**Pre-signed URL pattern is preserved.** Clients upload/download directly to storage; the API generates short-lived SAS URLs. This maps cleanly from S3 pre-signed URLs to Azure Blob SAS tokens using user-delegation keys.

**Bicep is modular and AVM-aligned.** Generated templates use Azure Verified Modules where available, are subscription-scoped, and include environment-specific parameter files validated before deployment.

**Dual-shell scripts everywhere.** Every skill script ships a `.sh` (Bash) and `.ps1` (PowerShell) implementation with identical output, so the plugin works on any developer machine.

---

## Technology Stack

### MCP Servers

| MCP Server | Used by | Purpose |
|---|---|---|
| AWS Cloud Control API MCP | `@aws-discovery` | Read-only AWS resource enumeration |
| AWS Knowledge MCP | `@aws-discovery`, `@azure-architect`, `@code-refactor` | AWS service documentation lookups |
| Microsoft Learn MCP | `@azure-architect`, `@iac-transformation`, `@code-refactor` | Azure docs and AVM module references |
| Azure MCP | `@azure-architect`, `@iac-transformation`, `@deployment-validation` | Live Azure resource information |
| Mermaid Chart MCP | `@azure-architect` | Diagram generation and syntax validation |

### Azure Runtime (generated output targets)
- **Azure Functions v4** — Python 3.11, Consumption plan, v2 decorator model
- **Azure Blob Storage** — Hot tier, Standard LRS (dev) / ZRS (prod), Managed Identity access
- **Azure Static Web Apps** — Free tier, `index.html` required as entry point
- **Application Insights + Log Analytics** — structured logging, distributed traces
- **Azure Key Vault** — Standard tier, soft-delete + purge protection enabled

---

## Known Gotchas

These issues were encountered during the first migration run and are captured inside the relevant agent definitions so future runs avoid them automatically:

1. **Python version** — Azure Functions v4 supports Python 3.9–3.11 only. Python 3.12/3.13 crash the worker (`0xC0000005`). Always create the venv with Python 3.11: `python3.11 -m venv .venv`
2. **Reserved environment variable** — `CONTAINER_NAME` is reserved by the Azure Functions host. Use `BLOB_CONTAINER_NAME` for Blob Storage container references.
3. **Static Web Apps entry point** — Azure Static Web Apps requires `index.html` as the default file. A standalone `app.html` is not served as the root without a `staticwebapp.config.json` routing rule.
4. **SAS token generation** — Use `get_user_delegation_key()` from `BlobServiceClient` (Managed Identity path) rather than storage account keys.
5. **APIM is optional** — For simple Lambda + API Gateway → Azure Functions migrations, HTTP triggers are a direct equivalent. Add APIM only when gateway-layer features (rate limiting, request transformation, developer portal) are explicitly required.

---

## Requirements

**Tooling:**
- VS Code with GitHub Copilot extension (agent mode enabled)
- GitHub Copilot subscription
- MCP servers: AWS Cloud Control API · AWS Knowledge · Microsoft Learn · Azure · Mermaid Chart
- Bash + `curl` + `jq`, or PowerShell 5.1+ (for skill scripts)

**Permissions:**
- **AWS (source):** IAM `ReadOnlyAccess` policy minimum
- **Azure (target):** `Contributor` + `User Access Administrator` on the target subscription (required for RBAC module in Bicep)

---

## Key Takeaways

![Key Takeaways](assets/Slide22.JPG)
