#Requires -Version 7.0
<#
.SYNOPSIS
    Validates every grouped Bicep orchestrator file (main.*.bicep) under a directory and
    runs az deployment sub what-if for every matching environment/group parameter file.

.DESCRIPTION
    Performs these checks in order:
      1. az bicep restore — pull AVM module cache for every main.*.bicep (required before building)
      2. az bicep build   — syntax validation on every main.*.bicep file
      3. az deployment sub what-if — subscription-scope dry-run for each
         parameters/<Environment>/<group>.bicepparam file, matched to its main.<group>.bicep
         (requires Location; ResourceGroup is only used to scope the blocking-delete check)

    There is no single main.bicep — every group (main.networking.bicep, main.security.bicep,
    main.data.bicep, main.monitoring.bicep, main.messaging.bicep, main.compute.bicep, or
    whatever groups the workload uses) is validated independently.

    Exits 0 only when all checks pass.  Any failure exits 1.

.PARAMETER BicepRoot
    Path to the Bicep root folder containing the main.*.bicep group files. Defaults to
    "outputs/bicep-templates" (relative to the repo root).

.PARAMETER Environment
    Environment folder under parameters/ to run what-if against (dev | staging | prod).
    If omitted, what-if is skipped and only syntax validation runs.

.PARAMETER Location
    Azure region for the subscription-scope what-if calls (e.g. australiaeast). Required
    when -Environment is supplied.

.PARAMETER Subscription
    Azure subscription ID. If omitted, uses the current az account.

.EXAMPLE
    # Syntax-only validation (no Azure login required)
    .\validate-bicep.ps1

.EXAMPLE
    # Full validation including what-if dry runs for every group in dev
    .\validate-bicep.ps1 -Environment dev -Location australiaeast -Subscription "00000000-0000-0000-0000-000000000000"
#>

[CmdletBinding()]
param (
    [string]$BicepRoot     = 'outputs/bicep-templates',
    [string]$Environment   = '',
    [string]$Location      = '',
    [string]$Subscription  = ''
)

$ErrorActionPreference = 'Stop'
$errors = 0

function Write-Step  { param([string]$Msg) Write-Host "`n==> $Msg" -ForegroundColor Cyan }
function Write-Pass  { param([string]$Msg) Write-Host "  [PASS] $Msg" -ForegroundColor Green }
function Write-Fail  { param([string]$Msg) Write-Host "  [FAIL] $Msg" -ForegroundColor Red; $Script:errors++ }

# ── Step 1: Discover group files ───────────────────────────────────────────────
$groupFiles = Get-ChildItem -Path $BicepRoot -Filter 'main.*.bicep' -ErrorAction SilentlyContinue
if (-not $groupFiles) {
    Write-Error "No main.*.bicep group files found under '$BicepRoot'. Adjust -BicepRoot."
    exit 1
}

# ── Step 2: Restore AVM modules for every group file ──────────────────────────
Write-Step "Restoring AVM module cache for $($groupFiles.Count) group file(s)"
foreach ($gf in $groupFiles) {
    az bicep restore --file $gf.FullName --force
    if ($LASTEXITCODE -ne 0) { Write-Fail "az bicep restore failed for $($gf.Name)" }
    else { Write-Pass "az bicep restore — $($gf.Name)" }
}

# ── Step 3: Build (syntax-check) every group file ─────────────────────────────
Write-Step "Building (syntax-checking) every main.*.bicep group file"
foreach ($gf in $groupFiles) {
    $result = az bicep build --file $gf.FullName 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "$($gf.Name)`n$result"
    } else {
        Write-Pass $gf.Name
    }
}

# ── Step 4: What-if for each group's parameter file in the target environment ─
if ($Environment) {
    if (-not $Location) {
        Write-Error "-Location is required when -Environment is supplied (subscription-scope what-if)."
        exit 1
    }

    $paramsDir = Join-Path $BicepRoot "parameters/$Environment"
    $paramFiles = Get-ChildItem -Path $paramsDir -Filter '*.bicepparam' -ErrorAction SilentlyContinue

    if (-not $paramFiles) {
        Write-Host "  No .bicepparam files found under $paramsDir — skipping what-if" -ForegroundColor Yellow
    } else {
        Write-Step "Running subscription-scope what-if for each group in '$Environment'"

        $subArgs = if ($Subscription) { @('--subscription', $Subscription) } else { @() }

        foreach ($pf in $paramFiles) {
            $group = $pf.BaseName   # networking | security | data | monitoring | messaging | compute
            $groupBicep = Join-Path $BicepRoot "main.$group.bicep"

            if (-not (Test-Path $groupBicep)) {
                Write-Fail "$group — no matching main.$group.bicep found for parameters/$Environment/$($pf.Name)"
                continue
            }

            Write-Host "  what-if: $group ..." -NoNewline

            $whatifJson = az deployment sub what-if `
                --location $Location `
                --template-file $groupBicep `
                --parameters $pf.FullName `
                --output json `
                @subArgs 2>&1

            if ($LASTEXITCODE -ne 0) {
                Write-Fail "what-if failed for $group`n$whatifJson"
                continue
            }

            # Check for blocking conditions
            try {
                $wi = $whatifJson | ConvertFrom-Json
                $blocking = $wi.properties.changes | Where-Object {
                    $_.changeType -eq 'Delete' -and
                    $_.resourceId -match 'storageAccounts|vaults|servers|namespaces|databaseAccounts'
                }
                if ($blocking) {
                    Write-Fail "$group — BLOCKING DELETE on data resource(s):"
                    $blocking | ForEach-Object { Write-Host "      DELETE: $($_.resourceId)" -ForegroundColor Red }
                } else {
                    Write-Pass "$group — no blocking changes"
                }
            } catch {
                Write-Host " (could not parse JSON — review manually)" -ForegroundColor Yellow
            }
        }
    }
} else {
    Write-Host "`n  -Environment not supplied — skipping what-if dry runs" -ForegroundColor Yellow
}

# ── Result ────────────────────────────────────────────────────────────────────
Write-Host ""
if ($errors -gt 0) {
    Write-Host "RESULT: $errors check(s) FAILED" -ForegroundColor Red
    exit 1
}
Write-Host "RESULT: All Bicep validation checks PASSED" -ForegroundColor Green

