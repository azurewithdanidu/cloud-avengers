# Phase 4 — Validation Repair Loop (MAX_VALIDATION_ITERATIONS = 3)

Requires: Phase 3a, 3b, and 3c all passed artifact checks (see [../references/artifact-checklist.md](../references/artifact-checklist.md)).

Phase 4 is a self-healing loop — never mark ❌ on the first failure without attempting repair.

## Failure Categorization Table

Every failing check from `outputs/validation-report.md` is assigned one category:

| Category | Signal | Auto-fixable? |
|---|---|---|
| A — Bicep/IaC | Wrong property, missing resource, security config not applied, wrong SKU | Yes — @iac-transformation |
| B — Skill/Agent | Failure pre-deploy evals should have caught (eval gap), or agent produced insecure config | Yes — @skill-evolution-engine + new eval check |
| C — Environment | Quota, region capacity, Azure Policy, PE approval pending, RBAC propagation | No — human intervention |

A failure can be both A and B. Fix the Bicep (A) AND update the skill and add an eval check (B).

## Loop Procedure (for each iteration V = 1…3)

**Step 4.V.1** — Invoke @deployment-validation.

**Step 4.V.2** — Read `outputs/validation-report.md`.
- `PASSED` → ✅ done.
- `FAILED` → categorize all failures per the table above.

**Step 4.V.3** — If any Category C failure: mark Phase 4 ❌ `"Human intervention required"`, stop.

**Step 4.V.4** — Apply fixes (Category B first, then A):

Category B → @skill-evolution-engine:
```
Fix the skill/agent that caused or failed to catch: <failures>
Add new eval check to evals/checks/ + fixture to evals/fixtures/ + entry to evals/evals-dataset.json
```

Category A → @iac-transformation:
```
Fix Bicep for: <failures>. Targeted fixes only. Write to outputs/bicep-templates/
```

**Step 4.V.5** — EVAL GATE (blocks re-deploy):

Run: `python3 -m evals.run_evals --report evals/evals-report.json`

- ≥ 90% → proceed to re-deploy.
- < 90% → fix the failing checks, re-run evals once more. If still < 90% → mark ❌, stop.

**Step 4.V.6** — Re-deploy: re-enter Phase 3 IaC-Deploy loop (counter continues, does not reset). After Phase 3 exits ✅: increment V, return to Step 4.V.1.

**Step 4.V.7** — MAX_ITERATIONS reached: mark ❌, write full report to `outputs/migration-task-plan.md`, stop.

## Mitigation 1 — Fixture verification after eval code generation

When @skill-evolution-engine writes a new eval check (Python code), the PM MUST immediately run:

```bash
python3 -m evals.run_evals --fixture
```

If fixture self-test exits non-zero (exit code 2), the new check is buggy. Invoke @skill-evolution-engine again to fix the check before proceeding.

**NEVER trust an LLM-generated eval check without running `--fixture`.**

## Mitigation 2 — Category C misclassification guard

If the **same failure message** appears in two consecutive validation iterations unchanged, reclassify it as Category C regardless of initial classification. Add to Blockers:

```
Same failure persisted across 2 iterations — likely environment issue requiring human intervention.
```

Stop the Phase 4 loop immediately.

## Mitigation 3 — Combined iteration counter

Write the combined Phase 3+4 total iteration count explicitly to `outputs/migration-task-plan.md` as a running number (not reconstructed from any log file).

Format in task plan:
```
Total deploy attempts (Phase 3+4): N
```

Update this after every Phase 3 iteration AND every Phase 4 re-deploy. Use this number for `MAX_ITERATIONS` checks, not a reconstructed count from a log.

Next: [Post-phase verification workflow](04-verification-workflow.md) still applies to every Phase 4 iteration.
