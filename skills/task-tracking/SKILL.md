---
name: task-tracking
description: 'Keep outputs/migration-task-plan.md synchronized with real migration progress. Use when: creating the task plan, updating phase rows, resolving concurrent writes, recording blockers, or resuming a six-phase migration run.'
---

# Task Tracking Skill

## Purpose

Maintain `outputs/migration-task-plan.md` as the durable, phase-by-phase control plane for the migration. Every worker agent updates only its own rows and checkboxes; the plan must always match artifact reality.

## When to Use

- At migration initialization, before Phase 1 starts
- At the start and end of every phase
- Immediately after any task-level artifact is produced
- When a retry, blocker, or resume event changes phase state
- Whenever two or more agents may touch `outputs/migration-task-plan.md` concurrently

## Inputs

| Path | Purpose |
|---|---|
| `outputs/migration-task-plan.md` | File to create, read, update, and reconcile |
| `outputs/aws-migration-artifacts/` | Phase 1 artifact evidence |
| `outputs/azure-architecture-output/` | Phase 2 artifact evidence |
| `outputs/bicep-templates/` | Phase 3a artifact evidence |
| `outputs/azure-functions/` | Phase 3b artifact evidence |
| `.github/workflows/` | Phase 3c artifact evidence |
| `outputs/validation-report.md` | Phase 4 artifact evidence |

## Outputs

| Path | Result |
|---|---|
| `outputs/migration-task-plan.md` | Complete migration plan with status summary, detailed tasks, timestamps, and blockers |

## Process


### 1. Create the plan at migration start

If `outputs/migration-task-plan.md` does not exist, create it using the full template in
[references/task-plan-template.md](references/task-plan-template.md) — copy it exactly, including
the Status Legend and Blockers section.

### 2. Update rules during execution

**On phase start:**

1. Re-read the plan.
2. Change the phase row from `⏳` to `🔄`.
3. Update `Last Updated:`.
4. If this is a resume, also update `Current Resume Point:`.

**On task completion:**

1. Re-read the plan.
2. Change the specific `- [ ]` task to `- [x]`.
3. Append `— completed <UTC-ISO-8601>`.
4. Update `Last Updated:`.

**On phase completion:**

1. Re-read the plan.
2. Set the phase row to `✅`.
3. Write the `Completed At` timestamp.
4. Update `Current Resume Point:` to the next incomplete phase.
5. Update `Last Updated:`.

**On blocker or failure:**

1. Re-read the plan.
2. Set the phase row to `❌`.
3. Add or replace a bullet under `## Blockers` using the required format.
4. Update `Last Updated:`.
5. Stop writing unrelated plan changes.

### 3. Concurrent-write conflict resolution

Use this optimistic-lock pattern whenever multiple agents may write the same file:

1. **Read** the latest `outputs/migration-task-plan.md`.
2. **Prepare** a minimal edit affecting only your phase row and your phase task list.
3. **Re-read immediately before write**.
4. **Compare** the second read against the version you based your edit on.
5. If the file changed:
   - replay your edit onto the newest copy
   - never revert another phase from `✅` to `⏳`
   - never delete another agent's completion timestamp
6. **Write** the merged version.
7. If another change lands between steps 5 and 6, retry up to three times.
8. On the third failed retry, add a blocker noting a plan write conflict and stop.

#### Merge precedence rules

| Conflict type | Resolution |
|---|---|
| Same phase row, one copy is `❌` | Keep `❌` until artifacts are re-verified |
| Same task checkbox, one copy is `[x]` | Keep `[x]`; never downgrade to `[ ]` |
| Different timestamps for same completed item | Keep the newer timestamp only if the artifact still exists |
| Another phase changed while your phase did not | Replay your edit onto the newer file |
| Another phase inserted a blocker | Preserve it; append yours below if needed |

### 4. Timestamp format examples

Use UTC ISO 8601 timestamps only inside the plan file.

**Good examples**

- `2026-07-14T00:14:16Z`
- `2026-07-14T00:21:39Z`
- `Generated: 2026-07-14T00:14:16Z`
- `Last Updated: 2026-07-14T00:42:07Z`
- `- [x] Write outputs/aws-migration-artifacts/aws-inventory.json — completed 2026-07-14T00:21:39Z`

**Bad examples**

- `14/07/2026 10:14 PM`
- `2026-07-14 00:14:16`
- `Tue Jul 14 00:14:16 2026`
- `2026-07-14T10:14:16+10:00` inside the plan file


### 5. Mid-migration example

See [references/task-plan-example-mid-migration.md](references/task-plan-example-mid-migration.md)
for a worked example of a plan filled in after Phase 2 completes and the parallel Phase 3 wave is
underway — use it to check your timestamp formatting and checkbox/status conventions match.

### 6. Edge Cases / Failure Modes

- **Empty Blockers section drift:** Replace `- None` only when the first real blocker is added; restore it only when all blockers are cleared and the phase has been rerun successfully.
- **Plan file missing during resume:** Recreate it from artifacts, then mark recovered phases `✅` only after re-verification.
- **Placeholder tasks left after Phase 2:** Do not start Phase 3 verification until placeholders are replaced with concrete items from the design document.
- **Out-of-order timestamps:** If a completion timestamp predates the phase start timestamp, treat it as a write error and correct it on the next update.
- **Worker updated another phase accidentally:** Preserve valid evidence but correct ownership and add a note in the blocker if the accidental edit caused ambiguity.

## Rules

- **Never mark `[x]` unless the underlying artifact exists and is non-empty.**
- **Never modify another phase section during a parallel run.**
- **Never use local time or mixed time zones in the plan file.**
- **Never remove evidence of a failure without re-running and re-verifying the phase.**
- **Always re-read before every write.**

## Best Practices

- Keep edits minimal and scoped to the phase you own.
- Add completion timestamps immediately, not at the end of the phase.
- Expand Phase 3 tasks from the design document as soon as Phase 2 finishes.
- Treat the plan as an audit artifact; future agents should be able to resume from it without chat history.
- Prefer blocker entries that point directly to the broken file path and next owner action.

---

## References

### Microsoft / Azure Documentation

| Topic | Link |
|---|---|
| Cloud Adoption Framework — project management | https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/manage/ |
| Azure DevOps work items | https://learn.microsoft.com/en-us/azure/devops/boards/work-items/about-work-items |

### GitHub Documentation

| Topic | Link |
|---|---|
| GitHub Projects — project tracking | https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/about-projects |
| GitHub Issues | https://docs.github.com/en/issues/tracking-your-work-with-issues/about-issues |

### Best Practices

- **Incremental updates beat batch updates** — they keep the plan reliable during long-running phases.
- **Optimistic locking is mandatory in parallel Phase 3 runs** — the plan is shared state.
- **UTC timestamps make resume logic deterministic** — no timezone math is required.
- **A checked box is an evidence claim** — only check it when the artifact can be opened and inspected.
