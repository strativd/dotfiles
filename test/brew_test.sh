#!/usr/bin/env bash
#
# Tests for homebrew/packages.sh.
#
# A fake `brew` on PATH records invocations. Run with: test/brew_test.sh

set -o pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"

TESTS_RUN=0
ASSERTS_FAILED=0
CURRENT_TEST=""
FAILED_TESTS=()

setup_fixture () {
  FIXTURE_ROOT="$(cd "$(mktemp -d)" && pwd -P)"
  FIXTURE_BIN="$FIXTURE_ROOT/bin"
  BREW_LOG="$FIXTURE_ROOT/brew.log"
  BREW_LISTED="$FIXTURE_ROOT/listed"
  mkdir -p "$FIXTURE_BIN"
  : > "$BREW_LOG"
  : > "$BREW_LISTED"

  cat > "$FIXTURE_BIN/brew" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$BREW_LOG"
case "$1" in
  list)
    if [ "$2" = "--cask" ]; then
      name="$3"
    else
      name="$2"
    fi
    if [ -n "$name" ] && grep -Fxq "$name" "$BREW_LISTED" 2>/dev/null; then
      exit 0
    fi
    exit 1
    ;;
  *)
    exit 0
    ;;
esac
EOF
  chmod +x "$FIXTURE_BIN/brew"
}

teardown_fixture () {
  if [ -n "$FIXTURE_ROOT" ] && [ -d "$FIXTURE_ROOT" ]; then
    rm -rf "$FIXTURE_ROOT"
  fi
}

run_install_cask () {
  env -i \
    PATH="$FIXTURE_BIN:/usr/bin:/bin" \
    BREW_LOG="$BREW_LOG" \
    BREW_LISTED="$BREW_LISTED" \
    HOME="$FIXTURE_ROOT/home" \
    bash -c '
      source "$1/homebrew/packages.sh"
      shift
      install_cask "$@"
    ' _ "$REPO_ROOT" "$@"
}

report_failure () {
  ASSERTS_FAILED=$((ASSERTS_FAILED + 1))
  printf '    FAIL %s: %s\n' "$CURRENT_TEST" "$1"
}

assert_log_contains () {
  local want=$1
  TESTS_RUN=$((TESTS_RUN + 1))
  if ! grep -Fxq "$want" "$BREW_LOG"; then
    report_failure "brew log missing '$want'; got: $(tr '\n' '|' < "$BREW_LOG")"
  fi
}

assert_log_lacks () {
  local want=$1
  TESTS_RUN=$((TESTS_RUN + 1))
  if grep -Fq "$want" "$BREW_LOG"; then
    report_failure "brew log has '$want'; got: $(tr '\n' '|' < "$BREW_LOG")"
  fi
}

test_unlisted_cask_installs_with_force () {
  run_install_cask cursor > /dev/null

  assert_log_contains "list --cask cursor"
  assert_log_contains "install --cask --force cursor"
}

test_listed_cask_is_not_reinstalled () {
  echo cursor > "$BREW_LISTED"

  run_install_cask cursor > /dev/null

  assert_log_contains "list --cask cursor"
  assert_log_lacks "install --cask"
}

test_mixed_casks_force_only_the_missing_ones () {
  echo slack > "$BREW_LISTED"

  run_install_cask slack cursor > /dev/null

  assert_log_lacks "install --cask --force slack"
  assert_log_contains "install --cask --force cursor"
}

### Runner ############################################################

main () {
  local test_name
  for test_name in $(declare -F | awk '{print $3}' | grep '^test_' | sort); do
    CURRENT_TEST="$test_name"
    local before=$ASSERTS_FAILED
    setup_fixture
    "$test_name"
    teardown_fixture
    if [ "$ASSERTS_FAILED" -gt "$before" ]; then
      FAILED_TESTS+=("$test_name")
    else
      printf '    ok   %s\n' "$test_name"
    fi
  done

  printf '\n%s assertions, %s failed\n' "$TESTS_RUN" "$ASSERTS_FAILED"
  if [ "${#FAILED_TESTS[@]}" -gt 0 ]; then
    printf 'failing tests: %s\n' "${FAILED_TESTS[*]}"
    exit 1
  fi
  echo 'PASS'
}

main "$@"
