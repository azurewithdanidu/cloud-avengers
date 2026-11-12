# Verification Workflow After Each Phase

Apply this after every phase claims completion, including every Phase 4 loop iteration.

1. Read the worker response for claimed output paths.
2. Ignore the success claim until the artifacts are opened and checked.
3. Verify file existence first.
4. Verify non-empty content second.
5. Run the applicable executable validators and require exit code 0, then verify content assertions — see [../references/artifact-checklist.md](../references/artifact-checklist.md). A validator error or missing runtime is a phase blocker.
6. Update `outputs/migration-task-plan.md` only after the checks pass.
7. If any check fails, add a blocker entry immediately using the format in [../references/error-escalation-runbook.md](../references/error-escalation-runbook.md).
