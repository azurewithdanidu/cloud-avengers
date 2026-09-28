# Environment Variable and Error Code Mapping

## Reserved Environment Variable Names

The following names are **reserved by the Azure Functions host** — using them causes silent overrides or runtime failures:

| Reserved Name | Use Instead |
|---|---|
| `CONTAINER_NAME` | `BLOB_CONTAINER_NAME` |
| `WEBSITE_*` (any prefix) | Choose a non-WEBSITE_ prefix |
| `FUNCTIONS_*` (any prefix) | Choose a non-FUNCTIONS_ prefix |
| `AzureWebJobs*` (any prefix) | Choose a non-AzureWebJobs prefix |

When renaming env vars during migration, also update: application code, Key Vault secret names, Bicep parameter files (app settings section), and GitHub Actions secrets.

## Environment Variable Mapping

| AWS Variable | Azure Replacement | Source |
|---|---|---|
| `AWS_REGION` | `AZURE_LOCATION` | App setting |
| `S3_BUCKET_NAME` | `AZURE_STORAGE_ACCOUNT_NAME` | App setting |
| `CONTAINER_NAME` | `BLOB_CONTAINER_NAME` | App setting (reserved name!) |
| `DYNAMODB_TABLE` | `COSMOS_ENDPOINT` + `COSMOS_DB` + `COSMOS_CONTAINER` | App settings |
| `SQS_QUEUE_URL` | `SERVICE_BUS_NAMESPACE` + `QUEUE_NAME` | App settings |
| `SECRET_NAME` | `MY_SECRET` (KV ref) | Key Vault reference |
| `AWS_ACCESS_KEY_ID` | Removed — use `DefaultAzureCredential` | N/A |
| `AWS_SECRET_ACCESS_KEY` | Removed — use `DefaultAzureCredential` | N/A |

## Error Code Equivalence

| AWS Error Code | Azure Equivalent | Notes |
|---|---|---|
| `NoSuchKey` | `BlobNotFound` (404) | Object/blob not found |
| `AccessDenied` | `AuthorizationPermissionMismatch` (403) | RBAC not assigned |
| `ResourceNotFoundException` | `CosmosHttpResponseError` (404) | Item not found |
| `ConditionalCheckFailedException` | `CosmosHttpResponseError` (412) | Optimistic concurrency failure |
| `ThrottlingException` | `HttpResponseError` (429) | Rate limited |
| `ServiceUnavailableException` | `ServiceRequestError` (503) | Transient error — retry |
