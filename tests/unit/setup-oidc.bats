#!/usr/bin/env bats

SCRIPT="$BATS_TEST_DIRNAME/../../skills/github-actions-oidc/scripts/setup-oidc.sh"

@test "OIDC cannot run unattended even with piped approval" {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  printf '#!/usr/bin/env bash\ntouch "$AZ_CALLED"\n' > "$BATS_TEST_TMPDIR/bin/az"
  chmod +x "$BATS_TEST_TMPDIR/bin/az"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  export AZ_CALLED="$BATS_TEST_TMPDIR/az-called"
  run bash -c 'printf "APPROVE\n" | bash "$1" org repo dev subscription resource-group' _ "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"human confirmation"* ]]
  [ ! -e "$AZ_CALLED" ]
}
