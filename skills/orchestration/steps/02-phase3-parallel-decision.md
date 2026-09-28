# Phase 3 Parallel/Serial Decision

Requires: Phase 2 artifacts already verified (see [../references/artifact-checklist.md](../references/artifact-checklist.md)).

Use this decision tree every time Phase 3 is reached or resumed:

```text
Have Phase 2 artifacts passed verification?
├─ No  → Stop. Fix or rerun Phase 2.
└─ Yes
   ↓
How many of 3a, 3b, 3c are not yet ✅?
├─ 3 incomplete → Launch 3a + 3b + 3c in one batched parallel block.
├─ 2 incomplete → Launch the two incomplete streams in parallel.
├─ 1 incomplete → Run only the remaining stream serially.
└─ 0 incomplete → Do not rerun Phase 3; proceed to Phase 4.
```

Additional rules:

- `full` runs from the start always launch all three Phase 3 streams together.
- `resume parallel` launches only the incomplete streams, but still launches them together when more than one remains.
- `phase 3a`, `phase 3b`, or `phase 3c` isolation requests are allowed to run serially because the user explicitly asked for a single stream.
- Verification can happen serially after the parallel launch completes, but invocation should not be artificially serialized when more than one stream remains.

Read `design-document.md` Sections 5, 6, and 11 after Phase 2 and expand the Phase 3 task lists before any Phase 3 verification is finalized.

Next, once all Phase 3 streams pass: [Phase 4 validation loop](03-phase4-validation-loop.md).
