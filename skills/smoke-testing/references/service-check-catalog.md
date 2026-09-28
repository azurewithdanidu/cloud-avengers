# Service Check Catalog

Pick **one or more** of the following based on what is deployed. At minimum run the check for your primary data service.

## Blob Storage

```bash
# Upload a test blob
az storage blob upload \
  --account-name <storage-account> \
  --container-name <container> \
  --name smoke-test.txt \
  --data "smoke test $(date -u +%s)" \
  --auth-mode login

# Verify it exists
az storage blob show \
  --account-name <storage-account> \
  --container-name <container> \
  --name smoke-test.txt \
  --auth-mode login \
  --query name -o tsv

# Clean up
az storage blob delete \
  --account-name <storage-account> \
  --container-name <container> \
  --name smoke-test.txt \
  --auth-mode login
```

## Cosmos DB (NoSQL)

```bash
# Write a test document
az cosmosdb sql container create ... # (skip if already exists)
COSMOS_ACCOUNT=<cosmos-account>
DB=<database-name>
CONTAINER=<container-name>
az rest --method POST \
  --url "https://management.azure.com/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.DocumentDB/databaseAccounts/${COSMOS_ACCOUNT}/sqlDatabases/${DB}/containers/${CONTAINER}/documents?api-version=2021-10-15" \
  --body '{"id":"smoke-test","value":"smoke","_ttl":60}'

# Alternative — use the Data Explorer or SDK; verify with:
az cosmosdb sql database list --account-name $COSMOS_ACCOUNT --resource-group rg-<env>-<workload> -o tsv
```

## Azure SQL / PostgreSQL Flexible Server

```bash
# Verify connectivity (will prompt for password or use Azure AD)
psql "host=<server>.postgres.database.azure.com port=5432 dbname=<db> sslmode=require user=<admin>@<server>" \
  --command "SELECT 1 AS smoke_test;"

# For Azure SQL:
sqlcmd -S <server>.database.windows.net -d <db> -G -Q "SELECT 1 AS smoke_test"
```

## Azure Service Bus (Queue)

```bash
# Send a test message using the Service Bus REST API
SB_NAMESPACE=<namespace>
QUEUE=<queue-name>
TOKEN=$(az account get-access-token --resource https://servicebus.azure.net --query accessToken -o tsv)
curl -s -X POST \
  "https://${SB_NAMESPACE}.servicebus.windows.net/${QUEUE}/messages" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/atom+xml;type=entry;charset=utf-8" \
  -d "<entry xmlns='http://www.w3.org/2005/Atom'><content type='application/xml'><SmokeTest>ok</SmokeTest></content></entry>"
echo "Service Bus send: $?"
```

## Azure Cache for Redis

```bash
# Using redis-cli (if available in pipeline runner):
redis-cli -h <redis-name>.redis.cache.windows.net -p 6380 \
  --tls --pass <access-key> \
  SET smoke-test "ok" EX 60
redis-cli -h <redis-name>.redis.cache.windows.net -p 6380 \
  --tls --pass <access-key> \
  GET smoke-test
```

## Static Web Apps

```bash
URL="https://<app-name>.azurestaticapps.net"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
echo "Static Web App root: $STATUS"
[ "$STATUS" -eq 200 ] || exit 1

# Verify the root page serves real HTML content (not an error page)
BODY=$(curl -s "$URL")
echo "$BODY" | grep -qi "<html" || { echo "Root page did not return HTML"; exit 1; }
```

## Azure Functions — Application API Endpoints

Run these checks for every migrated workload that exposes file-upload and file-list APIs:

```bash
FUNC_HOST=$(az functionapp show \
  --name <functionapp-name> \
  --resource-group <resource-group> \
  --query defaultHostName -o tsv)

# /api/files — list endpoint (must return 200 or 401; 5xx = fail)
FILES_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  "https://${FUNC_HOST}/api/files")
echo "/api/files: $FILES_STATUS"
[ "$FILES_STATUS" -eq 200 ] || [ "$FILES_STATUS" -eq 401 ] || \
  { echo "FAIL: /api/files returned $FILES_STATUS"; exit 1; }

# /api/upload — upload endpoint (GET/HEAD probe; expect 200, 401, or 405)
UPLOAD_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X HEAD \
  "https://${FUNC_HOST}/api/upload")
echo "/api/upload (HEAD probe): $UPLOAD_STATUS"
[ "$UPLOAD_STATUS" -eq 200 ] || [ "$UPLOAD_STATUS" -eq 401 ] || \
  [ "$UPLOAD_STATUS" -eq 405 ] || \
  { echo "FAIL: /api/upload returned $UPLOAD_STATUS"; exit 1; }

# Full upload smoke test — POST a small test file
UPLOAD_POST_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "https://${FUNC_HOST}/api/upload" \
  -F "file=@/dev/null;filename=smoke-test.txt;type=text/plain")
echo "/api/upload (POST): $UPLOAD_POST_STATUS"
# Accept 200, 201, 401 (auth required), or 415 (wrong content type — endpoint alive)
[ "$UPLOAD_POST_STATUS" -eq 200 ] || [ "$UPLOAD_POST_STATUS" -eq 201 ] || \
  [ "$UPLOAD_POST_STATUS" -eq 401 ] || [ "$UPLOAD_POST_STATUS" -eq 415 ] || \
  { echo "FAIL: /api/upload POST returned $UPLOAD_POST_STATUS"; exit 1; }
```

Add the following rows to the smoke-test report for these checks:

```markdown
| /api/files endpoint | PASS/FAIL | HTTP <status> |
| /api/upload (probe) | PASS/FAIL | HTTP <status> |
| /api/upload (POST)  | PASS/FAIL | HTTP <status> |
```

## API Management (APIM)

```bash
APIM_GW="https://<apim-name>.azure-api.net"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  "${APIM_GW}/<api-path>" \
  -H "Ocp-Apim-Subscription-Key: <subscription-key>")
echo "APIM gateway: $STATUS"
[ "$STATUS" -eq 200 ] || [ "$STATUS" -eq 401 ] || exit 1
```

## Log Analytics — verify ingestion is working

```bash
WORKSPACE_ID=<workspace-id>
az monitor log-analytics query \
  --workspace "$WORKSPACE_ID" \
  --analytics-query "AzureActivity | take 5" \
  --output table
# Expect at least 1 row; empty result means no data is flowing
```
