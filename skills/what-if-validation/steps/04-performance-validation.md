# Step 4 — Performance Validation

Requires: [Step 3 — Security Validation](03-security-validation.md) passed.

## Baseline Comparison

| Metric | Acceptance Threshold |
|---|---|
| P50 response time | ≤ 1.5× AWS P50 |
| P95 response time | ≤ 2.0× AWS P95 |
| P99 response time | ≤ 3.0× AWS P99 |
| Error rate | ≤ 0.5% (same as AWS baseline or better) |
| Throughput (RPS) | ≥ 80% of AWS baseline |

```bash
# Quick load test (install hey: go install github.com/rakyll/hey@latest)
hey -n 1000 -c 50 -m GET "https://<functionapp>.azurewebsites.net/api/list"
```

Performance checklist:
- [ ] P95 response time ≤ design document SLA target
- [ ] No memory leaks (Function App memory trending flat)
- [ ] Cold start time acceptable for plan (Consumption: ≤ 3s, Premium: ≤ 500ms)

Next: [Step 5 — Cost Validation](05-cost-validation.md).
