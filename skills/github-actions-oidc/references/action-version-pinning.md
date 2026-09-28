# Action Version Pinning

Always pin action versions to a specific tag or SHA for production workflows:

```yaml
# Pinned versions — update deliberately, not automatically
uses: actions/checkout@v4
uses: actions/setup-python@v5
uses: azure/login@v2
uses: Azure/functions-action@v1
uses: Azure/static-web-apps-deploy@v1
uses: actions/github-script@v7
uses: actions/upload-artifact@v4
```

For highest security, pin to full commit SHA:
```yaml
uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
uses: azure/login@6c251865b4e6290e7b78be643ea2d005bc51f69a       # v2.1.1
```
