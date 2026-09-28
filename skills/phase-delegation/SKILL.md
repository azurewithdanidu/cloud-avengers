---
name: phase-delegation
description: 'Delegate each migration phase with consistent prompts and verifiable outputs. Use when: sending work to aws-discovery, azure-architect, iac-transformation, code-refactor, pipeline-builder-agent, or deployment-validation and checking returned artifacts for completeness.'
---

# Phase Delegation Skill

## Purpose

Standardize phase handoffs so every worker receives the same instructions, writes to the same paths, updates the shared task plan correctly, and returns artifacts that can be verified objectively.

## When to Use

- Whenever orchestration decides the next phase to run
- When rerunning a failed phase
- When resuming a migration after a partial stop
- When auditing whether a worker produced enough output to count as complete

## Inputs

| Path | Why it is required |
|---|---|
| `outputs/migration-task-plan.md` | Shared status file the worker must update only within its phase section |
| `source-app/` | Read-only application source and docs |
| `outputs/aws-migration-artifacts/` | Required before Phase 2 |
| `outputs/azure-architecture-output/` | Required before Phase 3 and Phase 4 |
| `outputs/bicep-templates/` | Required before Phase 4 |
| `outputs/azure-functions/` | Required before Phase 4 |
| `.github/workflows/` | Required before Phase 4 |

## Outputs

| Path | Result |
|---|---|
| `outputs/aws-migration-artifacts/` | Phase 1 artifacts |
| `outputs/azure-architecture-output/` | Phase 2 artifacts |
| `outputs/bicep-templates/` | Phase 3a artifacts |
| `outputs/azure-functions/` | Phase 3b artifacts |
| `.github/workflows/` | Phase 3c artifacts |
| `outputs/validation-report.md` | Phase 4 artifact |

## Process

1. Read `outputs/migration-task-plan.md` before delegating.
2. Confirm prerequisite artifacts exist for the target phase.
3. Copy the exact prompt block for the phase.
4. Replace only placeholder values such as `<AWS_ACCOUNT_ID>` and `<AWS_REGION>`.
5. Do not paraphrase or shorten the prompt.
6. After the worker returns, verify every required artifact listed for that phase.
7. If any assertion fails, follow the re-delegation procedure at the end of this file.


## Exact Phase Prompts and Acceptance Checks

Load only the file for the phase currently being delegated:

| Phase | File |
|---|---|
| 1 — AWS Discovery → `@aws-discovery` | [references/phase1-aws-discovery.md](references/phase1-aws-discovery.md) |
| 2 — Architecture → `@azure-architect` | [references/phase2-architecture.md](references/phase2-architecture.md) |
| 3a — IaC Transformation → `@iac-transformation` | [references/phase3a-iac-transformation.md](references/phase3a-iac-transformation.md) |
| 3b — Code Refactor → `@code-refactor` | [references/phase3b-code-refactor.md](references/phase3b-code-refactor.md) |
| 3c — Pipeline Build → `@pipeline-builder-agent` | [references/phase3c-pipeline-build.md](references/phase3c-pipeline-build.md) |
| 4 — Validation → `@deployment-validation` | [references/phase4-validation.md](references/phase4-validation.md) |

Each file contains the exact copy-paste prompt (only replace `<placeholder>` values — never paraphrase) and the artifact acceptance checks for that phase.

## Re-delegation Procedure for Incomplete Artifacts

Use this workflow when a phase returns but the artifact checks do not pass:

1. Read the returned artifacts and list the exact failing assertions.
2. Update `outputs/migration-task-plan.md` with the failing phase status:
   - keep `🔄` only if you are immediately retrying once
   - use `❌` if a blocker must be surfaced before retry
3. Re-read the prerequisite inputs to ensure the worker did not fail because of missing upstream context.
4. Re-send the same phase prompt unchanged, then append this repair section:

```text
Repair Request:
- Reuse the same output paths.
- Fix only the failed assertions listed below.
- Do not overwrite valid artifacts unnecessarily.
- Failed assertions:
  - <assertion 1>
  - <assertion 2>
```

5. Verify the repaired artifacts again from disk.
6. If the second attempt still fails the same assertion, stop, mark the phase `❌`, and record a blocker with the broken file path and next owner action.

## Edge Cases / Failure Modes

- **Worker wrote to the wrong directory:** treat as failed even if the content is good; the pipeline depends on exact paths.
- **Worker updated the wrong phase rows:** preserve evidence, correct the plan, and note the conflict if it obscures ownership.
- **Partial success:** accept only the subset that passed, but do not mark the phase `✅` until all required artifacts pass.
- **Upstream ambiguity:** if the design document is missing detail, route the failure back to architecture instead of improvising in Phase 3 or Phase 4.
- **Whitespace-only output or stub headings:** fail the artifact; placeholders are not deliverables.

## Rules

- **Always send the exact prompt block.**
- **Always verify artifacts from the filesystem, not from chat text.**
- **Never change output paths unless the architecture skill itself changed the contract.**
- **Never accept a phase with only some required artifacts present.**
- **Never let a downstream phase compensate for an upstream missing artifact.**

## Best Practices

- Keep failure feedback concrete: file path plus failed assertion.
- Re-delegate once for repairable defects; escalate quickly when the upstream contract is the real problem.
- Substitute placeholders only; any wording drift in the prompt increases output variance.
- Use the task-tracking skill conventions during every retry so the plan remains trustworthy.

---

## References

### Microsoft / Azure Documentation

| Topic | Link |
|---|---|
| Azure Migrate — migration execution guide | https://learn.microsoft.com/en-us/azure/migrate/migrate-services-overview |
| Cloud Adoption Framework — migration checklist | https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/migrate/azure-migration-guide/migrate |
| Cloud Adoption Framework — validate and promote | https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/migrate/azure-migration-guide/optimize-and-transform |

### AWS Documentation

| Topic | Link |
|---|---|
| AWS Migration Hub — tracking migrations | https://docs.aws.amazon.com/migrationhub/latest/ug/tracking-migration-tasks.html |
| AWS Migration Evaluator | https://aws.amazon.com/migration-evaluator/ |

### Best Practices

- **Prompts are contracts** — the exact wording and output paths matter because downstream verification depends on them.
- **A missing or malformed file is a phase failure, not a cosmetic issue** — capture it precisely and route it to the right owner.
- **Repair only what failed** — preserve valid work when issuing a re-delegation request.
