# Java SDK Mappings (AWS SDK v2 → Azure SDK for Java)

Load this file when the source file being refactored contains `software.amazon.awssdk.*` imports.

## Storage: S3 → Azure Blob Storage

```java
// BEFORE (AWS SDK v2)
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;
import software.amazon.awssdk.core.sync.RequestBody;

S3Client s3 = S3Client.builder().region(Region.US_EAST_1).build();

// Upload
s3.putObject(PutObjectRequest.builder().bucket(bucket).key(key).build(),
             RequestBody.fromBytes(data));

// Download
ResponseInputStream<GetObjectResponse> obj = s3.getObject(
    GetObjectRequest.builder().bucket(bucket).key(key).build());

// AFTER (azure-storage-blob)
import com.azure.storage.blob.*;
import com.azure.identity.DefaultAzureCredentialBuilder;

BlobServiceClient blobServiceClient = new BlobServiceClientBuilder()
    .endpoint("https://" + System.getenv("AZURE_STORAGE_ACCOUNT_NAME") + ".blob.core.windows.net")
    .credential(new DefaultAzureCredentialBuilder().build())
    .buildClient();

BlobClient blobClient = blobServiceClient
    .getBlobContainerClient(container)
    .getBlobClient(blobName);

// Upload
blobClient.upload(BinaryData.fromBytes(data), true);

// Download
byte[] downloaded = blobClient.downloadContent().toBytes();
```

## NoSQL Database: DynamoDB → Cosmos DB

```java
// BEFORE (AWS SDK v2)
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.*;

DynamoDbClient dynamo = DynamoDbClient.create();
Map<String, AttributeValue> key = Map.of("orderId", AttributeValue.fromS(id));
GetItemResponse response = dynamo.getItem(GetItemRequest.builder()
    .tableName("orders").key(key).build());

// AFTER (azure-cosmos)
import com.azure.cosmos.*;
import com.azure.cosmos.models.*;
import com.azure.identity.DefaultAzureCredentialBuilder;

CosmosClient cosmosClient = new CosmosClientBuilder()
    .endpoint(System.getenv("COSMOS_ENDPOINT"))
    .credential(new DefaultAzureCredentialBuilder().build())
    .buildClient();

CosmosContainer container = cosmosClient
    .getDatabase(System.getenv("COSMOS_DB"))
    .getContainer("orders");

// Read
CosmosItemResponse<OrderItem> response = container.readItem(id, new PartitionKey(id), OrderItem.class);
OrderItem item = response.getItem();

// Write
container.upsertItem(item);
```

## Messaging: SQS → Azure Service Bus

```java
// BEFORE (AWS SDK v2)
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;

SqsClient sqs = SqsClient.create();
sqs.sendMessage(SendMessageRequest.builder()
    .queueUrl(System.getenv("QUEUE_URL"))
    .messageBody(payload)
    .build());

// AFTER (azure-messaging-servicebus)
import com.azure.messaging.servicebus.*;
import com.azure.identity.DefaultAzureCredentialBuilder;

ServiceBusSenderClient sender = new ServiceBusClientBuilder()
    .fullyQualifiedNamespace(System.getenv("SERVICE_BUS_NAMESPACE"))
    .credential(new DefaultAzureCredentialBuilder().build())
    .sender()
    .queueName(System.getenv("QUEUE_NAME"))
    .buildClient();

sender.sendMessage(new ServiceBusMessage(payload));
sender.close();
```

## Secrets: Secrets Manager → Key Vault

```java
// BEFORE (AWS SDK v2)
import software.amazon.awssdk.services.secretsmanager.SecretsManagerClient;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueRequest;

SecretsManagerClient sm = SecretsManagerClient.create();
String secret = sm.getSecretValue(GetSecretValueRequest.builder()
    .secretId("my-secret").build()).secretString();

// AFTER (azure-security-keyvault-secrets)
import com.azure.security.keyvault.secrets.SecretClient;
import com.azure.security.keyvault.secrets.SecretClientBuilder;
import com.azure.identity.DefaultAzureCredentialBuilder;

SecretClient secretClient = new SecretClientBuilder()
    .vaultUrl("https://" + System.getenv("KEY_VAULT_NAME") + ".vault.azure.net")
    .credential(new DefaultAzureCredentialBuilder().build())
    .buildClient();

String secret = secretClient.getSecret("my-secret").getValue();

// Alternative: inject via Key Vault reference in app settings (preferred — zero SDK calls at runtime):
String secret = System.getenv("MY_SECRET"); // Azure resolves @Microsoft.KeyVault(...) reference
```

## Events: SNS → Azure Event Grid / Service Bus Topics

```java
// BEFORE (AWS SDK v2 — SNS publish)
import software.amazon.awssdk.services.sns.SnsClient;
import software.amazon.awssdk.services.sns.model.PublishRequest;

SnsClient sns = SnsClient.create();
sns.publish(PublishRequest.builder().topicArn(topicArn).message(payload).build());

// AFTER (azure-messaging-eventgrid — fan-out pattern)
import com.azure.messaging.eventgrid.*;
import com.azure.core.models.CloudEvent;
import com.azure.core.credential.AzureKeyCredential;

EventGridPublisherClient<CloudEvent> client = new EventGridPublisherClientBuilder()
    .endpoint(System.getenv("AZURE_EVENT_GRID_ENDPOINT"))
    .credential(new AzureKeyCredential(System.getenv("AZURE_EVENT_GRID_KEY")))
    .buildCloudEventPublisherClient();

client.sendEvent(new CloudEvent("/my-service", eventType, BinaryData.fromString(payload), "application/json"));
```
