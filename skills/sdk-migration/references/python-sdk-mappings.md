# Python SDK Mappings (boto3 → Azure SDK)

Load this file when the source file being refactored contains `import boto3` or `boto3.client(...)`.

## Storage: S3 → Azure Blob Storage

```python
# BEFORE (boto3)
import boto3
s3_client = boto3.client('s3', region_name='us-east-1')

def upload_file(bucket_name: str, key: str, body: bytes) -> None:
    s3_client.put_object(Bucket=bucket_name, Key=key, Body=body)

def download_file(bucket_name: str, key: str) -> bytes:
    response = s3_client.get_object(Bucket=bucket_name, Key=key)
    return response['Body'].read()

# AFTER (azure-storage-blob)
import os
from azure.storage.blob import BlobServiceClient
from azure.identity import DefaultAzureCredential

blob_service_client = BlobServiceClient(
    account_url=f"https://{os.environ['AZURE_STORAGE_ACCOUNT_NAME']}.blob.core.windows.net",
    credential=DefaultAzureCredential()
)

def upload_file(container_name: str, blob_name: str, body: bytes) -> None:
    blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)
    blob_client.upload_blob(body, overwrite=True)

def download_file(container_name: str, blob_name: str) -> bytes:
    blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)
    return blob_client.download_blob().readall()
```

## NoSQL Database: DynamoDB → Cosmos DB

```python
# BEFORE (boto3)
import boto3
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
table = dynamodb.Table('orders')

def get_item(order_id: str) -> dict:
    response = table.get_item(Key={'orderId': order_id})
    return response.get('Item', {})

def put_item(item: dict) -> None:
    table.put_item(Item=item)

# AFTER (azure-cosmos)
import os
from azure.cosmos import CosmosClient
from azure.identity import DefaultAzureCredential

cosmos_client = CosmosClient(
    url=os.environ['AZURE_COSMOS_ENDPOINT'],
    credential=DefaultAzureCredential()
)
container = cosmos_client.get_database_client(os.environ['COSMOS_DB']).get_container_client('orders')

def get_item(order_id: str) -> dict:
    return container.read_item(item=order_id, partition_key=order_id)

def put_item(item: dict) -> None:
    container.upsert_item(body=item)
```

## Messaging: SQS → Azure Service Bus

```python
# BEFORE (boto3)
import boto3
sqs = boto3.client('sqs')
sqs.send_message(QueueUrl=os.environ['QUEUE_URL'], MessageBody=json.dumps(payload))

# AFTER (azure-servicebus)
import os, json
from azure.servicebus import ServiceBusClient, ServiceBusMessage
from azure.identity import DefaultAzureCredential

credential = DefaultAzureCredential()
with ServiceBusClient(os.environ['SERVICE_BUS_NAMESPACE'], credential) as sb_client:
    with sb_client.get_queue_sender(os.environ['QUEUE_NAME']) as sender:
        sender.send_messages(ServiceBusMessage(json.dumps(payload)))
```

## Secrets: Secrets Manager → Key Vault app setting reference

```python
# BEFORE (boto3)
import boto3
sm = boto3.client('secretsmanager')
secret = sm.get_secret_value(SecretId='my-secret')['SecretString']

# AFTER — no SDK call needed at runtime
# The secret is injected via Key Vault reference in app settings (set in Bicep):
#   MY_SECRET = @Microsoft.KeyVault(SecretUri=https://<kv>.vault.azure.net/secrets/my-secret/)
secret = os.environ['MY_SECRET']   # Azure resolves the KV reference automatically
```

## Lambda Handler → Azure Function Handler

```python
# BEFORE (AWS Lambda)
def handler(event, context):
    try:
        result = process(event)
        return {'statusCode': 200, 'body': json.dumps(result)}
    except Exception as e:
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}

# AFTER (Azure Functions v2 Python)
import azure.functions as func
import json

app = func.FunctionApp()

@app.function_name(name="HttpTrigger")
@app.route(route="process", methods=["GET", "POST"])
def http_trigger(req: func.HttpRequest) -> func.HttpResponse:
    try:
        result = process(req)
        return func.HttpResponse(json.dumps(result), status_code=200, mimetype="application/json")
    except Exception as e:
        return func.HttpResponse(json.dumps({'error': str(e)}), status_code=500, mimetype="application/json")
```
