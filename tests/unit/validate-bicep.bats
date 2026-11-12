#!/usr/bin/env bats
# Unit tests for validate-bicep.sh

SCRIPT="$BATS_TEST_DIRNAME/../../skills/module-organization/scripts/validate-bicep.sh"

@test "validate-bicep.sh exists" {
  [ -f "$SCRIPT" ]
}

@test "validate-bicep.sh is executable" {
  [ -x "$SCRIPT" ]
}

@test "validate-bicep.sh fails when no group files are found" {
  run bash "$SCRIPT" --bicep-root /nonexistent/path
  [ "$status" -ne 0 ]
  [[ "$output" == *"group files found under"* ]]
}

@test "validate-bicep.sh rejects unknown flags" {
  run bash "$SCRIPT" --weird-flag
  [ "$status" -ne 0 ]
}

@test "validate-bicep.sh calls az bicep restore in source" {
  grep -q "bicep restore" "$SCRIPT"
}

@test "validate-bicep.sh calls az bicep build in source" {
  grep -q "bicep build" "$SCRIPT"
}

@test "validate-bicep.sh skips what-if when no environment is given" {
  grep -q "environment.*not supplied.*skipping what-if" "$SCRIPT"
}

setup_validation() {
  ROOT="$BATS_TEST_TMPDIR/bicep"
  mkdir -p "$ROOT/parameters/dev" "$BATS_TEST_TMPDIR/bin"
  echo "targetScope = 'subscription'" > "$ROOT/main.compute.bicep"
  echo "using '../../main.compute.bicep'" > "$ROOT/parameters/dev/compute.bicepparam"
  cat > "$BATS_TEST_TMPDIR/bin/az" <<'MOCK'
#!/usr/bin/env bash
if [[ "$1" == "deployment" ]]; then
  printf '%s\n' "$WHATIF_JSON"
  exit "${WHATIF_EXIT:-0}"
fi
exit 0
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/az"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  export WHATIF_JSON='{"properties":{"changes":[]}}'
  export WHATIF_EXIT=0
}

@test "both Bicep validators pass valid what-if and fail closed on bad responses" {
  setup_validation
  for skill in module-organization parameter-management; do
    validator="$BATS_TEST_DIRNAME/../../skills/$skill/scripts/validate-bicep.sh"
    for response in '{"properties":{"changes":[]}}' 'not-json' '{}' '{"properties":{"changes":[{}]}}' '{"properties":{"changes":[{"changeType":"Delete","resourceId":"/storageAccounts/test"}]}}'; do
      export WHATIF_JSON="$response"
      run bash "$validator" --bicep-root "$ROOT" --environment dev --location eastus
      if [[ "$response" == '{"properties":{"changes":[]}}' ]]; then
        [ "$status" -eq 0 ]
      else
        [ "$status" -ne 0 ]
        [[ "$output" != *"All Bicep validation checks PASSED"* ]]
      fi
    done
    export WHATIF_JSON='{"properties":{"changes":[]}}'
    export WHATIF_EXIT=1
    run bash "$validator" --bicep-root "$ROOT" --environment dev --location eastus
    [ "$status" -ne 0 ]
    export WHATIF_EXIT=0
  done
}

@test "both Bicep validators reject missing group parameters" {
  setup_validation
  echo "targetScope = 'subscription'" > "$ROOT/main.data.bicep"
  for skill in module-organization parameter-management; do
    run bash "$BATS_TEST_DIRNAME/../../skills/$skill/scripts/validate-bicep.sh" --bicep-root "$ROOT" --environment dev --location eastus
    [ "$status" -ne 0 ]
    [[ "$output" == *"missing or empty parameter"* ]]
  done
}
