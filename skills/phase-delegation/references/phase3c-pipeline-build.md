# Phase 3c — Pipeline Build → `@pipeline-builder-agent`

**Copy-paste prompt**

```text
You are executing Phase 3c — Pipeline Build for the AWS-to-Azure migration factory.

Inputs:
- outputs/azure-architecture-output/design-document.md
- Read Section 11 (CI/CD Spec) in full before writing any files.
- Shared task plan: outputs/migration-task-plan.md

Required outputs:
- one or more workflow files under .github/workflows/
- at least one infrastructure deployment workflow
- environment and OIDC references aligned with the CI/CD specification

Requirements:
1. Implement every workflow listed in Section 11.1.
2. Use OIDC / workload identity, not long-lived Azure secrets.
3. Encode dev, staging, and prod promotion logic in the workflow design.
4. Update only your Phase 3c row and Phase 3c task list in outputs/migration-task-plan.md.
5. If Section 11 lacks exact deployment details, stop and record a blocker instead of inventing workflow behavior.
```

**Artifact acceptance checks**

| Path | Minimum assertion |
|---|---|
| `.github/workflows/` | Contains at least one `.yml` or `.yaml` file |
| one workflow file with `infra` or `deploy` in the file name | Contains Azure login and deployment steps |
| every created workflow file | Non-empty and includes a valid `on:` trigger block |
