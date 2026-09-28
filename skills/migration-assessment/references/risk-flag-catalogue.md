# Risk Flag Catalogue

Flag these conditions with explicit notes in the Service Complexity Matrix:

| Risk | Impact |
|---|---|
| Lambda layers | Must be re-packaged as Python packages or shared code modules |
| Custom Lambda authorizers | Must be re-implemented as Azure Functions middleware or APIM policies |
| Event source mappings with complex filtering | EventBridge filter patterns differ from Event Grid subscription filters |
| DynamoDB Streams | No direct Cosmos DB equivalent — use Change Feed |
| IAM Permission Boundaries | Re-implement via Azure Policy |
| Custom VPC with Direct Connect / VPN | Requires ExpressRoute or VPN Gateway; extra lead time |
| Lambda in VPC | Azure Functions VNET integration has different subnet delegation requirements |
| S3 presigned URLs | Equivalent via SAS tokens — short-lived, different signature algorithm |
| Step Functions | Durable Functions have different orchestration model |
| Cross-account S3 access | Azure Blob Storage uses separate storage account + managed identity |
| Secrets Manager rotation policies | Key Vault key rotation uses Event Grid — different event model |
