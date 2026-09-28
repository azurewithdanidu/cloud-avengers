# cost-comparison.md Output Format

Write `outputs/azure-architecture-output/cost-comparison.md` using this structure. Adapt the rows to whatever services are in the target architecture — do not hard-code a fixed set of services.

```markdown
# Cost Comparison: <Source Cloud> vs Azure

> Prices fetched from Azure Retail Prices API (https://prices.azure.com/api/retail/prices).
> Retrieved: <ISO date>. Currency: USD. Target region: <armRegionName>.
> All `retailPrice` values are unmodified from the API response.

## SKU-Level Price Detail

| Service | SKU / Meter | `retailPrice` | Unit | Est. Units/Month | Est. Monthly (USD) | Source |
|---|---|---:|---|---:|---:|---|
| <Service Name> | <meterName> | $X.XX | <unitOfMeasure> | <N> | $X.XX | API ✓ |
| **<Service> subtotal** | | | | | **$X.XX** | |
| <Another Service> | <meterName> | $X.XX | <unitOfMeasure> | <N> | $X.XX | Estimated |
| ... | | | | | | |
| **Azure Total** | | | | | **$X.XX** | |

## Source vs Azure Summary

| Category | <Source Cloud> (Estimated) | Azure (API-Backed) | Delta |
|---|---:|---:|---:|
| Compute | $X | $X | ±$X |
| Storage | $X | $X | ±$X |
| Networking | $X | $X | ±$X |
| Monitoring | $X | $X | ±$X |
| Security | $X | $X | ±$X |
| <other categories as needed> | $X | $X | ±$X |
| **Total** | **$X** | **$X** | **±$X** |

## Annual Projection

| Metric | <Source Cloud> | Azure |
|---|---:|---:|
| Monthly run-rate | $X | $X |
| Annual run-rate | $X | $X |
| Annual delta | | ±$X |

## Cost Optimisation Levers

| Change | Approx. Saving | Trade-off |
|---|---:|---|
| <e.g. downgrade tier> | −$X/mo | <what you lose> |

## Assumptions

- List the filter query used for each service.
- List estimated monthly units for each meter (hours, GB, operations).
- Call out any services where `Count: 0` was returned and how you resolved it.
- Call out any free-tier boundaries that affect the estimate.
- State whether Reserved Instance pricing was considered.
```
