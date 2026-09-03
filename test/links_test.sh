#!/usr/bin/env bash
#
# Tests for script/lib/links.sh.
#
# Each test runs against a throwaway DOTFILES_ROOT and HOME so nothing touches
# the real machine. Run with: test/links_test.sh

set -o pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"

TESTS_RUN=0
ASSERTS_FAILED=0
CURRENT_TEST=""
FAILED_TESTS=()

# mktemp -d returns a path under /var, which is itself a symlink to
# /private/var on macOS. Resolve it so expected link targets match what the
# engine computes with pwd -P.
setup_fixture () {
  FIXTURE_ROOT="$(cd "$(mktemp -d)" && pwd -P)"
  FIXTURE_DOTFILES="$FIXTURE_ROOT/dotfiles"
  FIXTURE_HOME="$FIXTURE_ROOT/home"
  mkdir -p "$FIXTURE_DOTFILES" "$FIXTURE_HOME"
}

teardown_fixture () {
  if [ -n "$FIXTURE_ROOT" ] && [ -d "$FIXTURE_ROOT" ]; then
    rm -rf "$FIXTURE_ROOT"
  fi
}

# Run the engine against the fixture, non-interactively.
run_links () {
  env -i \
    HOME="$FIXTURE_HOME" \
    DOTFILES_ROOT="$FIXTURE_DOTFILES" \
    LINK_CONFLICT_POLICY="${LINK_CONFLICT_POLICY:-skip}" \
    PATH="$PATH" \
    bash -c '
      source "$1/script/lib/output.sh"
      source "$1/script/lib/links.sh"
      install_dotfiles
    ' _ "$REPO_ROOT"
}

report_failure () {
  ASSERTS_FAILED=$((ASSERTS_FAILED + 1))
  printf '    FAIL %s: %s\n' "$CURRENT_TEST" "$1"
}

assert_symlink () {
  local path=$1 want=$2 got
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ ! -L "$path" ]; then
    report_failure "$path is not a symlink"
    return
  fi
  got="$(readlink "$path")"
  if [ "$got" != "$want" ]; then
    report_failure "$path -> $got, want $want"
  fi
}

assert_real_dir () {
  local path=$1
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ -L "$path" ]; then
    report_failure "$path is a symlink, want a real directory"
  elif [ ! -d "$path" ]; then
    report_failure "$path is not a directory"
  fi
}

assert_absent () {
  local path=$1
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ -e "$path" ] || [ -L "$path" ]; then
    report_failure "$path exists, want it absent"
  fi
}

assert_file_contains () {
  local path=$1 want=$2
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ ! -f "$path" ]; then
    report_failure "$path is not a regular file"
  elif [ "$(cat "$path")" != "$want" ]; then
    report_failure "$path contents = $(cat "$path"), want $want"
  fi
}

### Rule 1: *.symlink files ############################################

test_rule1_links_file_to_home_dotfile () {
  mkdir -p "$FIXTURE_DOTFILES/git"
  echo "config" > "$FIXTURE_DOTFILES/git/gitconfig.symlink"

  run_links > /dev/null

  assert_symlink "$FIXTURE_HOME/.gitconfig" \
    "$FIXTURE_DOTFILES/git/gitconfig.symlink"
}

test_rule1_is_idempotent () {
  mkdir -p "$FIXTURE_DOTFILES/git"
  echo "config" > "$FIXTURE_DOTFILES/git/gitconfig.symlink"

  run_links > /dev/null
  run_links > /dev/null

  assert_symlink "$FIXTURE_HOME/.gitconfig" \
    "$FIXTURE_DOTFILES/git/gitconfig.symlink"
}

test_rule1_handles_path_with_a_space () {
  mkdir -p "$FIXTURE_DOTFILES/my topic"
  echo "x" > "$FIXTURE_DOTFILES/my topic/spaced.symlink"

  run_links > /dev/null

  assert_symlink "$FIXTURE_HOME/.spaced" \
    "$FIXTURE_DOTFILES/my topic/spaced.symlink"
}

test_rule1_ignores_depth_three_entries () {
  mkdir -p "$FIXTURE_DOTFILES/topic/nested"
  echo "x" > "$FIXTURE_DOTFILES/topic/nested/toodeep.symlink"

  run_links > /dev/null

  assert_absent "$FIXTURE_HOME/.toodeep"
}

test_fail_exits_nonzero () {
  TESTS_RUN=$((TESTS_RUN + 1))
  if bash -c "source '$REPO_ROOT/script/lib/output.sh'; fail 'boom'" \
      > /dev/null 2>&1; then
    report_failure "fail() exited 0, want nonzero"
  fi
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
