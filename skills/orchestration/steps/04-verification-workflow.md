# Verification Workflow After Each Phase

Apply this after every phase claims completion, including every Phase 4 loop iteration.

1. Read the worker response for claimed output paths.
2. Ignore the success claim until the artifacts are opened and checked.
3. Verify file existence first.
4. Verify non-empty content second.
5. Verify minimum content assertions third — see [../references/artifact-checklist.md](../references/artifact-checklist.md).
6. Update `outputs/migration-task-plan.md` only after the checks pass.
7. If any check fails, add a blocker entry immediately using the format in [../references/error-escalation-runbook.md](../references/error-escalation-runbook.md).
