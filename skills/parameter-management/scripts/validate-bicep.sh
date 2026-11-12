#!/usr/bin/env bash
# Validate every grouped Bicep orchestrator file (main.*.bicep) and optionally run
# subscription-scope what-if for each matching environment/group parameter file.
# Usage: validate-bicep.sh [--bicep-root <path>] [--environment <dev|staging|prod>] [--location <region>] [--subscription <id>]
#
# --environment is optional. If omitted, what-if dry runs are skipped (syntax-only).
# --location is required when --environment is supplied (subscription-scope what-if).
# There is no single main.bicep — every main.<group>.bicep is validated independently.
# Exits 1 if any check fails.

set -euo pipefail

BICEP_ROOT="outputs/bicep-templates"
ENVIRONMENT=""
LOCATION=""
SUBSCRIPTION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bicep-root)   BICEP_ROOT="$2";   shift 2 ;;
    --environment)  ENVIRONMENT="$2";  shift 2 ;;
    --location)     LOCATION="$2";     shift 2 ;;
    --subscription) SUBSCRIPTION="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

GROUP_FILES=()
while IFS= read -r -d '' f; do
  GROUP_FILES+=("$f")
done < <(find "$BICEP_ROOT" -maxdepth 1 -name "main.*.bicep" -print0 2>/dev/null || true)

if [[ "${#GROUP_FILES[@]}" -eq 0 ]]; then
  echo "ERROR: No main.*.bicep group files found under '$BICEP_ROOT'. Adjust --bicep-root."
  exit 1
fi

SUB_ARGS=()
[[ -n "$SUBSCRIPTION" ]] && SUB_ARGS=(--subscription "$SUBSCRIPTION")

ERRORS=0

pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; ERRORS=$((ERRORS + 1)); }

# ── Step 1: Restore AVM modules for every group file ──────────────────────────
echo ""
echo "==> Restoring AVM module cache for ${#GROUP_FILES[@]} group file(s)"
for gf in "${GROUP_FILES[@]}"; do
  if az bicep restore --file "$gf" --force 2>&1; then
    pass "az bicep restore — $(basename "$gf")"
  else
    fail "az bicep restore failed for $(basename "$gf")"
  fi
done

# ── Step 2: Build (syntax-check) every group file ─────────────────────────────
echo ""
echo "==> Building (syntax-checking) every main.*.bicep group file"
for gf in "${GROUP_FILES[@]}"; do
  fname=$(basename "$gf")
  if az bicep build --file "$gf" &>/dev/null; then
    pass "$fname"
  else
    fail "$fname"
  fi
done

# ── Step 3: What-if for each group's parameter file in the target environment ─
if [[ -n "$ENVIRONMENT" ]]; then
  if [[ -z "$LOCATION" ]]; then
    echo "ERROR: --location is required when --environment is supplied (subscription-scope what-if)."
    exit 1
  fi

  PARAMS_DIR="$BICEP_ROOT/parameters/$ENVIRONMENT"
  echo ""
  echo "==> Running subscription-scope what-if for each group in '$ENVIRONMENT'"

  PARAM_FILES=()
  while IFS= read -r -d '' f; do
    PARAM_FILES+=("$f")
  done < <(find "$PARAMS_DIR" -name "*.bicepparam" -print0 2>/dev/null || true)

  for gf in "${GROUP_FILES[@]}"; do
    group_name=$(basename "$gf" .bicep)
    group_name="${group_name#main.}"
    [[ -s "$PARAMS_DIR/$group_name.bicepparam" ]] || fail "$group_name — missing or empty parameter file in $PARAMS_DIR"
  done

  if [[ "${#PARAM_FILES[@]}" -eq 0 ]]; then
    fail "No .bicepparam files found under $PARAMS_DIR"
  else
    for pf in "${PARAM_FILES[@]}"; do
      group_name=$(basename "$pf" .bicepparam)
      group_bicep="$BICEP_ROOT/main.$group_name.bicep"

      if [[ ! -f "$group_bicep" ]]; then
        fail "$group_name — no matching main.$group_name.bicep found for parameters/$ENVIRONMENT/$(basename "$pf")"
        continue
      fi

      echo -n "  what-if: $group_name ... "
      if ! WHATIF_OUT=$(az deployment sub what-if \
          --location "$LOCATION" \
          --template-file "$group_bicep" \
          --parameters "$pf" \
          --output json \
          "${SUB_ARGS[@]}"); then
        fail "what-if failed for $group_name"
        continue
      fi

      if echo "$WHATIF_OUT" | jq -e '
        (.properties.changes | type == "array") and
        all(.properties.changes[]; (.changeType | type == "string") and (.resourceId | type == "string"))
      ' >/dev/null; then
        BLOCKING=$(echo "$WHATIF_OUT" | jq -r \
          '[.properties.changes[]? | select(.changeType=="Delete") | select(.resourceId | test("storageAccounts|vaults|servers|namespaces|databaseAccounts"))] | length')
        if [[ "$BLOCKING" -gt 0 ]]; then
          fail "$group_name — BLOCKING DELETE on data resource(s)"
          echo "$WHATIF_OUT" | jq -r \
            '.properties.changes[]? | select(.changeType=="Delete") | select(.resourceId | test("storageAccounts|vaults|servers|namespaces|databaseAccounts")) | "    DELETE: \(.resourceId)"'
        else
          pass "$group_name — no blocking changes"
        fi
      else
        fail "$group_name — invalid what-if JSON or missing changes array"
      fi
    done
  fi
else
  echo ""
  echo "  --environment not supplied — skipping what-if dry runs"
fi

# ── Result ─────────────────────────────────────────────────────────────────────
echo ""
if [[ "$ERRORS" -gt 0 ]]; then
  echo "RESULT: $ERRORS check(s) FAILED"
  exit 1
fi
echo "RESULT: All Bicep validation checks PASSED"

