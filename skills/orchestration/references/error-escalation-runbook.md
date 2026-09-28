# Error Escalation Runbook

Use this runbook to keep failures consistent and recoverable.

| Severity | Trigger | Required response |
|---|---|---|
| Level 1 — Missing file | Expected artifact path does not exist | Re-read the phase prompt, re-delegate once with the missing file list, keep phase `🔄` during retry |
| Level 2 — Empty or malformed file | File exists but is empty, whitespace-only, or lacks required headings/content | Mark the phase `❌`, record the exact failing assertion, then re-delegate only if the defect is repairable without changing upstream design |
| Level 3 — Upstream/downstream mismatch | Phase output contradicts a prerequisite artifact, for example Bicep modules not present in Section 5 | Mark the current phase `❌`, add a blocker naming the conflicting upstream source, stop and route back to the prerequisite phase owner |
| Level 4 — External dependency failure | Credentials, MCP servers, required tooling, or repository permissions unavailable | Mark the phase `❌`, note the external dependency in `## Blockers`, stop and surface the unblock action |

**Blocker format:**

```markdown
- Phase <phase-id> (<owner>): <what failed> — <exact unblock action>
```

## Edge Cases / Failure Modes

- **Stale success row:** `migration-task-plan.md` says `✅`, but the file was deleted later. Treat the artifact as authoritative and downgrade the row to `❌`.
- **Partial Phase 3 completion:** One Phase 3 stream is `✅`, another `🔄`, another `❌`. Re-run only the failing or incomplete streams unless Phase 2 changed.
- **Architecture drift after Phase 2:** If `design-document.md` is rewritten, re-check whether existing Phase 3 artifacts still align before accepting them.
- **Concurrent worker writes:** Always re-read the plan immediately before editing. Do not overwrite other phase rows.
- **Whitespace-only output:** A file containing just a heading or comment still fails the minimum-content rule.
- **Ambiguous resume point:** If multiple earlier phases are incomplete or invalid, resume from the earliest invalid prerequisite.
