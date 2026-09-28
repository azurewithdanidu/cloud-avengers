# cost-comparison.md Full Template

Use this full template for `outputs/azure-architecture-output/cost-comparison.md`:

```markdown
# Cost Comparison: AWS vs Azure

## 1. Executive Summary
- Current AWS monthly estimate:
- Projected Azure monthly estimate:
- Monthly delta:
- One-time migration cost:
- Break-even:

## 2. Scope and Inputs
- Discovery artifacts used:
- Source billing or documentation used:
- Target Azure services modeled:
- Currency and pricing date:

## 3. AWS Current Monthly Cost Baseline
| Service Category | Service | Quantity / Usage | Monthly Cost | Source / Assumption |
|---|---|---|---|---|

## 4. Azure Projected Monthly Cost (Pay-as-you-go)
| Service Category | Azure Service | SKU / Tier | Quantity / Usage | Monthly Cost | Source / Assumption |
|---|---|---|---|---|---|

## 5. Reservation and Commitment Scenarios
| Scenario | Eligible Spend | Monthly Cost | Savings vs PAYG | Notes |
|---|---|---|---|---|
| Pay-as-you-go |  |  |  |  |
| 1-year reservation |  |  |  |  |
| 3-year reservation |  |  |  |  |

## 6. Network and Data Egress
- AWS egress formula and result:
- Azure egress formula and result:
- Front Door or CDN contribution:
- Inter-region data transfer assumptions:

## 7. Monthly Cost Summary
| Category | AWS | Azure PAYG | Azure 1yr Reserved | Azure 3yr Reserved | Delta vs AWS |
|---|---|---|---|---|---|

## 8. Break-even and ROI
- One-time migration cost:
- Monthly savings by scenario:
- Break-even months by scenario:
- 3-year ROI by scenario:

## 9. Assumptions and Unknowns
- Document every assumption.
- Mark every estimated AWS cost explicitly.
- Call out excluded costs such as enterprise support, shared landing zone cost, or team labor if omitted.

## 10. Sensitivity and Risk Notes
- Traffic growth sensitivity:
- Reservation commitment risk:
- Services with the highest estimate uncertainty:

## 11. Recommendation
- Recommended Azure pricing posture:
- Conditions that would change the decision:
- Next pricing validation step:
```
