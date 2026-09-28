---
name: cost-estimator
description: Fetch real Azure Retail Prices API data (no auth) for any Azure service in the target architecture and emit defensible per-SKU costs into cost-comparison.md. Read before any cost output.
---


# Cost Estimator Skill

## Purpose

Replace hand-estimated costs in `outputs/azure-architecture-output/cost-comparison.md` with real SKU prices sourced directly from the Azure Retail Prices API for **any Azure service** in the target architecture. Every number in the output must trace back to an API-returned `retailPrice` field.

---

## Azure Retail Prices API

**Base URL:** `https://prices.azure.com/api/retail/prices`  
**Auth:** None required.  
**Method:** HTTP GET with OData `$filter` query parameter.  
**Response schema:**

```json
{
  "BillingCurrency": "USD",
  "Items": [
    {
      "retailPrice": 0.182,
      "unitPrice": 0.182,
      "unitOfMeasure": "1 Hour",
      "currencyCode": "USD",
      "skuName": "Premium",
      "productName": "Premium Functions",
      "meterName": "Premium vCPU Duration",
      "serviceName": "Functions",
      "serviceFamily": "Compute",
      "armRegionName": "australiaeast",
      "type": "Consumption"
    }
  ],
  "NextPageLink": null,
  "Count": 2
}
```

**OData filter fields available:**

| Field | Description | Example value |
|---|---|---|
| `armRegionName` | Azure region ARM name | `australiaeast`, `eastus`, `westeurope` |
| `serviceName` | Top-level service name | `Functions`, `Storage`, `SQL Database` |
| `serviceFamily` | Broad category | `Compute`, `Storage`, `Networking`, `Databases` |
| `productName` | Specific product within a service | `Premium Functions`, `Blob Storage` |
| `skuName` | Tier or redundancy variant | `EP1`, `Hot LRS`, `General Purpose` |
| `meterName` | Individual billing dimension | `Premium vCPU Duration`, `Hot LRS Data Stored` |
| `priceType` | Pricing model | `Consumption`, `Reservation`, `DevTest` |
| `currencyCode` | Currency | `USD` |
| `type` | Alias for priceType | `Consumption` |

---

## Universal Discovery Workflow

Use this process for **every service** in the target architecture, regardless of service type.

### Step 1 — Discover available product names

Start broad. If you don't know the exact `productName`, query by `serviceName` or a `contains()` substring match:

```
GET https://prices.azure.com/api/retail/prices?$filter=armRegionName eq '<region>' and serviceName eq '<service>'
```

Or by substring when the service name is uncertain:

```
GET https://prices.azure.com/api/retail/prices?$filter=armRegionName eq '<region>' and contains(productName,'<keyword>')
```

Scan the returned `Items` to identify the correct `productName`, `skuName`, and `meterName` values for the tier you are costing.

> **If `Count` is 0:** The service may be global (no per-region meter), or the product name differs from the portal display name. Drop `armRegionName` and add `currencyCode eq 'USD'` instead, then re-query.

### Step 2 — Narrow to the exact meter

Refine the filter to `productName eq '<exact value>'` and check all returned `meterName` values. A single product typically has multiple meters (e.g., vCPU hours, memory hours, data stored, read ops, write ops). Identify every meter that applies to the workload.

```
GET https://prices.azure.com/api/retail/prices?$filter=armRegionName eq '<region>' and productName eq '<exact product name>' and priceType eq 'Consumption'
```

### Step 3 — Extract and calculate

For each relevant meter:
1. Read `retailPrice` and `unitOfMeasure` from the response.
2. Estimate monthly units from workload assumptions (hours, GB, operations, etc.).
3. Multiply: `retailPrice × estimated_units = monthly_cost`.
4. Tag the row `API ✓` in the output table.

### Step 4 — Handle pagination

If `NextPageLink` is not null, follow it to retrieve additional pages before selecting the correct meter.

### Step 5 — Handle services with no regional meter

Some services (Static Web Apps, Private Link, Azure DNS, Front Door, CDN) are globally priced. Drop `armRegionName` and filter by `currencyCode eq 'USD'` only. Note this in the Assumptions section of the output.

---


## Service Catalog — Filter Reference

See [references/service-catalog-filters.md](references/service-catalog-filters.md) for starting `$filter` queries grouped by category (Compute, Storage, Databases, Networking, AI/ML, Integration & Messaging, Security & Identity, Management & Monitoring, Developer Tools & DevOps). Use it as a starting point, then refine per Step 2 above — service names and SKUs change over time.

## Handling Free Tiers and Tiered Pricing

Many services have free tiers or volume tiers. The API returns multiple `Items` for the same `meterName` with different `tierMinimumUnits`:

```json
[
  { "tierMinimumUnits": 0,       "retailPrice": 0.00,  "meterName": "Analytics Logs Data Ingestion" },
  { "tierMinimumUnits": 5,       "retailPrice": 3.34,  "meterName": "Analytics Logs Data Ingestion" }
]
```

**Rule:** Select the tier whose `tierMinimumUnits` is ≤ your estimated monthly consumption. For workloads that span multiple tiers, calculate the cost in each tier bracket and sum them.

---

## Reserved Instance / Savings Plan Pricing

To fetch Reserved pricing (1-year or 3-year) instead of pay-as-you-go:

```
GET https://prices.azure.com/api/retail/prices?$filter=<your filter> and priceType eq 'Reservation'
```

Include both Consumption and Reservation rows in the output table when the service supports reservations, so stakeholders can see the savings opportunity.

---

## Services That Are Free

The following services have **no billable meter** in the API. Record them as `$0.00 — Free` in the output table:

- **Azure Virtual Network (VNet)** — creation, maintenance, subnets, NSGs
- **Azure Resource Manager** — API calls, deployments, resource groups
- **Azure Managed Identity** — system-assigned and user-assigned
- **Azure RBAC** — role assignments
- **Azure Policy** — policy definitions and compliance scanning
- **Azure Active Directory (Free tier)** — basic identity, up to 50K objects

---


## Output Format

Write `outputs/azure-architecture-output/cost-comparison.md` following [references/cost-comparison-template.md](references/cost-comparison-template.md) exactly (SKU-level detail, source-vs-Azure summary, annual projection, cost optimisation levers, assumptions). Adapt the rows to whatever services are in the target architecture — do not hard-code a fixed set of services.

## Rules

1. **Never invent a price.** If the API returns `Count: 0`, broaden the filter and document the fallback query used.
2. **Always tag each row** with `API ✓` (price confirmed from API response) or `Estimated` (reasonable industry assumption with rationale).
3. **Always record the query used** in an Assumptions section or code comment so future runs can re-fetch the same data.
4. **Re-fetch before each output generation** — retail prices change. Stale embedded prices must not be copy-pasted from previous runs.
5. **Show subtotals** for multi-meter services (e.g., Functions has both vCPU and memory meters).
6. **If `NextPageLink` is non-null**, follow it to retrieve all pages before selecting the correct meter.
7. **Match on `meterName`**, not just `skuName` — multiple meters share the same `skuName` (e.g., "Premium" has both vCPU and Memory meters).
8. **Use `retailPrice`**, not `unitPrice` — they are usually identical for Consumption pricing but `retailPrice` is the public list price.

---

## Scripts

| Script | When to run |
|---|---|
| `./scripts/fetch-prices.sh` | Run on Bash/macOS/Linux/WSL whenever you need live Azure Retail Prices API data for a specific service, region, and optional SKU filter. |
| `./scripts/fetch-prices.ps1` | Run the same live price lookup on PowerShell 7+ environments, including Windows runners and developer shells. |

---

## References

### Microsoft / Azure Documentation

| Topic | Link |
|---|---|
| Azure Retail Prices API reference | https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices |
| Azure Retail Prices API — interactive explorer | https://prices.azure.com/api/retail/prices |
| Azure Cost Management documentation | https://learn.microsoft.com/en-us/azure/cost-management-billing/ |
| Azure Pricing Calculator | https://azure.microsoft.com/en-us/pricing/calculator/ |
| Azure Savings Plans | https://learn.microsoft.com/en-us/azure/cost-management-billing/savings-plan/savings-plan-compute-overview |
| Azure Reservations overview | https://learn.microsoft.com/en-us/azure/cost-management-billing/reservations/save-compute-costs-reservations |
| Azure Free tier services | https://azure.microsoft.com/en-us/pricing/free-services/ |
| Azure consumption APIs | https://learn.microsoft.com/en-us/azure/cost-management-billing/automate/consumption-api-overview |
| OData filter query syntax | https://learn.microsoft.com/en-us/azure/search/search-query-odata-filter |

### Best Practices

- **Always re-fetch prices at generation time** — the Retail Prices API is unauthenticated and fast. Embedded prices from previous runs become stale within weeks.
- **Tiered pricing requires per-bracket calculation:** Many Azure meters have `tierMinimumUnits` — always check for all tiers before assuming a flat rate.
- **`Count: 0` is a signal, not an error** — it means the filter is too narrow. Drop fields one at a time (`armRegionName`, then `skuName`) until you find the right meter. Document the fallback query in Assumptions.
- **Reservation pricing is always worth showing** for services with predictable baseline usage — 1-year reserved VMs and databases typically cost 30–40% less than pay-as-you-go.
- **AWS Cost Explorer exports** are the most accurate source of historical AWS spend — request them from the customer before estimating AWS baseline costs.

---

## Updating `cost-comparison.md`

1. Fetch all queries above using the `web` tool.
2. Parse the `Items` array and extract `retailPrice` for the meterName listed in each table.
3. Multiply by the usage estimate to produce `Est. Monthly (USD)`.
4. Populate the output table with the real numbers.
5. Record the retrieval date in the document header.
6. Mark the `migration-task-plan.md` row for this task as ✅ once the file is written.
