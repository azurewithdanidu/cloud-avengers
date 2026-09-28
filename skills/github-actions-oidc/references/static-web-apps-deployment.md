# Azure Static Web Apps Deployment

```yaml
jobs:
  deploy-static-web:
    runs-on: ubuntu-latest
    environment: ${{ vars.ENV }}
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4

      # SWA requires index.html as default document — verify before deploy
      - name: Verify index.html exists
        run: |
          if [ ! -f "source-app/app-code/build/index.html" ]; then
            echo "ERROR: index.html not found. SWA requires index.html as the default document."
            exit 1
          fi

      - name: Deploy to Azure Static Web Apps
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.STATIC_WEB_APP_TOKEN }}
          action: upload
          app_location: source-app/app-code/build   # Folder containing index.html
          skip_app_build: true                        # Pre-built; do not re-build
```

**Critical SWA rules:**
- `index.html` MUST exist as the default document — `app.html` alone is rejected
- Use `skip_app_build: true` for pre-built apps
- The SWA deployment token comes from the Bicep `outputs.staticWebAppDeploymentToken`; store in `STATIC_WEB_APP_TOKEN` GitHub Secret
- Wrong args to avoid: `--skipBuild`, `--branch`, `--deploymentToken` (use `--apiToken`)
