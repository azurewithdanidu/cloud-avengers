---
name: orchestration
description: 'Coordinate the 6-phase AWS-to-Azure migration pipeline. Use when: starting a migration, resuming from discovery or architecture or parallel or validation, verifying artifacts, or escalating blockers in outputs/migration-task-plan.md.'
---

# Orchestration Skill

## Purpose

Coordinate the documented six-phase migration pipeline end to end, keep `outputs/migration-task-plan.md` authoritative, and advance only when upstream artifacts are present, non-empty, and minimally valid.

## When to Use

- At migration start, before any worker agent runs
- After any phase reports completion
- When resuming from `discovery`, `architecture`, `parallel`, or `validation`
- When a user asks for current status without running more work
- When any artifact check fails and a blocker or retry decision is needed

## Inputs

| Path | Why it matters |
|---|---|
| `outputs/migration-task-plan.md` | Durable source of truth for phase state, timestamps, and blockers |
| `outputs/aws-migration-artifacts/aws-inventory.json` | Required to prove Phase 1 completed |
| `outputs/aws-migration-artifacts/architecture-diagram.mmd` | Discovery architecture baseline |
| `outputs/aws-migration-artifacts/dependency-matrix.csv` | Dependency evidence for design and sequencing |
| `outputs/aws-migration-artifacts/migration-assessment.md` | Migration findings and risks |
| `outputs/azure-architecture-output/design-document.md` | Mandatory handoff artifact for all Phase 3 work |
| `outputs/azure-architecture-output/architecture-diagram-azure.mmd` | Azure target topology evidence |
| `outputs/azure-architecture-output/cost-comparison.md` | Cost decision evidence |
| `outputs/azure-architecture-output/service-mapping.md` | Service equivalence evidence |
| `outputs/bicep-templates/` | Phase 3a outputs to verify |
| `outputs/azure-functions/` | Phase 3b outputs to verify |
| `.github/workflows/` | Phase 3c outputs to verify |
| `outputs/validation-report.md` | Final validation artifact |

## Outputs

| Path | Expected state |
|---|---|
| `outputs/migration-task-plan.md` | Created at start, then updated after every verification step |
| `outputs/aws-migration-artifacts/` | Discovery artifacts verified before Phase 2 |
| `outputs/azure-architecture-output/` | Architecture artifacts verified before Phase 3 |
| `outputs/bicep-templates/` | IaC outputs verified before validation |
| `outputs/azure-functions/` | Refactored function outputs verified before validation |
| `.github/workflows/` | Pipeline outputs verified before validation |
| `outputs/validation-report.md` | Final `PASSED` or `FAILED` validation report |

## Process

### 1. Pre-flight

1. Read `outputs/migration-task-plan.md` if it already exists.
2. If the file does not exist, create it using the full template from `skills/task-tracking/SKILL.md`.
3. Record the current UTC timestamp in ISO 8601 format.
4. Confirm the run mode:
   - `full` or no argument
   - `resume discovery`
   - `resume architecture`
   - `resume parallel`
   - `resume validation`
   - `status`
5. If the request is `status`, do not invoke worker agents; only read and summarize.

### 2. Write the Phase Summary table at migration start

Copy this section exactly into `outputs/migration-task-plan.md` when initializing a migration:

```markdown
## Phase Summary

| Phase | Owner | Artifact Root | Status | Completed At |
|---|---|---|---|---|
| 1 — Discovery | aws-discovery | `outputs/aws-migration-artifacts/` | ⏳ | — |
| 2 — Architecture | azure-architect | `outputs/azure-architecture-output/` | ⏳ | — |
| 3a — IaC Transformation | iac-transformation | `outputs/bicep-templates/` | ⏳ | — |
| 3b — Code Refactor | code-refactor | `outputs/azure-functions/` | ⏳ | — |
| 3c — Pipeline Build | pipeline-builder-agent | `.github/workflows/` | ⏳ | — |
| 4 — Validation | deployment-validation | `outputs/validation-report.md` | ⏳ | — |
```

### 3. Standard execution order

```text
Phase 1 Discovery
    ↓
Phase 2 Architecture
    ↓
Phase 3a IaC  ─┐
Phase 3b Code ─┼─ run together when more than one Phase 3 stream is incomplete
Phase 3c CI/CD ┘
    ↓
Phase 4 Validation
```

1. Do not advance to a downstream phase until the current phase passes verification.
2. Treat Phase 3 as a coordination group, not a single artifact.
3. Read `design-document.md` Sections 5, 6, and 11 after Phase 2 and expand the Phase 3 task lists before any Phase 3 verification is finalized.


### 4. Resume-from-phase procedure

See [steps/01-resume-from-phase.md](steps/01-resume-from-phase.md) for the full per-phase resume rules (`resume discovery`, `resume architecture`, `resume parallel`, `resume validation`).

### 5. Artifact checklist per phase

See [references/artifact-checklist.md](references/artifact-checklist.md) for the required artifact and minimum-content assertion per phase. A phase is not complete until every listed artifact passes.

### 6. Decision tree: invoke Phase 3 in parallel or serial

See [steps/02-phase3-parallel-decision.md](steps/02-phase3-parallel-decision.md).

### 7. Phase 4 — Validation Repair Loop (MAX_VALIDATION_ITERATIONS = 3)

See [steps/03-phase4-validation-loop.md](steps/03-phase4-validation-loop.md) for the full self-healing loop, failure categorization table, and iteration mitigations.

### 8. Verification workflow after each phase

See [steps/04-verification-workflow.md](steps/04-verification-workflow.md).

### 9. Error escalation runbook and edge cases

See [references/error-escalation-runbook.md](references/error-escalation-runbook.md) for the severity table, blocker format, and known edge cases (stale success rows, partial Phase 3 completion, architecture drift, concurrent writes).

---

## Rules

- **Never trust an agent success message without reading the artifacts.**
- **Never advance to a later phase while an earlier prerequisite is `❌`.**
- **Never overwrite another phase row or task list during a parallel run.**
- **Never skip the `design-document.md` read before coordinating Phase 3.**
- **Never mark a phase `✅` if the artifact exists but is empty, placeholder-only, or structurally incomplete.**
- **Always stop after recording a blocker when the runbook says to stop.**

## Best Practices

- Keep the task plan open as the operational dashboard and re-read it before every update.
- Prefer the earliest valid resume point rather than patching downstream artifacts blindly.
- Treat Phase 2 as the contract for Phase 3; if the contract changes, verify all dependent work again.
- Write blocker messages that a different agent could act on without additional explanation.
- When fixing a failed phase, cite the exact artifact path and assertion that failed.

---

## References

### Microsoft / Azure Documentation

| Topic | Link |
|---|---|
| Azure Migrate overview | https://learn.microsoft.com/en-us/azure/migrate/migrate-services-overview |
| Cloud Adoption Framework — migrate | https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/migrate/ |
| Cloud Adoption Framework — migration landing zone | https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/migrate/azure-migration-guide/ |
| Azure DevOps migration guide | https://learn.microsoft.com/en-us/azure/devops/migrate/migration-overview |

### AWS Documentation

| Topic | Link |
|---|---|
| AWS Migration Hub | https://docs.aws.amazon.com/migrationhub/latest/ug/whatishub.html |
| AWS Migration Acceleration Program | https://aws.amazon.com/migration-acceleration-program/ |
| AWS 7 Rs migration strategies | https://docs.aws.amazon.com/prescriptive-guidance/latest/migration-retiring-applications/apg-gloss.html |

### Best Practices

- **Phase 3 parallelism is a throughput optimization, not a correctness shortcut** — prerequisite validation still happens before and after the parallel wave.
- **Artifacts beat memory** — the plan file and generated outputs are the source of truth, not prior agent replies.
- **Resume by evidence** — use the earliest invalid artifact, not the latest claimed status, to decide where to restart.
- **Block fast, unblock precisely** — each blocker should name the broken file, the failed assertion, and the next owner action.
