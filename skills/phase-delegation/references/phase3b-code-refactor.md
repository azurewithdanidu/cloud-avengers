# Phase 3b — Code Refactor → `@code-refactor`

**Copy-paste prompt**

```text
You are executing Phase 3b — Code Refactor for the AWS-to-Azure migration factory.

Inputs:
- outputs/azure-architecture-output/design-document.md
- Read Section 6 (Function Rewrite Spec) in full before writing any files.
- Read-only source application: source-app/
- Shared task plan: outputs/migration-task-plan.md

Required outputs:
- outputs/azure-functions/function_app.py
- outputs/azure-functions/requirements.txt
- outputs/azure-functions/host.json
- any supporting files needed by the rewritten Azure Functions app

Requirements:
1. Rewrite each Lambda handler described in Section 6 as an Azure Function.
2. Use the trigger type, authentication pattern, SDK mapping, and environment variable names defined in the design document.
3. Do not modify source-app/.
4. Update only your Phase 3b row and Phase 3b task list in outputs/migration-task-plan.md.
5. If the rewrite specification is incomplete, stop and record a blocker instead of inventing interfaces.
```

**Artifact acceptance checks**

| Path | Minimum assertion |
|---|---|
| `outputs/azure-functions/function_app.py` | Exists, non-empty, and contains an Azure Functions application definition such as `FunctionApp` |
| `outputs/azure-functions/requirements.txt` | Exists, non-empty, and includes `azure-functions` plus required Azure SDK packages |
| `outputs/azure-functions/host.json` | Exists, non-empty, and contains JSON configuration |
