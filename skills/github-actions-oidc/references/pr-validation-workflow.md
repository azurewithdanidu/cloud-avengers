# Quality Gates — PR Validation Workflow

There is no single `main.bicep` — lint and what-if every grouped orchestrator file
(`main.networking.bicep`, `main.security.bicep`, `main.data.bicep`, `main.monitoring.bicep`,
`main.messaging.bicep`, `main.compute.bicep`, or whichever groups the workload uses) using
subscription-scope commands, since each one creates the resource group itself.

```yaml
# .github/workflows/validate-pr.yml
on:
  pull_request:
    branches: [main]

jobs:
  lint-and-validate:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v4

      - name: Azure Login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Lint Bicep (every group file)
        run: |
          for f in outputs/bicep-templates/main.*.bicep; do
            az bicep build --file "$f"
          done

      - name: Bicep What-If (every group, PR comment)
        run: |
          : > what-if-output.txt
          for f in outputs/bicep-templates/main.*.bicep; do
            group=$(basename "$f" .bicep | sed -E 's/^main\.//')
            echo "=== $group ===" >> what-if-output.txt
            az deployment sub what-if \
              --location ${{ vars.LOCATION }} \
              --template-file "$f" \
              --parameters "outputs/bicep-templates/parameters/dev/${group}.bicepparam" \
              2>&1 | tee -a what-if-output.txt
          done

      - name: Post What-If to PR
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const output = fs.readFileSync('what-if-output.txt', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '## Bicep What-If (all groups)\n```\n' + output.slice(0, 60000) + '\n```'
            });
```

