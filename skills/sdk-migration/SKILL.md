---
name: sdk-migration
description: Replace AWS SDK calls with Azure SDK equivalents — Python (boto3), Node.js/TypeScript (@aws-sdk), and Java (AWS SDK v2) package mapping, client instantiation, authentication, and runtime gotchas
---


# SDK Migration Skill

## Purpose

Replace every boto3 (Python), `@aws-sdk` (Node.js/TypeScript), and AWS SDK v2 (Java) API call with the correct Azure SDK equivalent, ensuring no AWS SDK dependencies remain in refactored output files.

## When to Use

When rewriting Lambda source files or other application code that contains boto3, `@aws-sdk`, or `software.amazon.awssdk` imports.

## Inputs

| Path | Why it matters |
|---|---|
| `source-app/app-code/lambda/` | Source Lambda handlers containing boto3 / @aws-sdk calls to replace |
| `outputs/azure-architecture-output/design-document.md` | Section 6 specifies the target SDK, auth pattern, and environment variable names per function |
| `outputs/azure-functions/requirements.txt` | Updated with Azure SDK packages as replacements are made |
## Process

1. Scan the source for all AWS SDK usage:
   ```bash
   # Python
   grep -n "boto3\.\|@aws-sdk\|import boto3" source-app/app-code/lambda/<function>/app.py
   # Node.js/TypeScript
   grep -rn "@aws-sdk" source-app/app-code/
   # Java
   grep -rn "software.amazon.awssdk" source-app/app-code/
   ```
2. Load only the mapping reference for the language detected in step 1 — do not load the others:
   - Python (`boto3`) → [references/python-sdk-mappings.md](references/python-sdk-mappings.md)
   - Node.js/TypeScript (`@aws-sdk`) → [references/nodejs-sdk-mappings.md](references/nodejs-sdk-mappings.md)
   - Java (`software.amazon.awssdk`) → [references/java-sdk-mappings.md](references/java-sdk-mappings.md)
3. Apply the matching pattern from the reference file, then replace the import block at the top of the file.
4. Add the required packages from [references/package-reference.md](references/package-reference.md) to `outputs/azure-functions/requirements.txt` (or `package.json` / `pom.xml`).
5. Rename any environment variables per [references/env-and-error-mapping.md](references/env-and-error-mapping.md), watching for reserved Azure Functions names.
6. Run validation: `grep -rn "boto3\|@aws-sdk" outputs/azure-functions/` must return no matches.

---

## Python Runtime Gotchas (Read First)

**Python 3.13 is NOT supported** by Azure Functions v4 — it crashes the worker process with a `0xC0000005` Access Violation. Supported versions: **Python 3.9, 3.10, 3.11 only**.

```bash
# Always create .venv using Python 3.11
python3.11 -m venv .venv

# If Python 3.11 is not installed (Linux):
sudo apt install python3.11 python3.11-venv
```

Azure Functions Core Tools must be v4:
```bash
npm install -g azure-functions-core-tools@4
```

---

## Reference Files

Load only the file relevant to the current task — do not load all of them:

| File | Load when |
|---|---|
| [references/python-sdk-mappings.md](references/python-sdk-mappings.md) | Refactoring a `boto3` source file (Storage, DynamoDB, SQS, Secrets Manager, Lambda handler patterns) |
| [references/nodejs-sdk-mappings.md](references/nodejs-sdk-mappings.md) | Refactoring an `@aws-sdk` source file (S3, DynamoDB, EventBridge patterns) |
| [references/java-sdk-mappings.md](references/java-sdk-mappings.md) | Refactoring a `software.amazon.awssdk` source file (S3, DynamoDB, SQS, Secrets Manager, SNS patterns) |
| [references/package-reference.md](references/package-reference.md) | Updating `requirements.txt`, `package.json`, or `pom.xml` with Azure SDK packages |
| [references/env-and-error-mapping.md](references/env-and-error-mapping.md) | Renaming environment variables or translating AWS error codes/handling to Azure equivalents |

---

## Rules

- **Never leave any `import boto3` or `@aws-sdk` in output files** — verify with `grep -rn "boto3\|@aws-sdk" outputs/azure-functions/`.
- **Never use `ClientSecretCredential` or hardcoded keys** — always `DefaultAzureCredential`.
- **Never call Key Vault SDK at runtime for secrets** unless the secret changes frequently — prefer app setting Key Vault references.
- **Never use `CONTAINER_NAME`** as an env var name — use `BLOB_CONTAINER_NAME` instead (reserved name).
- **Always update `requirements.txt`** with every new Azure package added.
- **Always use Python 3.11** — 3.12 and 3.13 are not supported by Azure Functions v4.

## Outputs

- Refactored Python/TypeScript files with zero boto3 / @aws-sdk references
- `outputs/azure-functions/requirements.txt` listing all Azure SDK packages used
- `grep -rn "boto3\|@aws-sdk" outputs/azure-functions/` returns no matches

---

## Scripts

| Script | Purpose |
|---|---|
| `scripts/scan-aws-sdk.ps1` | Scans output code for residual AWS SDK imports; exits 1 if any found |
| `scripts/scan-aws-sdk.sh` | Bash equivalent of the above |

Run after every refactoring pass to verify no AWS SDK references remain:

```powershell
./scripts/scan-aws-sdk.ps1 -ScanPath "outputs/azure-functions"
```

Also wire into CI as a gate step before the deployment job:

```yaml
- name: Scan for AWS SDK residue
  run: pwsh scripts/scan-aws-sdk.ps1
```

---

## References

### Microsoft / Azure Documentation

| Topic | Link |
|---|---|
| Azure SDK for Python overview | https://learn.microsoft.com/en-us/azure/developer/python/sdk/azure-sdk-overview |
| azure-storage-blob (Python) | https://learn.microsoft.com/en-us/python/api/overview/azure/storage-blob-readme |
| azure-cosmos (Python) | https://learn.microsoft.com/en-us/python/api/overview/azure/cosmos-readme |
| azure-servicebus (Python) | https://learn.microsoft.com/en-us/python/api/overview/azure/servicebus-readme |
| azure-eventgrid (Python) | https://learn.microsoft.com/en-us/python/api/overview/azure/eventgrid-readme |
| azure-eventhub (Python) | https://learn.microsoft.com/en-us/python/api/overview/azure/eventhub-readme |
| azure-identity (Python) | https://learn.microsoft.com/en-us/python/api/overview/azure/identity-readme |
| azure-keyvault-secrets (Python) | https://learn.microsoft.com/en-us/python/api/overview/azure/keyvault-secrets-readme |
| Azure SDK for JavaScript | https://learn.microsoft.com/en-us/azure/developer/javascript/sdk/azure-sdk-overview |
| @azure/storage-blob (JS/TS) | https://learn.microsoft.com/en-us/javascript/api/overview/azure/storage-blob-readme |
| @azure/cosmos (JS/TS) | https://learn.microsoft.com/en-us/javascript/api/overview/azure/cosmos-readme |
| @azure/service-bus (JS/TS) | https://learn.microsoft.com/en-us/javascript/api/overview/azure/service-bus-readme |
| Azure SDK for Java overview | https://learn.microsoft.com/en-us/azure/developer/java/sdk/overview |
| Azure SDK BOM (Java) | https://learn.microsoft.com/en-us/azure/developer/java/sdk/azure-sdk-library-package-index |
| Azure Functions reserved env vars | https://learn.microsoft.com/en-us/azure/azure-functions/functions-app-settings |
| Key Vault references in App Service | https://learn.microsoft.com/en-us/azure/app-service/app-service-key-vault-references |

### AWS Documentation

| Topic | Link |
|---|---|
| boto3 SDK reference | https://boto3.amazonaws.com/v1/documentation/api/latest/index.html |
| boto3 S3 client | https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html |
| boto3 DynamoDB resource | https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/dynamodb.html |
| boto3 SQS client | https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/sqs.html |
| boto3 Secrets Manager client | https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager.html |
| AWS SDK for JavaScript v3 | https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/ |
| AWS SDK for Java v2 | https://docs.aws.amazon.com/sdk-for-java/latest/developer-guide/home.html |

### Best Practices

- **Zero-tolerance for AWS SDK residue:** Run `grep -rn "boto3\|@aws-sdk\|software.amazon.awssdk" outputs/azure-functions/` as the final gate before declaring migration done.
- **Key Vault references over SDK:** For secrets that don't change at runtime, inject via `@Microsoft.KeyVault(SecretUri=...)` in app settings \u2014 no SDK call, no latency, no token refresh logic needed.
- **Azure SDK BOM for Java:** Always use the BOM to avoid version conflicts between Azure SDK artifacts \u2014 never specify individual artifact versions manually.
- **`DefaultAzureCredential` is environment-agnostic:** The same code runs on a developer's laptop (`az login`), in CI (environment credentials), and in Azure (managed identity). This is by design \u2014 never override it with `ManagedIdentityCredential` or `ClientSecretCredential`.

---

## Runtime Detection

This skill supports both Bash and PowerShell. Use the following detection order:

| Priority | Runtime | Condition | Script |
|---|---|---|---|
| 1 (preferred) | Bash | `curl` and `jq` available on PATH | `scripts/<name>.sh` |
| 2 | PowerShell 7+ | `pwsh` available on PATH | `scripts/<name>.ps1` |
| 3 (fallback) | Windows PowerShell 5.1 | `powershell.exe` available | `scripts/<name>.ps1 -ExecutionPolicy RemoteSigned` |

**Detection snippet (Bash):**
```bash
if command -v curl &>/dev/null && command -v jq &>/dev/null; then
  bash scripts/<name>.sh [args]
elif command -v pwsh &>/dev/null; then
  pwsh -File scripts/<name>.ps1 [args]
elif command -v powershell.exe &>/dev/null; then
  powershell.exe -ExecutionPolicy RemoteSigned -File scripts/<name>.ps1 [args]
else
  echo "ERROR: Requires curl+jq (Bash) or PowerShell 7+ (pwsh)"
  exit 1
fi
```

**Parameter naming convention:** Bash uses `--kebab-case`; PowerShell uses `-PascalCase`. Both produce identical output.

