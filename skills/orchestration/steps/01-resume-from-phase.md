# Resume-From-Phase Procedure

Follow this exact recovery workflow whenever a run starts with `resume <phase>` or `status`.

1. Read the latest `outputs/migration-task-plan.md`.
2. Identify the requested resume point or the first phase that is not `✅`.
3. Re-run artifact checks for every prerequisite phase (see [../references/artifact-checklist.md](../references/artifact-checklist.md)).
4. If a prerequisite row shows `✅` but the artifact check fails, immediately change that row to `❌`, add a blocker, and stop.
5. If a prerequisite row is stale (`⏳` or `🔄`) but all required artifacts exist and pass checks, repair the row to `✅` and write the recovery timestamp.
6. Mark the resumed phase `🔄` only after prerequisites pass.
7. Re-read the plan again before each write so concurrent updates are not lost.

## Resume `discovery`

- Allowed when no later phase has valid artifacts yet, or when Phase 1 artifacts are missing or invalid.
- Before running, confirm that later phases are either `⏳`, `🔄`, or already marked `❌` because of discovery issues.
- After success, reset downstream phases only if their artifacts are now inconsistent with the new discovery set.

## Resume `architecture`

- Require all Phase 1 artifacts to exist and be non-empty.
- Re-check these paths before invoking the architect:
  - `outputs/aws-migration-artifacts/aws-inventory.json`
  - `outputs/aws-migration-artifacts/architecture-diagram.mmd`
  - `outputs/aws-migration-artifacts/dependency-matrix.csv`
  - `outputs/aws-migration-artifacts/migration-assessment.md`
- If any are missing, downgrade the run to `resume discovery` and record why.

## Resume `parallel`

- Require all Phase 2 artifacts to exist and be non-empty.
- Re-check these paths before invoking any Phase 3 stream:
  - `outputs/azure-architecture-output/design-document.md`
  - `outputs/azure-architecture-output/architecture-diagram-azure.mmd`
  - `outputs/azure-architecture-output/cost-comparison.md`
  - `outputs/azure-architecture-output/service-mapping.md`
- Inspect Phase 3a, 3b, and 3c individually:
  - if two or three streams are incomplete, launch all incomplete streams in parallel
  - if exactly one stream is incomplete, rerun only that stream
  - if any stream is `❌`, repair or re-delegate only the failing stream unless the architecture artifact changed

## Resume `validation`

- Require all completed Phase 3 streams to pass artifact checks.
- If any Phase 3 artifact is missing or invalid, do not run validation; route back to the failing stream.
- Only when 3a, 3b, and 3c all pass may Phase 4 start.

Next: [Phase 3 parallel/serial decision](02-phase3-parallel-decision.md) or, if all of Phase 3 already passed, [Phase 4 validation loop](03-phase4-validation-loop.md).
