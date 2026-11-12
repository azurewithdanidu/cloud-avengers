#!/usr/bin/env bats

SCRIPT="$BATS_TEST_DIRNAME/../../skills/aws-inventory-scan/scripts/validate-inventory.sh"

setup() {
  INVENTORY="$BATS_TEST_TMPDIR/inventory.json"
  cat > "$INVENTORY" <<'JSON'
{"discovery_timestamp":"2026-11-13T00:00:00Z","aws_account_id":"123456789012","aws_region":"us-east-1","services":{"lambda":{"service_type":"AWS::Lambda::Function","count":1,"resources":[{"name":"handler","arn":"arn:aws:lambda:us-east-1:123456789012:function:handler","region":"us-east-1"}]}}}
JSON
}

@test "inventory validator accepts complete typed inventory" {
  run bash "$SCRIPT" "$INVENTORY"
  [ "$status" -eq 0 ]
}

@test "inventory validator rejects incorrect counts and malformed resources" {
  for mutation in \
    '.services.lambda.count = 2' \
    '.services.lambda.count = 1.5' \
    '.services.lambda.count = "1"' \
    '.services.lambda.resources = [42]' \
    '.services.lambda.resources[0].name = false' \
    '.services.lambda.resources[0].region = " "' \
    '.aws_account_id = 123456789012' \
    '.services = []'; do
    jq "$mutation" "$INVENTORY" > "$BATS_TEST_TMPDIR/invalid.json"
    run bash "$SCRIPT" "$BATS_TEST_TMPDIR/invalid.json"
    [ "$status" -ne 0 ]
  done
}

@test "documented inventory example passes the executable contract" {
  awk '/^```json$/ {capture=1; next} capture && /^```$/ {exit} capture {print}' \
    "$BATS_TEST_DIRNAME/../../skills/aws-inventory-scan/references/output-schemas.md" > "$INVENTORY"
  run bash "$SCRIPT" "$INVENTORY"
  [ "$status" -eq 0 ]
}
