# Complete Trigger Mapping Catalog

Map every Lambda trigger type to its Azure Functions equivalent using this catalog. Select the entry that matches the source trigger found in `aws-inventory.json`.

## HTTP API Gateway → HttpTrigger

```python
import azure.functions as func

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

@app.route(route="<route>", methods=["GET", "POST"])
def http_handler(req: func.HttpRequest) -> func.HttpResponse:
    # business logic here
    return func.HttpResponse(body='{"status": "ok"}', status_code=200, mimetype="application/json")
```

## CloudWatch Events / EventBridge Scheduler → TimerTrigger

```python
# CRON note: Azure uses 6-part CRON (seconds minutes hours day month weekday)
# AWS "rate(5 minutes)"  → "0 */5 * * * *"
# AWS "cron(0 12 * * ? *)" → "0 0 12 * * *"
@app.timer_trigger(schedule="0 */5 * * * *", arg_name="timer", run_on_startup=False)
def scheduled_handler(timer: func.TimerRequest) -> None:
    # business logic here
    pass
```

## S3 Put/Delete event → BlobTrigger

```python
# Source path pattern: "<container>/{name}"
# Use output binding to write to a second container if the Lambda did so
@app.blob_trigger(arg_name="blob", path="<container>/{name}", connection="STORAGE_CONNECTION")
def blob_handler(blob: func.InputStream) -> None:
    data = blob.read()
    # business logic here
```

## SQS → Service Bus Queue trigger

```python
@app.service_bus_queue_trigger(
    arg_name="msg",
    queue_name="<queue-name>",
    connection="SERVICE_BUS_CONNECTION"
)
def queue_handler(msg: func.ServiceBusMessage) -> None:
    body = msg.get_body().decode("utf-8")
    # business logic here
```

## DynamoDB Streams → Cosmos DB Change Feed trigger

```python
# Requires: azure-cosmos in requirements.txt
# connection string app setting: COSMOS_CONNECTION
@app.cosmos_db_trigger(
    arg_name="documents",
    database_name="<db-name>",
    container_name="<container-name>",
    connection="COSMOS_CONNECTION",
    create_lease_container_if_not_exists=True
)
def cosmosdb_trigger(documents: func.DocumentList) -> None:
    for doc in documents:
        # business logic here — doc is a dict of the changed item
        pass
```

## SNS → Event Grid trigger (via Event Grid subscription)

```python
# Wire up an Event Grid subscription from your Event Grid topic to this function endpoint.
# The function receives CloudEvents or Event Grid schema events.
@app.event_grid_trigger(arg_name="event")
def eventgrid_handler(event: func.EventGridEvent) -> None:
    data = event.get_json()
    # business logic here
```

## Kinesis Data Streams → Event Hubs trigger

```python
# Requires: azure-eventhub in requirements.txt
# connection string app setting: EVENT_HUB_CONNECTION
@app.event_hub_message_trigger(
    arg_name="events",
    event_hub_name="<eventhub-name>",
    connection="EVENT_HUB_CONNECTION",
    cardinality="many"   # batch mode — use "one" for single-event processing
)
def eventhub_handler(events: func.EventHubEvent) -> None:
    for event in events:
        body = event.get_body().decode("utf-8")
        # business logic here
```

## Step Functions (start execution) → Durable Functions orchestration

```python
import azure.durable_functions as df

# Orchestrator function (replaces the Step Functions state machine definition)
@df.orchestrator
def orchestrator_function(context: df.DurableOrchestrationContext):
    result1 = yield context.call_activity("Step1", context.get_input())
    result2 = yield context.call_activity("Step2", result1)
    return result2

# Activity function (replaces each Lambda invoked by a state machine step)
@app.activity_trigger(input_name="input")
def Step1(input: dict) -> dict:
    # business logic here
    return {}

# Client function (replaces the Lambda that calls sfn.start_execution)
@app.route(route="start", methods=["POST"])
@app.durable_client_input(client_name="client")
async def http_start(req: func.HttpRequest, client) -> func.HttpResponse:
    instance_id = await client.start_new("orchestrator_function", client_input=req.get_json())
    return client.create_check_status_response(req, instance_id)
```

> **Durable Functions package:** Add `azure-functions-durable` to `requirements.txt`. Remove the `azure-durable-functions` package (different name).

## WebSocket API Gateway → Azure SignalR Service bindings

```python
# WebSocket push connections migrate to SignalR Service.
# Requires: azure-functions[signalr] in requirements.txt
@app.route(route="negotiate", methods=["POST"])
@app.generic_input_binding(arg_name="connectionInfo",
    type="signalRConnectionInfo",
    hub_name="<hub-name>",
    connection="SIGNALR_CONNECTION")
def negotiate(req: func.HttpRequest, connectionInfo) -> func.HttpResponse:
    return func.HttpResponse(connectionInfo)

# Broadcast from server:
@app.generic_output_binding(arg_name="signalRMessages",
    type="signalR",
    hub_name="<hub-name>",
    connection="SIGNALR_CONNECTION")
def broadcast(timer: func.TimerRequest, signalRMessages: func.Out[str]) -> None:
    signalRMessages.set(json.dumps([{"target": "newMessage", "arguments": ["Hello from Azure"]}]))
```

## Cognito triggers (Pre-SignUp, Post-Confirmation, etc.) → Custom auth middleware

> Cognito custom auth logic does not have a direct Azure Functions trigger equivalent. Migrate the logic to middleware in your application (MSAL.js or Microsoft.Identity.Web) or to B2C custom policies. Do not create a Functions trigger for this.

## Required `host.json`

```json
{
  "version": "2.0",
  "logging": {
    "applicationInsights": {
      "samplingSettings": { "isEnabled": true }
    }
  },
  "extensionBundle": {
    "id": "Microsoft.Azure.Functions.ExtensionBundle",
    "version": "[4.*, 5.0.0)"
  }
}
```

## Required `requirements.txt` base

```
azure-functions
azure-identity
azure-storage-blob
azure-keyvault-secrets
```

## Additional Packages by Trigger Type

Include only what the source Lambda uses:

| Source trigger | Add to requirements.txt |
|---|---|
| SQS → Service Bus Queue | `azure-servicebus` |
| DynamoDB Streams → Cosmos DB | `azure-cosmos` |
| SNS → Event Grid | `azure-eventgrid` |
| Kinesis → Event Hubs | `azure-eventhub` |
| Step Functions → Durable Functions | `azure-functions-durable` |
| WebSocket → SignalR | `azure-functions[signalr]` |
