---
name: lambda-to-functions
description: Rewrite AWS Lambda handlers as Azure Functions — full trigger catalog covering HTTP, Timer, Blob, Service Bus, Cosmos DB Change Feed, Event Grid, Event Hubs, Durable Functions, SignalR, and Cognito migration guidance
---


# Lambda-to-Functions Skill

## Purpose

Rewrite each AWS Lambda function as an Azure Function with the correct trigger, binding, Python handler signature, and response shape — while preserving 100% of the original business logic.

## When to Use

For every Lambda function listed in `design-document.md` Section 6.

## Process

1. Read the original Lambda handler from `source-app/app-code/lambda/<function>/app.py`.
2. Read `outputs/azure-architecture-output/design-document.md` Section 6 for the target trigger type.
3. Apply the trigger mapping below.
4. Replace the Lambda handler body with the Azure equivalent, preserving all business logic.
5. Write output to `outputs/azure-functions/<function_name>/function_app.py`.
6. Update `outputs/azure-functions/requirements.txt` with Azure SDK packages.
7. Ensure `outputs/azure-functions/host.json` exists with correct runtime version.


## Complete Trigger Mapping Catalog

See [references/trigger-mapping-catalog.md](references/trigger-mapping-catalog.md) for the full per-trigger-type mapping (HTTP, Timer, Blob, Service Bus, Cosmos DB Change Feed, Event Grid, Event Hubs, Durable Functions, SignalR, Cognito), plus the required `host.json`, base `requirements.txt`, and additional-package table by trigger type.

## Rules

- **Never import boto3 in output files.**
- **Always use `DefaultAzureCredential`** for downstream service access — see `skills/azure-auth-patterns/SKILL.md`.
- **Always use `os.environ["VAR_NAME"]`** for environment variables — same pattern as Lambda, different variable names.
- **Never use `context.log()` or Lambda `print()` for logging** — use `logging.getLogger(__name__).info(...)`.
- **Python version must be 3.9–3.11** — never 3.12+ (Azure Functions v4 constraint).
- **Never modify files in `source-app/`** — read only.
- **Preserve 100% of business logic** — only the trigger/response/SDK patterns change.

## Output

- `outputs/azure-functions/<function_name>/function_app.py` — syntactically valid Python, no boto3 imports
- `outputs/azure-functions/requirements.txt` — includes `azure-functions` and all Azure SDK packages
- `outputs/azure-functions/host.json` — valid JSON with extensionBundle version 4.x

---

## References

### Microsoft / Azure Documentation

| Topic | Link |
|---|---|
| Azure Functions Python developer guide | https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-python |
| Azure Functions v2 Python model | https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-python?tabs=get-started%2Casgi%2Capplication-level&pivots=python-mode-decorators |
| Azure Functions triggers and bindings | https://learn.microsoft.com/en-us/azure/azure-functions/functions-triggers-bindings |
| HTTP trigger reference | https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-http-webhook-trigger |
| Timer trigger reference | https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-timer |
| Blob trigger reference | https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-storage-blob-trigger |
| Service Bus trigger reference | https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-service-bus-trigger |
| Cosmos DB trigger reference | https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-cosmosdb-v2-trigger |
| Event Grid trigger reference | https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-event-grid-trigger |
| Event Hubs trigger reference | https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-event-hubs-trigger |
| Durable Functions overview | https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-functions-overview |
| SignalR Service bindings | https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-signalr-service |
| Azure Functions CRON expression syntax | https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-timer#ncrontab-expressions |
| host.json reference | https://learn.microsoft.com/en-us/azure/azure-functions/functions-host-json |
| Extension bundle versions | https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-register#extension-bundles |
| Supported Python versions | https://learn.microsoft.com/en-us/azure/azure-functions/supported-languages#languages-by-runtime-version |
| Azure Durable Functions — Python | https://learn.microsoft.com/en-us/azure/azure-functions/durable/quickstart-python-vscode |

### AWS Documentation

| Topic | Link |
|---|---|
| AWS Lambda Python developer guide | https://docs.aws.amazon.com/lambda/latest/dg/lambda-python.html |
| Lambda event source mappings | https://docs.aws.amazon.com/lambda/latest/dg/invocation-eventsourcemapping.html |
| Lambda triggers — full list | https://docs.aws.amazon.com/lambda/latest/dg/lambda-services.html |
| AWS Step Functions developer guide | https://docs.aws.amazon.com/step-functions/latest/dg/welcome.html |
| Amazon Cognito triggers | https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools-working-with-aws-lambda-triggers.html |

### Best Practices

- **Never use Python 3.12+ with Azure Functions v4** — the worker crashes. Lock `.python-version` to `3.11` in your repository.
- **CRON is 6-part in Azure, 5-part in AWS:** AWS `rate(5 minutes)` = Azure `0 */5 * * * *` (6 fields, leading seconds). Missing the seconds field causes a silent schedule misfire.
- **Cognito triggers have no Azure Functions equivalent trigger** — move that logic to MSAL middleware or Azure AD B2C custom policies.
- **Extension bundles must be v4.x** — v3.x does not support the v2 Python programming model decorator syntax.

