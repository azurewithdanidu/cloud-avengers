# Validation Report Template

Write `outputs/validation-report.md` using this structure:

```markdown
# Azure Migration Validation Report

**Date:** YYYY-MM-DD
**Migration:** AWS → Azure
**Validated By:** deployment-validation agent
**Status:** PASS | FAIL | PARTIAL

---

## Executive Summary

| Category | Status | Notes |
|---|---|---|
| Pre-Deployment Validation | ✅ PASS / ❌ FAIL | |
| Post-Deployment Validation | ✅ PASS / ❌ FAIL | |
| Security Validation | ✅ PASS / ❌ FAIL | |
| Performance Validation | ✅ PASS / ❌ FAIL | |
| Cost Validation | ✅ PASS / ❌ FAIL | |
| **Overall** | **✅ PASS / ❌ FAIL** | |

---

## Pre-Deployment Validation

### Template Validation
- [ ] `az bicep build` — PASS / FAIL
- [ ] `az deployment sub validate` — PASS / FAIL
- [ ] `az deployment sub what-if` — PASS / BLOCKED

### What-If Change Table
| Environment | Change Type | Resource | Verdict |
|---|---|---|---|
| dev | Create | rg-dev-storage | OK |
| prod | Delete | rg-prod-keyvault | ❌ BLOCKED |

### Policy Compliance
- [ ] Required tags present — PASS / FAIL
- [ ] No public IPs on private services — PASS / FAIL

### Quota Checks
- [ ] Storage account quota sufficient — PASS / FAIL
- [ ] Function App quota sufficient — PASS / FAIL

---

## Post-Deployment Validation

### Resource Status
| Resource | Type | Status |
|---|---|---|
| functionApp | Microsoft.Web/sites | ✅ Succeeded |
| storageAccount | Microsoft.Storage/storageAccounts | ✅ Succeeded |
| keyVault | Microsoft.KeyVault/vaults | ✅ Succeeded |

### Connectivity
| Test | Result | Notes |
|---|---|---|
| Function App health endpoint | ✅ HTTP 200 | |
| SWA index.html | ✅ HTTP 200 | |
| Database connectivity | ✅ Reachable | |

### Smoke Tests
| Test | Result | Actual vs Expected |
|---|---|---|
| Upload file | ✅ PASS | HTTP 200, file in Blob |
| List files | ✅ PASS | File appears in list |
| View file | ✅ PASS | Correct content returned |
| Delete file | ✅ PASS | File removed |
| Error handling | ✅ PASS | 404 for missing resource |

---

## Security Validation

| Check | Result | Notes |
|---|---|---|
| No credentials in app settings | ✅ PASS | |
| Managed Identity enabled | ✅ PASS | |
| RBAC least privilege | ✅ PASS | |
| TLS 1.2+ enforced | ✅ PASS | |
| Key Vault soft delete | ✅ PASS | |
| Private endpoints configured | ✅ PASS | |

---

## Performance Validation

| Metric | AWS Baseline | Azure Result | Within Threshold |
|---|---|---|---|
| P50 response time | XXX ms | XXX ms | ✅ / ❌ |
| P95 response time | XXX ms | XXX ms | ✅ / ❌ |
| Error rate | X.X% | X.X% | ✅ / ❌ |
| Throughput (RPS) | XXX | XXX | ✅ / ❌ |

---

## Cost Validation

| Service | Projected (Monthly) | Actual (First Week × 4.3) | Within Budget |
|---|---|---|---|
| Azure Functions | $XXX | $XXX | ✅ / ❌ |
| Storage | $XXX | $XXX | ✅ / ❌ |
| Database | $XXX | $XXX | ✅ / ❌ |
| **Total** | **$XXX** | **$XXX** | **✅ / ❌** |

---

## Issues Found

### Critical (Must Fix Before Go-Live)
1. [Issue description, impacted resource, remediation steps]

### High (Fix Within 1 Week)
1. [Issue description, impacted resource, remediation steps]

---

## Sign-Off
- [ ] Infrastructure team: approved
- [ ] Security team: approved
- [ ] Application team: tested and approved
```
