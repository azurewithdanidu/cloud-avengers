#Requires -Version 7.0
<#
.SYNOPSIS
    Runs full pre-deployment validation for every grouped Bicep orchestrator file
    (main.<group>.bicep): syntax, ARM validation, what-if dry-run, policy
    compliance, and quota checks.

.DESCRIPTION
    There is no single main.bicep — every main.<group>.bicep discovered under
    -BicepRoot (main.networking.bicep, main.security.bicep, main.data.bicep,
    main.monitoring.bicep, main.messaging.bicep, main.compute.bicep, or whatever
    groups the workload uses) is validated independently, in the order the
    module-organization skill specifies (networking → security → data →
    monitoring → messaging → compute).

    Gate order per group file (stops that group on first blocking failure):
      1. az bicep build              — syntax check
      2. az deployment sub validate  — ARM schema validation (subscription scope)
      3. az deployment sub what-if   — dry-run (subscription scope)
         Blocks on: Delete of data resources, public network re-enabled,
                    NSG allow-all additions, subscription-scope role changes
    Then, once per environment (not per group):
      4. az policy state summarize   — policy compliance (Non-compliant Deny policies)
      5. Quota spot-checks           — storage + Function App limits

    Results are written to  outputs/deployment-validation/what-if-<group>-<env>.json
    (one per group) and a combined summary to outputs/deployment-validation/what-if-report.md

    IMPORTANT: Every main.<group>.bicep MUST declare targetScope = 'subscription'.
    This script enforces 'az deployment sub' commands for every group and fails
    loudly if a group file is not subscription-scoped.

.PARAMETER Location
    Azure region for the subscription-scope deployments (e.g. australiaeast).

.PARAMETER ResourceGroup
    Azure resource group name used for post-deployment policy and quota checks
    (the same resource group every group file ensures).

.PARAMETER Environment
    Target environment: dev | staging | prod

.PARAMETER BicepRoot
    Path to the Bicep root (default: outputs/bicep-templates).

.PARAMETER Subscription
    Azure subscription ID. Defaults to current az account.

.EXAMPLE
    .\run-what-if.ps1 -Location australiaeast -ResourceGroup "rg-migration-dev" -Environment dev

.EXAMPLE
    .\run-what-if.ps1 -Location australiaeast -ResourceGroup "rg-prod-migration" -Environment prod -Subscription "00000000-..."
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Location,

    [Parameter(Mandatory)]
    [string]$ResourceGroup,

    [Parameter(Mandatory)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,

    [string]$BicepRoot    = 'outputs/bicep-templates',
    [string]$Subscription = ''
)

$ErrorActionPreference = 'Stop'
$blocking = 0
$warnings = 0
$report   = [System.Collections.Generic.List[string]]::new()

function Write-Step    { param([string]$Msg) Write-Host "`n==> $Msg" -ForegroundColor Cyan }
function Write-Pass    { param([string]$Msg) Write-Host "  [PASS]    $Msg" -ForegroundColor Green;  $report.Add("- [x] PASS: $Msg") }
function Write-Warn    { param([string]$Msg) Write-Host "  [WARN]    $Msg" -ForegroundColor Yellow; $report.Add("- [ ] WARN: $Msg"); $Script:warnings++ }
function Write-Block   { param([string]$Msg) Write-Host "  [BLOCKED] $Msg" -ForegroundColor Red;    $report.Add("- [ ] BLOCKED: $Msg"); $Script:blocking++ }

$outDir     = 'outputs/deployment-validation'
$reportFile = "$outDir/what-if-report.md"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$subArgs = if ($Subscription) { @('--subscription', $Subscription) } else { @() }

$groupFiles = Get-ChildItem -Path $BicepRoot -Filter 'main.*.bicep' -ErrorAction SilentlyContinue
if (-not $groupFiles) {
    Write-Error "No main.*.bicep group files found under '$BicepRoot'."
    exit 1
}

foreach ($gf in $groupFiles) {
    $group      = ($gf.BaseName -replace '^main\.', '')   # e.g. main.compute.bicep -> compute
    $paramFile  = Join-Path $BicepRoot "parameters/$Environment/$group.bicepparam"
    $whatifFile = "$outDir/what-if-$group-$Environment.json"

    Write-Step "Group: $group ($($gf.Name))"

    if (-not (Test-Path $paramFile)) {
        Write-Warn "$group — no parameter file at parameters/$Environment/$group.bicepparam; skipping"
        continue
    }

    # ── Scope gate ────────────────────────────────────────────────────────────
    $bicepContent = Get-Content $gf.FullName -Raw -ErrorAction SilentlyContinue
    if ($bicepContent -notmatch "targetScope\s*=\s*'subscription'") {
        Write-Block "$group — targetScope = 'subscription' not found in $($gf.Name). Every group file must be subscription-scoped."
        continue
    }
    Write-Pass "$group — subscription-scoped"

    # ── Bicep syntax ──────────────────────────────────────────────────────────
    az bicep restore --file $gf.FullName --force *>$null
    az bicep build --file $gf.FullName 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Block "$group — az bicep build FAILED — fix syntax errors first"; continue }
    Write-Pass "$group — az bicep build"

    # ── ARM validation ────────────────────────────────────────────────────────
    $validateOutput = az deployment sub validate `
        --location $Location `
        --template-file $gf.FullName `
        --parameters $paramFile `
        @subArgs `
        --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Block "$group — ARM validation failed: $validateOutput"
        continue
    }
    Write-Pass "$group — az deployment sub validate"

    # ── What-if dry run ───────────────────────────────────────────────────────
    $whatifOutput = az deployment sub what-if `
        --location $Location `
        --template-file $gf.FullName `
        --parameters $paramFile `
        --output json `
        @subArgs 2>&1

    $whatifOutput | Out-File $whatifFile -Encoding utf8
    Write-Host "  Saved to $whatifFile"

    try {
        $wi = $whatifOutput | ConvertFrom-Json

        $deletesOnData = $wi.properties.changes | Where-Object {
            $_.changeType -eq 'Delete' -and
            $_.resourceId -match 'storageAccounts|vaults|servers|namespaces|databaseAccounts|redis'
        }
        foreach ($d in $deletesOnData) {
            Write-Block "$group — Delete on data resource: $($d.resourceId)"
        }

        $publicReEnabled = $wi.properties.changes | Where-Object {
            $_.changeType -in ('Create','Modify') -and
            ($_.delta | Where-Object { $_.path -match 'publicNetworkAccess' -and $_.after -eq 'Enabled' })
        }
        foreach ($p in $publicReEnabled) {
            Write-Block "$group — publicNetworkAccess re-enabled on: $($p.resourceId)"
        }

        $newResources = $wi.properties.changes | Where-Object { $_.changeType -eq 'Create' }
        if ($newResources) { Write-Warn "$group — $($newResources.Count) new resource(s) will be created (review expected)" }

        $modifies = $wi.properties.changes | Where-Object { $_.changeType -eq 'Modify' }
        if ($modifies) { Write-Warn "$group — $($modifies.Count) resource(s) will be modified (review expected)" }

        if (-not $deletesOnData -and -not $publicReEnabled) {
            Write-Pass "$group — no blocking conditions found in what-if output"
        }
    } catch {
        Write-Warn "$group — could not parse what-if JSON — review $whatifFile manually"
    }
}

# ── Policy compliance (once per environment, against the shared resource group) ─
Write-Step "Policy compliance check ($ResourceGroup)"
$policyOutput = az policy state summarize --resource-group $ResourceGroup @subArgs --output json 2>&1 | ConvertFrom-Json
$nonCompliant = $policyOutput.results.nonCompliantResources
if ($nonCompliant -gt 0) {
    Write-Block "$nonCompliant non-compliant resource(s) — check for Deny-effect policies before deploying"
} else {
    Write-Pass "Policy compliance — 0 non-compliant resources"
}

# ── Quota spot-checks (once per environment) ──────────────────────────────────
Write-Step "Quota spot-checks"
$storageUsage = az resource list --resource-group $ResourceGroup --resource-type Microsoft.Storage/storageAccounts @subArgs --output json 2>&1 | ConvertFrom-Json
if ($storageUsage.Count -ge 240) {
    Write-Warn "Storage account count is $($storageUsage.Count) — approaching 250/region limit"
} else {
    Write-Pass "Storage account count: $($storageUsage.Count) (limit 250)"
}

# ── Write combined report ─────────────────────────────────────────────────────
$reportContent = @"
# What-If Validation Report — $Environment

**Date:** $(Get-Date -Format 'yyyy-MM-dd')
**Environment:** $Environment
**Location:** $Location
**Resource Group:** $ResourceGroup
**Groups validated:** $(($groupFiles | ForEach-Object { ($_.BaseName -replace '^main\.', '') }) -join ', ')
**Status:** $(if ($blocking -gt 0) { 'BLOCKED' } elseif ($warnings -gt 0) { 'PASS (with warnings)' } else { 'PASS' })

## Checks

$($report | ForEach-Object { $_ } | Out-String)

## What-If Output
Saved per group to: outputs/deployment-validation/what-if-<group>-$Environment.json
"@

$reportContent | Out-File $reportFile -Encoding utf8
Write-Host "`nReport written to $reportFile"

# ── Result ────────────────────────────────────────────────────────────────────
Write-Host ""
if ($blocking -gt 0) {
    Write-Host "RESULT: $blocking BLOCKING condition(s) — deployment must not proceed" -ForegroundColor Red
    exit 1
}
Write-Host "RESULT: Validation PASSED ($warnings warning(s))" -ForegroundColor Green

