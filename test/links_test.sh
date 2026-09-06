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

### Rule 2: *.symlink directories #####################################

test_rule2_links_leaves_into_real_dirs () {
  mkdir -p "$FIXTURE_DOTFILES/opencode/config.symlink/opencode"
  echo "{}" > "$FIXTURE_DOTFILES/opencode/config.symlink/opencode/opencode.json"

  run_links > /dev/null

  assert_real_dir "$FIXTURE_HOME/.config"
  assert_real_dir "$FIXTURE_HOME/.config/opencode"
  assert_symlink "$FIXTURE_HOME/.config/opencode/opencode.json" \
    "$FIXTURE_DOTFILES/opencode/config.symlink/opencode/opencode.json"
}

test_rule2_merges_two_topics_into_one_target () {
  mkdir -p "$FIXTURE_DOTFILES/opencode/config.symlink/opencode"
  mkdir -p "$FIXTURE_DOTFILES/pi/config.symlink/mcp"
  echo "{}" > "$FIXTURE_DOTFILES/opencode/config.symlink/opencode/a.json"
  echo "{}" > "$FIXTURE_DOTFILES/pi/config.symlink/mcp/b.json"

  run_links > /dev/null

  assert_real_dir "$FIXTURE_HOME/.config"
  assert_symlink "$FIXTURE_HOME/.config/opencode/a.json" \
    "$FIXTURE_DOTFILES/opencode/config.symlink/opencode/a.json"
  assert_symlink "$FIXTURE_HOME/.config/mcp/b.json" \
    "$FIXTURE_DOTFILES/pi/config.symlink/mcp/b.json"
}

test_rule2_preserves_foreign_content_in_target () {
  mkdir -p "$FIXTURE_DOTFILES/cursor/cursor.symlink"
  echo "{}" > "$FIXTURE_DOTFILES/cursor/cursor.symlink/hooks.json"
  mkdir -p "$FIXTURE_HOME/.cursor/plugins"
  echo "cache" > "$FIXTURE_HOME/.cursor/plugins/keep.txt"

  run_links > /dev/null

  assert_real_dir "$FIXTURE_HOME/.cursor"
  assert_real_dir "$FIXTURE_HOME/.cursor/plugins"
  assert_file_contains "$FIXTURE_HOME/.cursor/plugins/keep.txt" "cache"
  assert_symlink "$FIXTURE_HOME/.cursor/hooks.json" \
    "$FIXTURE_DOTFILES/cursor/cursor.symlink/hooks.json"
}

test_rule2_links_dot_prefixed_files_but_not_ignore_list () {
  mkdir -p "$FIXTURE_DOTFILES/agents/agents.symlink"
  echo "{}" > "$FIXTURE_DOTFILES/agents/agents.symlink/.skill-lock.json"
  echo "junk" > "$FIXTURE_DOTFILES/agents/agents.symlink/.DS_Store"

  run_links > /dev/null

  assert_symlink "$FIXTURE_HOME/.agents/.skill-lock.json" \
    "$FIXTURE_DOTFILES/agents/agents.symlink/.skill-lock.json"
  assert_absent "$FIXTURE_HOME/.agents/.DS_Store"
}

test_rule2_walks_empty_dir_without_error () {
  mkdir -p "$FIXTURE_DOTFILES/topic/empty.symlink"

  run_links > /dev/null

  assert_real_dir "$FIXTURE_HOME/.empty"
}

### Rule 3: nested *.symlink entries link whole ########################

test_rule3_nested_dir_links_whole () {
  mkdir -p "$FIXTURE_DOTFILES/pi/pi.symlink/agent/themes.symlink"
  echo "{}" > "$FIXTURE_DOTFILES/pi/pi.symlink/agent/themes.symlink/space.json"

  run_links > /dev/null

  assert_real_dir "$FIXTURE_HOME/.pi/agent"
  assert_symlink "$FIXTURE_HOME/.pi/agent/themes" \
    "$FIXTURE_DOTFILES/pi/pi.symlink/agent/themes.symlink"
  assert_absent "$FIXTURE_HOME/.pi/agent/themes.symlink"
}

test_rule3_nested_file_strips_suffix_without_adding_dot () {
  mkdir -p "$FIXTURE_DOTFILES/topic/root.symlink"
  echo "x" > "$FIXTURE_DOTFILES/topic/root.symlink/inner.symlink"

  run_links > /dev/null

  assert_symlink "$FIXTURE_HOME/.root/inner" \
    "$FIXTURE_DOTFILES/topic/root.symlink/inner.symlink"
}

test_rule3_resolves_repo_symlink_to_physical_path () {
  mkdir -p "$FIXTURE_DOTFILES/agents/agents.symlink/prompts"
  echo "p" > "$FIXTURE_DOTFILES/agents/agents.symlink/prompts/general.md"
  mkdir -p "$FIXTURE_DOTFILES/cursor/cursor.symlink"
  ln -s "../../agents/agents.symlink/prompts" \
    "$FIXTURE_DOTFILES/cursor/cursor.symlink/prompts.symlink"

  run_links > /dev/null

  # One hop, not two: the $HOME link points at the real directory.
  assert_symlink "$FIXTURE_HOME/.cursor/prompts" \
    "$FIXTURE_DOTFILES/agents/agents.symlink/prompts"
}

test_rule3_does_not_follow_bare_symlink_to_directory () {
  mkdir -p "$FIXTURE_DOTFILES/topic/root.symlink"
  mkdir -p "$FIXTURE_DOTFILES/shared/stuff"
  echo "x" > "$FIXTURE_DOTFILES/shared/stuff/a.txt"
  ln -s "../../shared/stuff" "$FIXTURE_DOTFILES/topic/root.symlink/stuff"

  run_links > /dev/null

  assert_symlink "$FIXTURE_HOME/.root/stuff" "$FIXTURE_DOTFILES/shared/stuff"
}

### .link-children sentinel ###########################################

test_link_children_links_each_child_whole () {
  local skills="$FIXTURE_DOTFILES/agents/agents.symlink/skills"
  mkdir -p "$skills/coding-guidelines" "$skills/refactor-with-a-kiss"
  touch "$skills/.link-children"
  echo "s" > "$skills/coding-guidelines/SKILL.md"
  echo "s" > "$skills/refactor-with-a-kiss/SKILL.md"

  run_links > /dev/null

  assert_real_dir "$FIXTURE_HOME/.agents/skills"
  assert_symlink "$FIXTURE_HOME/.agents/skills/coding-guidelines" \
    "$skills/coding-guidelines"
  assert_symlink "$FIXTURE_HOME/.agents/skills/refactor-with-a-kiss" \
    "$skills/refactor-with-a-kiss"
  assert_absent "$FIXTURE_HOME/.agents/skills/.link-children"
}

test_link_children_does_not_recurse_into_children () {
  local skills="$FIXTURE_DOTFILES/agents/agents.symlink/skills"
  mkdir -p "$skills/tdd/references"
  touch "$skills/.link-children"
  echo "s" > "$skills/tdd/references/tests.md"

  run_links > /dev/null

  assert_symlink "$FIXTURE_HOME/.agents/skills/tdd" "$skills/tdd"
}

test_link_children_preserves_externally_installed_siblings () {
  local skills="$FIXTURE_DOTFILES/agents/agents.symlink/skills"
  mkdir -p "$skills/mine"
  touch "$skills/.link-children"
  echo "s" > "$skills/mine/SKILL.md"
  mkdir -p "$FIXTURE_HOME/.agents/skills/installed-externally"
  echo "e" > "$FIXTURE_HOME/.agents/skills/installed-externally/SKILL.md"

  run_links > /dev/null

  assert_real_dir "$FIXTURE_HOME/.agents/skills/installed-externally"
  assert_file_contains \
    "$FIXTURE_HOME/.agents/skills/installed-externally/SKILL.md" "e"
  assert_symlink "$FIXTURE_HOME/.agents/skills/mine" "$skills/mine"
}

### Rule 4: *.link declaration files ##################################

test_rule4_expands_home_variable () {
  mkdir -p "$FIXTURE_DOTFILES/cursor/cursor.symlink"
  echo '$HOME/.agents/skills' \
    > "$FIXTURE_DOTFILES/cursor/cursor.symlink/skills.link"
  mkdir -p "$FIXTURE_HOME/.agents/skills"

  run_links > /dev/null

  assert_symlink "$FIXTURE_HOME/.cursor/skills" \
    "$FIXTURE_HOME/.agents/skills"
  assert_absent "$FIXTURE_HOME/.cursor/skills.link"
}

test_rule4_expands_dotfiles_variable () {
  mkdir -p "$FIXTURE_DOTFILES/pi/config.symlink/mcp"
  mkdir -p "$FIXTURE_DOTFILES/pi/pi.symlink/agent"
  echo "{}" > "$FIXTURE_DOTFILES/pi/pi.symlink/agent/mcp.local.json"
  echo '$DOTFILES/pi/pi.symlink/agent/mcp.local.json' \
    > "$FIXTURE_DOTFILES/pi/config.symlink/mcp/mcp.json.link"

  run_links > /dev/null

  assert_symlink "$FIXTURE_HOME/.config/mcp/mcp.json" \
    "$FIXTURE_DOTFILES/pi/pi.symlink/agent/mcp.local.json"
}

test_rule4_accepts_absolute_path () {
  mkdir -p "$FIXTURE_DOTFILES/topic/root.symlink"
  echo "$FIXTURE_ROOT/elsewhere" \
    > "$FIXTURE_DOTFILES/topic/root.symlink/thing.link"
  mkdir -p "$FIXTURE_ROOT/elsewhere"

  run_links > /dev/null

  assert_symlink "$FIXTURE_HOME/.root/thing" "$FIXTURE_ROOT/elsewhere"
}

test_rule4_rejects_relative_path () {
  mkdir -p "$FIXTURE_DOTFILES/topic/root.symlink"
  echo '../sneaky' > "$FIXTURE_DOTFILES/topic/root.symlink/thing.link"

  TESTS_RUN=$((TESTS_RUN + 1))
  if run_links > /dev/null 2>&1; then
    report_failure "relative *.link target was accepted, want failure"
  fi
  assert_absent "$FIXTURE_HOME/.root/thing"
}

test_rule4_creates_dangling_link_for_missing_referent () {
  mkdir -p "$FIXTURE_DOTFILES/cursor/cursor.symlink"
  echo '$HOME/.agents/skills' \
    > "$FIXTURE_DOTFILES/cursor/cursor.symlink/skills.link"

  run_links > /dev/null

  # Referent does not exist; the link is still created and Task 6 prunes it.
  assert_symlink "$FIXTURE_HOME/.cursor/skills" \
    "$FIXTURE_HOME/.agents/skills"
}

### .local overlay ####################################################

test_local_overlay_link_children_links_each_child_whole () {
  local skills="$FIXTURE_DOTFILES/agents/agents.symlink/skills"
  mkdir -p "$skills/tracked" "$skills/.local/unsafe"
  touch "$skills/.link-children"
  echo "t" > "$skills/tracked/SKILL.md"
  echo "u" > "$skills/.local/unsafe/SKILL.md"

  run_links > /dev/null

  assert_real_dir "$FIXTURE_HOME/.agents/skills"
  assert_symlink "$FIXTURE_HOME/.agents/skills/tracked" "$skills/tracked"
  assert_symlink "$FIXTURE_HOME/.agents/skills/unsafe" \
    "$skills/.local/unsafe"
  assert_absent "$FIXTURE_HOME/.agents/skills/.local"
}

test_local_overlay_does_not_recurse_into_overlay_children () {
  local skills="$FIXTURE_DOTFILES/agents/agents.symlink/skills"
  mkdir -p "$skills/.local/unsafe/references"
  touch "$skills/.link-children"
  echo "s" > "$skills/.local/unsafe/references/notes.md"

  run_links > /dev/null

  assert_symlink "$FIXTURE_HOME/.agents/skills/unsafe" \
    "$skills/.local/unsafe"
}

test_local_overlay_rule2_leaf_links_into_same_destination () {
  mkdir -p "$FIXTURE_DOTFILES/cursor/cursor.symlink/.local"
  echo "{}" > "$FIXTURE_DOTFILES/cursor/cursor.symlink/hooks.json"
  echo "secret" > "$FIXTURE_DOTFILES/cursor/cursor.symlink/.local/mcp.json"

  run_links > /dev/null

  assert_real_dir "$FIXTURE_HOME/.cursor"
  assert_symlink "$FIXTURE_HOME/.cursor/hooks.json" \
    "$FIXTURE_DOTFILES/cursor/cursor.symlink/hooks.json"
  assert_symlink "$FIXTURE_HOME/.cursor/mcp.json" \
    "$FIXTURE_DOTFILES/cursor/cursor.symlink/.local/mcp.json"
  assert_absent "$FIXTURE_HOME/.cursor/.local"
}

test_local_overlay_absent_is_noop () {
  local skills="$FIXTURE_DOTFILES/agents/agents.symlink/skills"
  mkdir -p "$skills/mine"
  touch "$skills/.link-children"
  echo "s" > "$skills/mine/SKILL.md"

  run_links > /dev/null

  assert_symlink "$FIXTURE_HOME/.agents/skills/mine" "$skills/mine"
  assert_absent "$FIXTURE_HOME/.agents/skills/.local"
}

test_local_overlay_skip_keeps_tracked_sibling_on_name_clash () {
  local skills="$FIXTURE_DOTFILES/agents/agents.symlink/skills"
  mkdir -p "$skills/mine" "$skills/.local/mine"
  touch "$skills/.link-children"
  echo "tracked" > "$skills/mine/SKILL.md"
  echo "local" > "$skills/.local/mine/SKILL.md"

  run_links > /dev/null

  assert_symlink "$FIXTURE_HOME/.agents/skills/mine" "$skills/mine"
}

test_local_overlay_link_declaration_inside_overlay () {
  local skills="$FIXTURE_DOTFILES/agents/agents.symlink/skills"
  mkdir -p "$skills/.local" "$FIXTURE_HOME/.gaia/src/agents/skills/from-gaia"
  touch "$skills/.link-children"
  echo "g" > "$FIXTURE_HOME/.gaia/src/agents/skills/from-gaia/SKILL.md"
  printf '%s\n' '$HOME/.gaia/src/agents/skills/from-gaia' \
    > "$skills/.local/from-gaia.link"

  run_links > /dev/null

  assert_symlink "$FIXTURE_HOME/.agents/skills/from-gaia" \
    "$FIXTURE_HOME/.gaia/src/agents/skills/from-gaia"
  assert_absent "$FIXTURE_HOME/.agents/skills/from-gaia.link"
}

test_dangling_owned_link_is_replaced_in_one_pass () {
  local skills="$FIXTURE_DOTFILES/agents/agents.symlink/skills"
  mkdir -p "$skills/.local/moved"
  touch "$skills/.link-children"
  echo "s" > "$skills/.local/moved/SKILL.md"
  mkdir -p "$FIXTURE_HOME/.agents/skills"
  ln -s "$skills/moved" "$FIXTURE_HOME/.agents/skills/moved"

  run_links > /dev/null

  assert_symlink "$FIXTURE_HOME/.agents/skills/moved" \
    "$skills/.local/moved"
}

### Pruning and drift #################################################

test_prune_removes_dangling_owned_link () {
  local skills="$FIXTURE_DOTFILES/agents/agents.symlink/skills"
  mkdir -p "$skills/mine"
  touch "$skills/.link-children"
  echo "s" > "$skills/mine/SKILL.md"
  mkdir -p "$FIXTURE_HOME/.agents/skills"
  ln -s "$skills/deleted-skill" "$FIXTURE_HOME/.agents/skills/deleted-skill"

  run_links > /dev/null

  assert_absent "$FIXTURE_HOME/.agents/skills/deleted-skill"
  assert_symlink "$FIXTURE_HOME/.agents/skills/mine" "$skills/mine"
}

test_prune_keeps_dangling_foreign_link () {
  mkdir -p "$FIXTURE_DOTFILES/agents/agents.symlink/skills"
  touch "$FIXTURE_DOTFILES/agents/agents.symlink/skills/.link-children"
  mkdir -p "$FIXTURE_HOME/.agents/skills"
  ln -s "/nonexistent/elsewhere" "$FIXTURE_HOME/.agents/skills/foreign"

  run_links > /dev/null

  TESTS_RUN=$((TESTS_RUN + 1))
  if [ ! -L "$FIXTURE_HOME/.agents/skills/foreign" ]; then
    report_failure "foreign dangling link was pruned, want it kept"
  fi
}

test_prune_keeps_live_owned_link () {
  local skills="$FIXTURE_DOTFILES/agents/agents.symlink/skills"
  mkdir -p "$skills/mine"
  touch "$skills/.link-children"
  echo "s" > "$skills/mine/SKILL.md"

  run_links > /dev/null
  run_links > /dev/null

  assert_symlink "$FIXTURE_HOME/.agents/skills/mine" "$skills/mine"
}

test_drift_is_reported_when_managed_path_is_a_regular_file () {
  mkdir -p "$FIXTURE_DOTFILES/cursor/cursor.symlink"
  echo "{}" > "$FIXTURE_DOTFILES/cursor/cursor.symlink/hooks.json"
  mkdir -p "$FIXTURE_HOME/.cursor"
  echo "written by the app" > "$FIXTURE_HOME/.cursor/hooks.json"

  local output
  output="$(run_links 2>&1)"

  TESTS_RUN=$((TESTS_RUN + 1))
  case "$output" in
    *"no longer a symlink"*) ;;
    *) report_failure "drift was not reported; output: $output" ;;
  esac
  # Default test policy is skip, so the app's file is left alone.
  assert_file_contains "$FIXTURE_HOME/.cursor/hooks.json" "written by the app"
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
