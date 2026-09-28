# Node.js / TypeScript SDK Mappings (@aws-sdk → @azure)

Load this file when the source file being refactored contains `@aws-sdk/*` imports.

## Storage: S3 → Azure Blob Storage

```typescript
// BEFORE (@aws-sdk)
import { S3Client, GetObjectCommand, PutObjectCommand } from "@aws-sdk/client-s3";
const s3Client = new S3Client({ region: "us-east-1" });

async function uploadFile(bucket: string, key: string, body: Buffer): Promise<void> {
    await s3Client.send(new PutObjectCommand({ Bucket: bucket, Key: key, Body: body }));
}
async function downloadFile(bucket: string, key: string): Promise<string> {
    const r = await s3Client.send(new GetObjectCommand({ Bucket: bucket, Key: key }));
    return r.Body?.toString() ?? '';
}

// AFTER (@azure/storage-blob)
import { BlobServiceClient } from "@azure/storage-blob";
import { DefaultAzureCredential } from "@azure/identity";

const blobServiceClient = new BlobServiceClient(
    `https://${process.env.AZURE_STORAGE_ACCOUNT_NAME}.blob.core.windows.net`,
    new DefaultAzureCredential()
);

async function uploadFile(container: string, blob: string, body: Buffer): Promise<void> {
    const blockBlobClient = blobServiceClient.getContainerClient(container).getBlockBlobClient(blob);
    await blockBlobClient.upload(body, body.length);
}
async function downloadFile(container: string, blob: string): Promise<string> {
    const blockBlobClient = blobServiceClient.getContainerClient(container).getBlockBlobClient(blob);
    return (await blockBlobClient.download()).contentAsText ?? '';
}
```

## NoSQL Database: DynamoDB → Cosmos DB

```typescript
// BEFORE (@aws-sdk)
import { DynamoDBDocumentClient, GetCommand, PutCommand } from "@aws-sdk/lib-dynamodb";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
const docClient = DynamoDBDocumentClient.from(new DynamoDBClient({ region: "us-east-1" }));

async function getItem(id: string) {
    return (await docClient.send(new GetCommand({ TableName: "orders", Key: { orderId: id } }))).Item;
}

// AFTER (@azure/cosmos)
import { CosmosClient } from "@azure/cosmos";
import { DefaultAzureCredential } from "@azure/identity";

const container = new CosmosClient({
    endpoint: process.env.AZURE_COSMOS_ENDPOINT!,
    aadCredentials: new DefaultAzureCredential()
}).database("mydb").container("orders");

async function getItem(id: string) {
    return (await container.item(id).read()).resource;
}
async function putItem(item: Record<string, unknown>) {
    await container.items.create(item);
}
```

## Events: EventBridge → Azure Event Grid

```typescript
// BEFORE (@aws-sdk)
import { EventBridgeClient, PutEventsCommand } from "@aws-sdk/client-eventbridge";
const eventBridge = new EventBridgeClient({ region: "us-east-1" });

async function publishEvent(type: string, detail: object): Promise<void> {
    await eventBridge.send(new PutEventsCommand({
        Entries: [{ Source: "my-service", DetailType: type, Detail: JSON.stringify(detail), EventBusName: "default" }]
    }));
}

// AFTER (@azure/eventgrid)
import { EventGridPublisherClient, AzureKeyCredential } from "@azure/eventgrid";

const egClient = new EventGridPublisherClient(
    process.env.AZURE_EVENT_GRID_ENDPOINT!,
    "CloudEvent",
    new AzureKeyCredential(process.env.AZURE_EVENT_GRID_KEY!)
);

async function publishEvent(type: string, detail: object): Promise<void> {
    await egClient.send([{
        type: type,
        source: "/my-service",
        data: detail,
        dataContentType: "application/json"
    }]);
}
```
