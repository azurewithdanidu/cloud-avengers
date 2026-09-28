# Cost Formulas — AWS Estimation, Egress, Reservations, Break-even

## Estimate Unknown AWS Costs from Instance Types and Workload Shape

Use these fallback formulas when actual AWS billing is unknown:

| AWS service | Estimation method |
|---|---|
| EC2 | `instance_count * hourly_rate(instance_type) * 730 + attached_storage_gb * storage_rate + outbound_data_gb * egress_rate` |
| Lambda | `request_count * request_rate + (memory_gb * avg_duration_seconds * request_count) * GBs_rate` |
| S3 | `stored_gb * storage_rate + PUT_requests * put_rate + GET_requests * get_rate + outbound_gb * egress_rate` |
| RDS | `instance_hours * class_rate + storage_gb * storage_rate + provisioned_iops * iops_rate` |
| DynamoDB | `read_units + write_units + storage_gb + backups + streams if used` |
| NAT Gateway | `hours * hourly_rate + processed_gb * data_processing_rate` |
| CloudWatch | `ingested_gb * log_rate + metrics_count * metric_rate + retained_gb * retention_rate` |

If a service still cannot be estimated precisely:

- pick the closest known instance class or usage tier
- state the proxy explicitly
- add a sensitivity range of at least ±15%

## Data Egress Cost Formulas

Always model egress explicitly. Use these formulas and explain the chosen rates:

- **AWS egress monthly**

  `AWS_Egress_Monthly = max(AWS_GB_Out - AWS_Free_GB, 0) * AWS_Egress_Rate_Per_GB`

- **Azure egress monthly**

  `Azure_Egress_Monthly = max(Azure_GB_Out - Azure_Free_GB, 0) * Azure_Egress_Rate_Per_GB`

- **Front Door egress contribution**

  `FrontDoor_Data_Cost = FrontDoor_GB_Out * FrontDoor_Rate_Per_GB`

- **Inter-region transfer**

  `InterRegion_Cost = InterRegion_GB * InterRegion_Rate_Per_GB`

- **Total network cost**

  `Total_Network_Cost = Egress + CDN_or_FrontDoor + InterRegion + NAT_or_Equivalent`

Worked egress example:

- 2,500 GB/month outbound
- 100 GB free allowance
- $0.087 per GB effective rate
- `max(2500 - 100, 0) * 0.087 = $208.80/month`

## Azure Reservations Savings Calculations

When the workload has predictable baseline compute or database usage, show reservation scenarios.

Formulas:

- `Reserved_1yr_Monthly = PAYG_Monthly * (1 - Savings_Rate_1yr)`
- `Reserved_3yr_Monthly = PAYG_Monthly * (1 - Savings_Rate_3yr)`
- `Savings_Percent = (PAYG_Monthly - Reserved_Monthly) / PAYG_Monthly * 100`

Example using placeholder savings rates:

- Baseline eligible Azure compute: `$800/month`
- 1-year reservation savings rate: `38%`
- 3-year reservation savings rate: `57%`
- `Reserved_1yr_Monthly = 800 * (1 - 0.38) = $496/month`
- `Reserved_3yr_Monthly = 800 * (1 - 0.57) = $344/month`

Use current documented or calculator-derived savings inputs; do not hardcode stale percentages without citation.

## Break-even Formula with Worked Example

Use this formula whenever migration one-time cost is known or estimated:

- `Monthly_Savings = AWS_Monthly - Azure_Monthly`
- `BreakEven_Months = Migration_OneTime_Cost / Monthly_Savings`

Worked example:

- Current AWS monthly cost: `$2,450`
- Projected Azure pay-as-you-go monthly cost: `$1,850`
- Migration one-time cost: `$18,000`
- `Monthly_Savings = 2450 - 1850 = $600`
- `BreakEven_Months = 18000 / 600 = 30 months`

Reservation comparison:

- Azure 1-year reserved monthly cost: `$1,620` → monthly savings `$830` → break-even `21.7 months`
- Azure 3-year reserved monthly cost: `$1,480` → monthly savings `$970` → break-even `18.6 months`

If `Monthly_Savings <= 0`, state that there is no break-even under the modeled scenario.
