#!/usr/bin/env bash
# Pre-deployment validation for every grouped Bicep orchestrator file (main.<group>.bicep):
# syntax, ARM validation (subscription scope), what-if dry-run, policy check, quota check.
# Usage: run-what-if.sh --location <region> --resource-group <rg> --environment <dev|staging|prod> [--bicep-root <path>] [--subscription <id>]
#
# NOTE: There is no single main.bicep — every main.<group>.bicep discovered under
#       --bicep-root (main.networking.bicep, main.security.bicep, main.data.bicep,
#       main.monitoring.bicep, main.messaging.bicep, main.compute.bicep, or whatever
#       groups the workload uses) is validated independently using subscription-scope
#       commands (az deployment sub ...), because every group file declares
#       targetScope = 'subscription' and creates the shared resource group itself.
#       The --resource-group flag is still required for post-deployment policy and
#       quota checks, which run once per environment (not per group).
#
# Outputs:
#   outputs/deployment-validation/what-if-<group>-<env>.json  (one per group)
#   outputs/deployment-validation/what-if-report.md           (combined summary)
# Exits 1 if any BLOCKING condition is found.

set -euo pipefail

LOCATION=""
RESOURCE_GROUP=""
ENVIRONMENT=""
BICEP_ROOT="outputs/bicep-templates"
SUBSCRIPTION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --location)        LOCATION="$2";       shift 2 ;;
    --resource-group)  RESOURCE_GROUP="$2"; shift 2 ;;
    --environment)     ENVIRONMENT="$2";    shift 2 ;;
    --bicep-root)      BICEP_ROOT="$2";     shift 2 ;;
    --subscription)    SUBSCRIPTION="$2";   shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

[[ -z "$LOCATION" ]]       && { echo "ERROR: --location is required (e.g. australiaeast)"; exit 1; }
[[ -z "$RESOURCE_GROUP" ]] && { echo "ERROR: --resource-group is required (for post-deploy checks)"; exit 1; }
[[ -z "$ENVIRONMENT" ]]    && { echo "ERROR: --environment is required (dev|staging|prod)"; exit 1; }
[[ "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]] || { echo "ERROR: --environment must be dev, staging, or prod"; exit 1; }

OUT_DIR="outputs/deployment-validation"
REPORT_FILE="$OUT_DIR/what-if-report.md"
mkdir -p "$OUT_DIR"

GROUP_FILES=()
while IFS= read -r -d '' f; do
  GROUP_FILES+=("$f")
done < <(find "$BICEP_ROOT" -maxdepth 1 -name "main.*.bicep" -print0 2>/dev/null || true)

if [[ "${#GROUP_FILES[@]}" -eq 0 ]]; then
  echo "ERROR: No main.*.bicep group files found under '$BICEP_ROOT'."
  exit 1
fi

SUB_ARGS=()
[[ -n "$SUBSCRIPTION" ]] && SUB_ARGS=(--subscription "$SUBSCRIPTION")

BLOCKING=0
WARNINGS=0
REPORT_LINES=()
GROUP_NAMES=()

step()    { echo; echo "==> $1"; }
pass()    { echo "  [PASS]    $1"; REPORT_LINES+=("- [x] PASS: $1"); }
warn()    { echo "  [WARN]    $1"; REPORT_LINES+=("- [ ] WARN: $1"); ((WARNINGS++)); }
block()   { echo "  [BLOCKED] $1"; REPORT_LINES+=("- [ ] BLOCKED: $1"); ((BLOCKING++)); }

for MAIN_BICEP in "${GROUP_FILES[@]}"; do
  GROUP_FNAME=$(basename "$MAIN_BICEP")
  GROUP=$(echo "$GROUP_FNAME" | sed -E 's/^main\.(.+)\.bicep$/\1/')
  GROUP_NAMES+=("$GROUP")
  PARAM_FILE="$BICEP_ROOT/parameters/$ENVIRONMENT/$GROUP.bicepparam"
  WHATIF_FILE="$OUT_DIR/what-if-$GROUP-$ENVIRONMENT.json"

  step "Group: $GROUP ($GROUP_FNAME)"

  if [[ ! -f "$PARAM_FILE" ]]; then
    warn "$GROUP — no parameter file at parameters/$ENVIRONMENT/$GROUP.bicepparam; skipping"
    continue
  fi

  # ── Scope gate ───────────────────────────────────────────────────────────
  if ! grep -q "targetScope *= *'subscription'" "$MAIN_BICEP" 2>/dev/null; then
    block "$GROUP — targetScope = 'subscription' not found in $GROUP_FNAME. Every group file must be subscription-scoped."
    continue
  fi
  pass "$GROUP — subscription-scoped"

  # ── Bicep syntax ─────────────────────────────────────────────────────────
  az bicep restore --file "$MAIN_BICEP" --force &>/dev/null
  if ! az bicep build --file "$MAIN_BICEP" 2>&1; then
    block "$GROUP — az bicep build FAILED — fix syntax errors first"
    continue
  fi
  pass "$GROUP — az bicep build"

  # ── ARM validation ───────────────────────────────────────────────────────
  if ! az deployment sub validate \
      --location "$LOCATION" \
      --template-file "$MAIN_BICEP" \
      --parameters "$PARAM_FILE" \
      "${SUB_ARGS[@]}" \
      --output json &>/dev/null; then
    block "$GROUP — ARM validation failed — run manually for details"
    continue
  fi
  pass "$GROUP — az deployment sub validate"

  # ── What-if dry run ──────────────────────────────────────────────────────
  az deployment sub what-if \
      --location "$LOCATION" \
      --template-file "$MAIN_BICEP" \
      --parameters "$PARAM_FILE" \
      --output json \
      "${SUB_ARGS[@]}" 2>&1 > "$WHATIF_FILE" || true

  echo "  Saved to $WHATIF_FILE"

  if command -v jq &>/dev/null && [[ -s "$WHATIF_FILE" ]]; then
    DELETES=$(jq -r '.properties.changes[]? | select(.changeType=="Delete") | select(.resourceId | test("storageAccounts|vaults|servers|namespaces|databaseAccounts|redis")) | .resourceId' "$WHATIF_FILE" 2>/dev/null || true)
    while IFS= read -r rid; do
      [[ -n "$rid" ]] && block "$GROUP — Delete on data resource: $rid"
    done <<< "$DELETES"

    NEW_COUNT=$(jq '[.properties.changes[]? | select(.changeType=="Create")] | length' "$WHATIF_FILE" 2>/dev/null || echo 0)
    MOD_COUNT=$(jq '[.properties.changes[]? | select(.changeType=="Modify")] | length' "$WHATIF_FILE" 2>/dev/null || echo 0)
    [[ "$NEW_COUNT" -gt 0 ]] && warn "$GROUP — $NEW_COUNT new resource(s) will be created (review expected)"
    [[ "$MOD_COUNT" -gt 0 ]] && warn "$GROUP — $MOD_COUNT resource(s) will be modified (review expected)"
    [[ -z "$DELETES" ]] && pass "$GROUP — no blocking conditions found in what-if output"
  else
    warn "$GROUP — could not parse what-if JSON — review $WHATIF_FILE manually"
  fi
done

# ── Policy compliance (once per environment, against the shared resource group) ─
step "Policy compliance check ($RESOURCE_GROUP)"
NON_COMPLIANT=$(az policy state summarize --resource-group "$RESOURCE_GROUP" "${SUB_ARGS[@]}" --output json 2>/dev/null \
  | jq '.results.nonCompliantResources // 0' 2>/dev/null || echo 0)
if [[ "$NON_COMPLIANT" -gt 0 ]]; then
  block "$NON_COMPLIANT non-compliant resource(s) — check for Deny-effect policies before deploying"
else
  pass "Policy compliance — 0 non-compliant resources"
fi

# ── Quota spot-check (once per environment) ───────────────────────────────────
step "Quota spot-checks"
STOR_COUNT=$(az resource list --resource-group "$RESOURCE_GROUP" \
  --resource-type Microsoft.Storage/storageAccounts "${SUB_ARGS[@]}" --output json 2>/dev/null \
  | jq 'length' 2>/dev/null || echo 0)
if [[ "$STOR_COUNT" -ge 240 ]]; then
  warn "Storage account count is $STOR_COUNT — approaching 250/region limit"
else
  pass "Storage account count: $STOR_COUNT (limit 250)"
fi

# ── Write combined report ──────────────────────────────────────────────────────
STATUS="PASS"
[[ "$BLOCKING" -gt 0 ]] && STATUS="BLOCKED"
[[ "$BLOCKING" -eq 0 && "$WARNINGS" -gt 0 ]] && STATUS="PASS (with warnings)"

{
  echo "# What-If Validation Report — $ENVIRONMENT"
  echo ""
  echo "**Date:** $(date -u '+%Y-%m-%d')"
  echo "**Environment:** $ENVIRONMENT"
  echo "**Location:** $LOCATION"
  echo "**Resource Group:** $RESOURCE_GROUP"
  echo "**Groups validated:** $(IFS=', '; echo "${GROUP_NAMES[*]}")"
  echo "**Status:** $STATUS"
  echo ""
  echo "## Checks"
  echo ""
  for line in "${REPORT_LINES[@]}"; do echo "$line"; done
  echo ""
  echo "## What-If Output"
  echo "Saved per group to: outputs/deployment-validation/what-if-<group>-$ENVIRONMENT.json"
} > "$REPORT_FILE"

echo ""
echo "Report written to $REPORT_FILE"

if [[ "$BLOCKING" -gt 0 ]]; then
  echo "RESULT: $BLOCKING BLOCKING condition(s) — deployment must not proceed"
  exit 1
fi
echo "RESULT: Validation PASSED ($WARNINGS warning(s))"

