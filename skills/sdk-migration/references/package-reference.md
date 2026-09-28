# Package Reference — boto3 / @aws-sdk / AWS SDK v2 → Azure SDK

## Python (requirements.txt)

| boto3 client | Azure package | pip command |
|---|---|---|
| `boto3` (s3) | `azure-storage-blob` | `pip install azure-storage-blob` |
| `boto3` (dynamodb) | `azure-cosmos` | `pip install azure-cosmos` |
| `boto3` (sqs) | `azure-servicebus` | `pip install azure-servicebus` |
| `boto3` (secretsmanager) | Key Vault app setting ref (no SDK) | — |
| `boto3` (sns) | `azure-eventgrid` | `pip install azure-eventgrid` |
| `boto3` (ses) | `azure-communication-email` | `pip install azure-communication-email` |
| Auth (all clients) | `azure-identity` | `pip install azure-identity` |

Minimum `requirements.txt` for an Azure Functions app:
```
azure-functions
azure-identity
azure-storage-blob
azure-cosmos
azure-servicebus
```

## Node.js (package.json)

| @aws-sdk package | @azure package |
|---|---|
| `@aws-sdk/client-s3` | `@azure/storage-blob` |
| `@aws-sdk/client-dynamodb`, `@aws-sdk/lib-dynamodb` | `@azure/cosmos` |
| `@aws-sdk/client-sqs` | `@azure/service-bus` |
| `@aws-sdk/client-eventbridge` | `@azure/eventgrid` |
| `@aws-sdk/client-sns` | `@azure/eventgrid` |
| `@aws-sdk/client-kinesis` | `@azure/event-hubs` |
| `@aws-sdk/client-secrets-manager` | No runtime dependency — use Key Vault app setting references |
| Auth (all) | `@azure/identity` |

## Java (Maven pom.xml)

Use the **Azure SDK BOM** to manage all Azure SDK versions together:

```xml
<dependencyManagement>
  <dependencies>
    <dependency>
      <groupId>com.azure</groupId>
      <artifactId>azure-sdk-bom</artifactId>
      <version>1.2.26</version>
      <type>pom</type>
      <scope>import</scope>
    </dependency>
  </dependencies>
</dependencyManagement>
```

Then add only the clients you need (no version required when using BOM):

| AWS SDK v2 artifact | Azure SDK artifact | groupId |
|---|---|---|
| `s3` | `azure-storage-blob` | `com.azure` |
| `dynamodb` | `azure-cosmos` | `com.azure` |
| `sqs` | `azure-messaging-servicebus` | `com.azure` |
| `secretsmanager` | `azure-security-keyvault-secrets` | `com.azure` |
| `sns` | `azure-messaging-eventgrid` | `com.azure` |
| `kinesis` | `azure-messaging-eventhubs` | `com.azure` |
| Auth (all) | `azure-identity` | `com.azure` |

Minimum `pom.xml` dependencies for a migrated Java service:
```xml
<dependency><groupId>com.azure</groupId><artifactId>azure-identity</artifactId></dependency>
<dependency><groupId>com.azure</groupId><artifactId>azure-storage-blob</artifactId></dependency>
<dependency><groupId>com.azure</groupId><artifactId>azure-cosmos</artifactId></dependency>
<dependency><groupId>com.azure</groupId><artifactId>azure-messaging-servicebus</artifactId></dependency>
```
