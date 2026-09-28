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
