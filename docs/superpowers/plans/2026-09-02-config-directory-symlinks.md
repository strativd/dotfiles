# Config-Directory Symlinks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace six ad-hoc linking mechanisms with one tested symlink engine
that extends the `*.symlink` convention to directories, recursing by default so
co-owned directories like `~/.cursor` stay real.

**Architecture:** Extract the linking logic out of `script/bootstrap` into
`script/lib/links.sh`, driven entirely by `DOTFILES_ROOT` and `HOME` from the
environment so it can be exercised against throwaway fixture directories. Build
it rule by rule under test, then migrate each topic to the new layout and delete
the bespoke functions and unwired scripts it replaces.

**Tech Stack:** Bash 3.2, `find`, `ln`, GNU-free coreutils only. No new
dependencies — `script/bootstrap` runs before Homebrew on a fresh machine.

Spec: `docs/superpowers/specs/2026-09-02-config-directory-symlinks-design.md`

## Global Constraints

- Target **bash 3.2.57**, the macOS system bash. No associative arrays, no
  `readarray`/`mapfile`, no `${var^^}`, no `declare -n`.
- No new runtime dependencies. `readlink -f` is unavailable on older macOS and
  must not be used.
- Preserve the existing `*.symlink` file convention: 11 tracked files plus the
  generated `git/gitconfig.local.symlink`.
- Only the link root gains a leading dot; nested paths map verbatim.
- Intermediate directories in a walked tree are **real directories**, never
  symlinks.
- Ignore list is exactly `.DS_Store`, `.git`, `.link-children`. All other
  dot-prefixed entries are linked normally — `.skill-lock.json` depends on this.
- `*.link` contents must be a single line that is absolute or begins with
  `$HOME` or `$DOTFILES`. Relative paths are rejected.
- Ownership for pruning means `readlink` resolves to a path under
  `$DOTFILES_ROOT`.
- Every file: UTF-8, LF, 2-space indent, trailing whitespace trimmed, final
  newline (`.editorconfig`).
- Markdown wraps at 80 columns (`rumdl` MD013 with `reflow = true`).

---

## File Structure

| File | | Responsibility |
| --- | --- | --- |
| `script/lib/output.sh` | new | Status printers, shared by all three |
| `script/lib/links.sh` | new | The engine: rules, sentinel, prune, drift |
| `script/bootstrap` | edit | Orchestration: gitconfig, source libs, brew |
| `test/links_test.sh` | new | Fixture-based tests; the repo's first |

The engine is a separate sourceable file rather than inline bash precisely so
the tests can drive it against a fake `DOTFILES_ROOT` and a fake `HOME`.

---

## Task 1: Test harness, output lib, and Rule 1

Establishes the test harness and moves existing single-file linking into the new
engine with no behavior change, so every later rule lands on tested ground.

**Files:**

- Create: `script/lib/output.sh`
- Create: `script/lib/links.sh`
- Create: `test/links_test.sh`
- Modify: `script/bootstrap` (delete inline `info`/`user`/`success`/`fail` at
  lines 12-28, delete `link_file` at lines 53-126, delete `install_dotfiles` at
  lines 128-138, source the libs instead)

**Interfaces:**

- Consumes: nothing.
- Produces:
  - `info MSG`, `user MSG`, `success MSG`, `fail MSG` — `fail` exits 1.
  - `link_file SRC DST` — creates `DST` as a symlink to `SRC`, creating
    `dirname DST`. Honors `LINK_CONFLICT_POLICY` (`prompt` default, plus
    `skip`, `overwrite`, `backup`).
  - `link_physical SRC` — echoes the physical path of `SRC`, following repo
    symlinks so `$HOME` links never form two-hop chains.
  - `link_ignored NAME` — returns 0 if `NAME` is in the ignore list.
  - `install_dotfiles` — discovers `*.symlink` roots at depth 1-2 and links
    them.
  - `LINK_CONFLICT_POLICY` env var, read by `link_file`.

- [ ] **Step 1: Write the failing test**

Create `test/links_test.sh`:

```bash
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
```

Then `chmod +x test/links_test.sh`.

- [ ] **Step 2: Run test to verify it fails**

Run: `test/links_test.sh`

Expected: FAIL. Every test reports failure because
`script/lib/output.sh` and `script/lib/links.sh` do not exist, so
`source` errors and no links are created.

- [ ] **Step 3: Write `script/lib/output.sh`**

```bash
#
# Colored status printers, shared by script/bootstrap, script/lib/links.sh,
# and the tests. Sourced, not executed.

info () {
  printf "\r  [ \033[00;34m..\033[0m ] %s\n" "$1"
}

user () {
  printf "\r  [ \033[0;33m??\033[0m ] %s\n" "$1"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] %s\n" "$1"
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] %s\n" "$1"
  echo ''
  exit 1
}
```

Two fixes versus the originals in `script/bootstrap`: the message is passed
through `%s` rather than being interpolated into the format string, so a `%` in
a path can no longer corrupt output; and `fail` exits 1 rather than bare `exit`,
which inherited the status of the preceding `echo` and therefore always exited
**0**.

- [ ] **Step 4: Write `script/lib/links.sh` with Rule 1**

```bash
#
# Symlink engine for dotfiles and config directories. Sourced, not executed.
#
# Requires DOTFILES_ROOT and HOME in the environment, and output.sh sourced
# first. Targets bash 3.2, the macOS system bash.
#
# Conventions, rooted at an entry named NAME.symlink at depth 1-2 of the repo:
#
#   Rule 1  file NAME.symlink       ->  $HOME/.NAME
#
# Only the link root gains a leading dot; nested paths map verbatim.

LINK_IGNORE=(".DS_Store" ".git" ".link-children")
: "${LINK_CONFLICT_POLICY:=prompt}"

overwrite_all=false
backup_all=false
skip_all=false

link_ignored () {
  local name=$1 ignore
  for ignore in "${LINK_IGNORE[@]}"; do
    if [ "$name" = "$ignore" ]; then
      return 0
    fi
  done
  return 1
}

# Echo the physical path of $1, following repo symlinks, so links created in
# $HOME point at real files instead of forming two-hop chains. readlink -f is
# unavailable on older macOS, hence the manual walk.
link_physical () {
  local src=$1 dir base target hops=0

  if [ -d "$src" ]; then
    (cd "$src" && pwd -P)
    return
  fi

  dir="$(cd "$(dirname "$src")" && pwd -P)"
  base="$(basename "$src")"

  while [ -L "$dir/$base" ] && [ "$hops" -lt 32 ]; do
    target="$(readlink "$dir/$base")"
    case "$target" in
      /*) dir="$(cd "$(dirname "$target")" && pwd -P)" ;;
      *)  dir="$(cd "$dir" && cd "$(dirname "$target")" && pwd -P)" ;;
    esac
    base="$(basename "$target")"
    hops=$((hops + 1))
  done

  printf '%s/%s\n' "$dir" "$base"
}

link_file () {
  local src=$1 dst=$2
  local overwrite= backup= skip= action=

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ "$(readlink "$dst")" = "$src" ]; then
      skip=true
    elif [ "$overwrite_all" = false ] && [ "$backup_all" = false ] \
         && [ "$skip_all" = false ]; then
      case "$LINK_CONFLICT_POLICY" in
        skip)      skip=true ;;
        overwrite) overwrite=true ;;
        backup)    backup=true ;;
        *)
          user "File already exists: $dst ($(basename "$src")), what do you want to do?
        [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
          read -r -n 1 action
          case "$action" in
            o) overwrite=true ;;
            O) overwrite_all=true ;;
            b) backup=true ;;
            B) backup_all=true ;;
            s) skip=true ;;
            S) skip_all=true ;;
          esac
          ;;
      esac
    fi

    overwrite=${overwrite:-$overwrite_all}
    backup=${backup:-$backup_all}
    skip=${skip:-$skip_all}

    if [ "$overwrite" = true ]; then
      rm -rf "$dst"
      success "removed $dst"
    fi

    if [ "$backup" = true ]; then
      mv "$dst" "${dst}.backup"
      success "moved $dst to ${dst}.backup"
    fi

    if [ "$skip" = true ]; then
      return 0
    fi
  fi

  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  success "linked $dst to $src"
}

install_dotfiles () {
  info 'installing dotfiles'

  overwrite_all=false
  backup_all=false
  skip_all=false

  local src name dst
  while IFS= read -r -d '' src; do
    name="$(basename "$src")"
    dst="$HOME/.${name%.symlink}"
    link_file "$(link_physical "$src")" "$dst"
  done < <(find -H "$DOTFILES_ROOT" -maxdepth 2 -name '*.symlink' \
    -not -path '*/.git/*' -print0)
}
```

Note the quoting fix in `link_file`: the original compared
`"$(readlink $dst)"` unquoted, which word-split on paths containing spaces.

- [ ] **Step 5: Run test to verify it passes**

Run: `test/links_test.sh`

Expected: PASS, 5 tests ok.

- [ ] **Step 6: Rewire `script/bootstrap`**

Replace lines 1-138 of `script/bootstrap` (everything from the shebang through
the end of the old `install_dotfiles`) with:

```bash
#!/usr/bin/env bash
#
# bootstrap installs things.

cd "$(dirname "$0")/.."
DOTFILES_ROOT=$(pwd -P)
export DOTFILES_ROOT

set -e

echo ''

source "$DOTFILES_ROOT/script/lib/output.sh"
source "$DOTFILES_ROOT/script/lib/links.sh"

setup_gitconfig () {
  if ! [ -f git/gitconfig.local.symlink ]
  then
    info 'setup gitconfig'

    git_credential='cache'
    if [ "$(uname -s)" == "Darwin" ]
    then
      git_credential='osxkeychain'
    fi

    user ' - What is your github author name?'
    read -e git_authorname
    user ' - What is your github author email?'
    read -e git_authoremail

    sed -e "s/AUTHORNAME/$git_authorname/g" -e "s/AUTHOREMAIL/$git_authoremail/g" -e "s/GIT_CREDENTIAL_HELPER/$git_credential/g" git/gitconfig.local.symlink.example > git/gitconfig.local.symlink

    success 'gitconfig'
  fi
}
```

Leave `install_agents_dir`, `link_my_skills`, and `install_pi_dir` in place for
now — they are removed in Tasks 7-10 as each topic migrates, so bootstrap keeps
working throughout.

- [ ] **Step 7: Verify bootstrap still works end to end**

Run: `script/bootstrap`

Expected: existing links are reported as skipped, no new links, no prompts, and
the run ends with `✅ All installed!`. Then confirm nothing detached:

Run: `ls -la ~/.gitconfig ~/.zshrc ~/.agents`

Expected: all three are still symlinks into `~/.dotfiles`.

- [ ] **Step 8: Commit**

```bash
git add script/lib/output.sh script/lib/links.sh test/links_test.sh script/bootstrap
git commit -m "refactor: extract tested symlink engine from bootstrap"
```

---

## Task 2: Rule 2 — recursive directory walk

**Files:**

- Modify: `script/lib/links.sh` (add `link_tree`, branch in `install_dotfiles`)
- Modify: `test/links_test.sh` (add Rule 2 tests)

**Interfaces:**

- Consumes: `link_file`, `link_physical`, `link_ignored` from Task 1.
- Produces: `link_tree SRC_DIR DST_DIR` — creates `DST_DIR` as a real
  directory, recurses into subdirectories creating real directories, and
  symlinks leaf files individually.

- [x] **Step 1: Write the failing tests**

Add to `test/links_test.sh` immediately before the `### Runner` section:

```bash
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
```

- [x] **Step 2: Run tests to verify they fail**

Run: `test/links_test.sh`

Expected: FAIL on the five new tests. `install_dotfiles` still calls
`link_file` for directory roots, so `~/.config` is created as a symlink to
`config.symlink` and `assert_real_dir` reports "is a symlink, want a real
directory".

- [x] **Step 3: Add `link_tree` to `script/lib/links.sh`**

Insert after `link_file` and before `install_dotfiles`:

```bash
# Walk a *.symlink directory. Intermediate directories are created real so the
# target can be co-owned with the tool that writes there; only leaves are
# linked.
link_tree () {
  local src_dir=$1 dst_dir=$2 entry name

  mkdir -p "$dst_dir"

  for entry in "$src_dir"/* "$src_dir"/.[!.]*; do
    if [ ! -e "$entry" ] && [ ! -L "$entry" ]; then
      continue
    fi

    name="$(basename "$entry")"
    if link_ignored "$name"; then
      continue
    fi

    if [ -d "$entry" ] && [ ! -L "$entry" ]; then
      link_tree "$entry" "$dst_dir/$name"
    else
      link_file "$(link_physical "$entry")" "$dst_dir/$name"
    fi
  done
}
```

The unmatched-glob guard is required because bash 3.2 has no `nullglob` here;
`"$src_dir"/.[!.]*` stays literal when a directory has no dot-entries.

- [x] **Step 4: Branch on directory roots in `install_dotfiles`**

Replace the body of the `while` loop in `install_dotfiles` with:

```bash
  while IFS= read -r -d '' src; do
    name="$(basename "$src")"
    dst="$HOME/.${name%.symlink}"
    if [ -d "$src" ] && [ ! -L "$src" ]; then
      link_tree "$src" "$dst"
    else
      link_file "$(link_physical "$src")" "$dst"
    fi
  done < <(find -H "$DOTFILES_ROOT" -maxdepth 2 -name '*.symlink' \
    -not -path '*/.git/*' -print0)
```

Also extend the header comment block:

```bash
#   Rule 2  dir  NAME.symlink       ->  walk into $HOME/.NAME; intermediate
#                                       directories are real, leaf files are
#                                       linked individually
```

- [x] **Step 5: Run tests to verify they pass**

Run: `test/links_test.sh`

Expected: PASS, 10 tests ok.

- [x] **Step 6: Commit**

```bash
git add script/lib/links.sh test/links_test.sh
git commit -m "feat: recurse into *.symlink directories, linking leaves"
```

---

## Task 3: Rule 3 — nested `*.symlink` links whole

**Files:**

- Modify: `script/lib/links.sh` (add the `*.symlink` case to `link_tree`)
- Modify: `test/links_test.sh` (add Rule 3 tests)

**Interfaces:**

- Consumes: `link_tree`, `link_file`, `link_physical` from Tasks 1-2.
- Produces: no new functions. `link_tree` gains the behavior that a nested
  entry named `X.symlink` is linked whole at `X` with no recursion, as is any
  nested symlink resolving to a directory.

- [ ] **Step 1: Write the failing tests**

Add to `test/links_test.sh` before `### Runner`:

```bash
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `test/links_test.sh`

Expected: FAIL on `test_rule3_nested_dir_links_whole` (currently recurses, so
`~/.pi/agent/themes.symlink` is a real directory and `~/.pi/agent/themes` is
absent) and on `test_rule3_nested_file_strips_suffix_without_adding_dot`
(currently links to `~/.root/inner.symlink`). The two symlink-resolution tests
may already pass via `link_physical`; they are regression cover.

- [ ] **Step 3: Add the `*.symlink` case to `link_tree`**

In `link_tree`, insert between the `link_ignored` guard and the
`[ -d "$entry" ]` branch:

```bash
    case "$name" in
      *.symlink)
        link_file "$(link_physical "$entry")" "$dst_dir/${name%.symlink}"
        continue
        ;;
    esac
```

Extend the header comment block:

```bash
#   Rule 3  nested *.symlink entry  ->  linked whole, suffix stripped, no
#                                       recursion; a nested symlink resolving
#                                       to a directory is also linked whole
```

The existing `[ -d "$entry" ] && [ ! -L "$entry" ]` test already gives the
second half of that rule: a bare symlink pointing at a directory falls to
`link_file` rather than being recursed into. This matches homeshick, which
documents that "Symlinks in the castle are not followed."

- [ ] **Step 4: Run tests to verify they pass**

Run: `test/links_test.sh`

Expected: PASS, 14 tests ok.

- [ ] **Step 5: Commit**

```bash
git add script/lib/links.sh test/links_test.sh
git commit -m "feat: nested *.symlink entries link whole without recursion"
```

---

## Task 4: `.link-children` sentinel

**Files:**

- Modify: `script/lib/links.sh` (sentinel branch in `link_tree`)
- Modify: `test/links_test.sh` (add sentinel tests)

**Interfaces:**

- Consumes: `link_tree`, `link_file`, `link_physical`, `link_ignored`.
- Produces: no new functions. A `.link-children` file in a source directory
  makes `link_tree` stop recursing and link each child whole.

- [ ] **Step 1: Write the failing tests**

Add to `test/links_test.sh` before `### Runner`:

```bash
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `test/links_test.sh`

Expected: FAIL. Without the sentinel branch, `link_tree` recurses into each
skill, so `~/.agents/skills/coding-guidelines` is a real directory rather than
a symlink.

- [ ] **Step 3: Add the sentinel branch to `link_tree`**

Insert immediately after `mkdir -p "$dst_dir"`:

```bash
  if [ -f "$src_dir/.link-children" ]; then
    for entry in "$src_dir"/* "$src_dir"/.[!.]*; do
      if [ ! -e "$entry" ] && [ ! -L "$entry" ]; then
        continue
      fi
      name="$(basename "$entry")"
      if link_ignored "$name"; then
        continue
      fi
      link_file "$(link_physical "$entry")" "$dst_dir/$name"
    done
    return 0
  fi
```

`.link-children` is already in `LINK_IGNORE`, so the sentinel is never linked.
Extend the header comment block:

```bash
#   .link-children sentinel         ->  link each child of this directory
#                                       whole; the directory itself stays real
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `test/links_test.sh`

Expected: PASS, 17 tests ok.

- [ ] **Step 5: Commit**

```bash
git add script/lib/links.sh test/links_test.sh
git commit -m "feat: .link-children sentinel links directory children whole"
```

---

## Task 5: Rule 4 — `*.link` declaration files

**Files:**

- Modify: `script/lib/links.sh` (add `link_declared`, `*.link` case in
  `link_tree`)
- Modify: `test/links_test.sh` (add Rule 4 tests)

**Interfaces:**

- Consumes: `link_file`, `fail`.
- Produces: `link_declared DECL_FILE DST` — reads the first line of
  `DECL_FILE`, expands a leading `$HOME` or `$DOTFILES`, rejects relative
  paths via `fail`, and links `DST` to the result.

- [ ] **Step 1: Write the failing tests**

Add to `test/links_test.sh` before `### Runner`:

```bash
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `test/links_test.sh`

Expected: FAIL. `*.link` files are currently treated as ordinary leaves, so the
engine creates `~/.cursor/skills.link` pointing at the declaration file instead
of `~/.cursor/skills` pointing at the declared target.

- [ ] **Step 3: Add `link_declared` to `script/lib/links.sh`**

Insert after `link_file` and before `link_tree`:

```bash
# Rule 4: NAME.link is a regular file whose first line is the link target.
# Rules 1-3 can only name paths inside the repo; this reaches $HOME paths (for
# a runtime directory shared between tools) and expresses renames.
link_declared () {
  local decl=$1 dst=$2 target=

  IFS= read -r target < "$decl" || true
  target="${target%$'\r'}"

  case "$target" in
    '$HOME'/*)
      target="$HOME/${target#\$HOME/}"
      ;;
    '$DOTFILES'/*)
      target="$DOTFILES_ROOT/${target#\$DOTFILES/}"
      ;;
    /*)
      ;;
    *)
      fail "$decl: target must be absolute or start with \$HOME or \$DOTFILES (got '$target')"
      ;;
  esac

  link_file "$target" "$dst"
}
```

- [ ] **Step 4: Add the `*.link` case to `link_tree`**

Extend the `case "$name"` block added in Task 3 so it reads:

```bash
    case "$name" in
      *.link)
        if [ -f "$entry" ] && [ ! -L "$entry" ]; then
          link_declared "$entry" "$dst_dir/${name%.link}"
          continue
        fi
        ;;
      *.symlink)
        link_file "$(link_physical "$entry")" "$dst_dir/${name%.symlink}"
        continue
        ;;
    esac
```

Add `.link` handling to the sentinel branch as well, so a `*.link` inside a
`.link-children` directory is still honored — replace the `link_file` call in
that loop with:

```bash
      case "$name" in
        *.link)
          if [ -f "$entry" ] && [ ! -L "$entry" ]; then
            link_declared "$entry" "$dst_dir/${name%.link}"
            continue
          fi
          ;;
      esac
      link_file "$(link_physical "$entry")" "$dst_dir/$name"
```

Extend the header comment block:

```bash
#   Rule 4  nested NAME.link file   ->  symlink NAME to the path named on the
#                                       first line of the file; $HOME and
#                                       $DOTFILES are expanded
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `test/links_test.sh`

Expected: PASS, 22 tests ok.

- [ ] **Step 6: Commit**

```bash
git add script/lib/links.sh test/links_test.sh
git commit -m "feat: *.link files declare targets outside the repo"
```

---

## Task 6: Pruning and drift reporting

**Files:**

- Modify: `script/lib/links.sh` (add `prune_links`, `link_report_drift`,
  `LINK_MANAGED_DIRS` and `LINK_DRIFT` bookkeeping)
- Modify: `test/links_test.sh` (add prune and drift tests)

**Interfaces:**

- Consumes: `link_tree`, `install_dotfiles`, `link_file`, `success`, `info`.
- Produces:
  - `prune_links DST_DIR` — removes symlinks directly in `DST_DIR` that resolve
    under `$DOTFILES_ROOT` and whose referent is missing.
  - `link_report_drift` — prints a summary of managed paths that exist as
    regular files rather than symlinks.
  - `LINK_MANAGED_DIRS` array, appended by `link_tree`.
  - `LINK_DRIFT` array, appended by `link_file`.

- [ ] **Step 1: Write the failing tests**

Add to `test/links_test.sh` before `### Runner`:

```bash
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `test/links_test.sh`

Expected: FAIL on `test_prune_removes_dangling_owned_link` (the dangling link
survives) and on `test_drift_is_reported_when_managed_path_is_a_regular_file`
(no "no longer a symlink" text in the output). The other two pass already and
are regression cover.

- [ ] **Step 3: Add pruning and drift bookkeeping**

Add near the top of `script/lib/links.sh`, beside the other state:

```bash
LINK_MANAGED_DIRS=()
LINK_DRIFT=()
```

Add after `link_declared`:

```bash
# A link is ours if it resolves under $DOTFILES_ROOT. Remove ours when the
# referent is gone; leave everything else alone.
prune_links () {
  local dst_dir=$1 link resolved

  if [ ! -d "$dst_dir" ]; then
    return 0
  fi

  for link in "$dst_dir"/* "$dst_dir"/.[!.]*; do
    if [ ! -L "$link" ]; then
      continue
    fi
    resolved="$(readlink "$link")"
    case "$resolved" in
      "$DOTFILES_ROOT"/*) ;;
      *) continue ;;
    esac
    if [ ! -e "$link" ]; then
      rm "$link"
      success "pruned stale symlink $link"
    fi
  done
}

link_report_drift () {
  local path
  if [ "${#LINK_DRIFT[@]}" -eq 0 ]; then
    return 0
  fi
  info 'managed paths that are no longer a symlink (config was rewritten in place):'
  for path in "${LINK_DRIFT[@]}"; do
    info "  $path"
  done
}
```

In `link_tree`, record the directory immediately after `mkdir -p "$dst_dir"`:

```bash
  LINK_MANAGED_DIRS+=("$dst_dir")
```

In `link_file`, record drift inside the existing
`if [ -e "$dst" ] || [ -L "$dst" ]` block, as its first statement:

```bash
    if [ -f "$dst" ] && [ ! -L "$dst" ]; then
      LINK_DRIFT+=("$dst")
    fi
```

Finally, in `install_dotfiles`, reset the arrays alongside the other state and
prune after the walk. The complete function:

```bash
install_dotfiles () {
  info 'installing dotfiles'

  overwrite_all=false
  backup_all=false
  skip_all=false
  LINK_MANAGED_DIRS=()
  LINK_DRIFT=()

  local src name dst dir
  while IFS= read -r -d '' src; do
    name="$(basename "$src")"
    dst="$HOME/.${name%.symlink}"
    if [ -d "$src" ] && [ ! -L "$src" ]; then
      link_tree "$src" "$dst"
    else
      link_file "$(link_physical "$src")" "$dst"
    fi
  done < <(find -H "$DOTFILES_ROOT" -maxdepth 2 -name '*.symlink' \
    -not -path '*/.git/*' -print0)

  if [ "${#LINK_MANAGED_DIRS[@]}" -gt 0 ]; then
    for dir in "${LINK_MANAGED_DIRS[@]}"; do
      prune_links "$dir"
    done
  fi

  link_report_drift
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `test/links_test.sh`

Expected: PASS, 26 tests ok.

- [ ] **Step 5: Commit**

```bash
git add script/lib/links.sh test/links_test.sh
git commit -m "feat: prune stale links and report symlink drift"
```

---

## Task 7: Migrate the agents topic

The engine is complete; this is the first topic to move, and the only one whose
runtime directory has to be relocated out of the repo.

**Files:**

- Create: `agents/agents.symlink/` (from existing content)
- Create: `agents/agents.symlink/skills/.link-children`
- Delete: `agents/skills/` (untracked external installs),
  `agents/skills-lock.json`
- Modify: `.gitignore:18` (remove `agents/skills/*`)
- Modify: `script/bootstrap` (delete `install_agents_dir` and `link_my_skills`
  and their call sites)

**Interfaces:**

- Consumes: `install_dotfiles` from Task 6.
- Produces: `$HOME/.agents/skills` as a real directory — the shared skills
  runtime that Tasks 8-10 point `*.link` files at.

- [ ] **Step 1: Preserve the externally installed skills**

The 37 external skill directories currently live inside the repo. Copy them
somewhere safe before anything moves, so they can be restored into the new
`$HOME` runtime directory instead of reinstalled.

```bash
cd ~/.dotfiles
mkdir -p /tmp/skills-rescue
for d in agents/skills/*/; do
  [ -L "${d%/}" ] && continue   # skip the my-skills symlinks
  cp -R "$d" /tmp/skills-rescue/
done
ls /tmp/skills-rescue | wc -l
```

Expected: 37.

- [ ] **Step 2: Move the tracked content into the new layout**

```bash
cd ~/.dotfiles
mkdir -p agents/agents.symlink/skills
git mv agents/prompts agents/agents.symlink/prompts
git mv agents/commands agents/agents.symlink/commands
for d in agents/my-skills/*/; do
  git mv "$d" "agents/agents.symlink/skills/$(basename "${d%/}")"
done
git mv agents/.skill-lock.json agents/agents.symlink/.skill-lock.json
git rm agents/skills-lock.json
touch agents/agents.symlink/skills/.link-children
git add agents/agents.symlink/skills/.link-children
rmdir agents/my-skills
```

`agents/README.md` stays at the topic root, outside the linked tree, so it is
not linked into `$HOME`.

- [ ] **Step 3: Make the `CLAUDE.md` prompt symlink relative**

It is currently an absolute link into
`/Users/stratbarrett/.dotfiles/claude/CLAUDE.md`, which breaks on any machine
with a different username.

```bash
cd ~/.dotfiles/agents/agents.symlink/prompts
rm CLAUDE.md
ln -s ../../../claude/CLAUDE.md CLAUDE.md
cd ~/.dotfiles
git add agents/agents.symlink/prompts/CLAUDE.md
readlink agents/agents.symlink/prompts/CLAUDE.md
```

Expected: `../../../claude/CLAUDE.md`. Task 9 repoints this when `CLAUDE.md`
moves into `claude/claude.symlink/`.

- [ ] **Step 4: Remove the bespoke bootstrap functions**

In `script/bootstrap`, delete `install_agents_dir` and `link_my_skills`
entirely, and delete these two lines from the call sequence at the bottom:

```bash
install_agents_dir
link_my_skills
```

- [ ] **Step 5: Drop the gitignore rule and the in-repo runtime directory**

Remove line 18 of `.gitignore`:

```text
agents/skills/*
```

Then replace the `~/.agents` whole-directory symlink with nothing, so bootstrap
can create a real directory, and delete the in-repo runtime directory:

```bash
cd ~/.dotfiles
rm ~/.agents
rm -rf agents/skills
```

- [ ] **Step 6: Bootstrap and restore the external skills**

```bash
cd ~/.dotfiles
LINK_CONFLICT_POLICY=backup script/bootstrap
cp -R /tmp/skills-rescue/* ~/.agents/skills/
```

- [ ] **Step 7: Verify the new layout**

Run: `ls -la ~/.agents ~/.agents/skills | head -30`

Expected: `~/.agents` is a real directory; `~/.agents/prompts` and
`~/.agents/commands` are real directories containing symlinks into the repo;
`~/.agents/.skill-lock.json` is a symlink into the repo;
`~/.agents/skills` is a real directory holding 7 symlinks to
`agents/agents.symlink/skills/*` plus 37 real external directories.

Run: `git status --short`

Expected: no untracked entries under `agents/`. This is the pollution fix — the
external skills are no longer inside the repo at all. Note that
`agents/skills/enable-ollama-in-cursor`, the dangling symlink that
`link_my_skills` could never prune, is gone with the directory.

Run: `skills install <any-source>/<any-name> && git status --short`

Expected: still clean. The new skill appears in `~/.agents/skills` as a real
directory outside the repo, and only `.skill-lock.json` shows as modified.

Run: `test/links_test.sh`

Expected: PASS, 26 tests ok.

- [ ] **Step 8: Commit**

```bash
cd ~/.dotfiles
git add -A agents .gitignore script/bootstrap
git commit -m "refactor: move agents to the *.symlink directory convention

The skills runtime directory moves out of the repo into ~/.agents/skills, so
external installs no longer land in git. my-skills/ collapses into
agents.symlink/skills/ now that authored and installed skills live in
different places."
rm -rf /tmp/skills-rescue
```

---

## Task 8: Add the cursor topic

**Files:**

- Create: `cursor/cursor.symlink/hooks.json` (from `~/.cursor/hooks.json`)
- Create: `cursor/cursor.symlink/skills.link`
- Create: `cursor/cursor.symlink/prompts.symlink` (repo symlink)
- Create: `cursor/cursor.symlink/commands.symlink` (repo symlink)
- Create: `cursor/README.md`

**Interfaces:**

- Consumes: `$HOME/.agents/skills` from Task 7; `install_dotfiles` from Task 6.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Import the untracked Cursor config**

`~/.cursor/hooks.json` is a real file today, tracked nowhere.

```bash
cd ~/.dotfiles
mkdir -p cursor/cursor.symlink
cp ~/.cursor/hooks.json cursor/cursor.symlink/hooks.json
```

`~/.cursor/mcp.json` is deliberately **not** tracked. It holds MCP server
credentials, and Cursor rewrites it in place, which would replace the symlink
with a regular file. Leave it alone.

Confirm nothing sensitive came across:

```bash
rg -i 'key|token|secret|password' cursor/cursor.symlink/hooks.json \
  || echo "clean"
```

Expected: `clean`. If anything matches, stop and move the value into a
machine-local file rather than committing it.

- [ ] **Step 2: Declare the shared skills runtime and the repo-owned content**

```bash
cd ~/.dotfiles/cursor/cursor.symlink
printf '$HOME/.agents/skills\n' > skills.link
ln -s ../../agents/agents.symlink/prompts prompts.symlink
ln -s ../../agents/agents.symlink/commands commands.symlink
```

`skills.link` uses Rule 4 because Cursor's installer writes into `skills/`, so
the link must point at the `$HOME` runtime directory rather than the repo.
`prompts` and `commands` use Rule 3 and point into the repo, because only you
write there.

- [ ] **Step 3: Replace the old hand-made Cursor links**

The three existing links were made by the now-deleted `install_agents_dir` and
point at the old `agents/skills`, `agents/prompts`, `agents/commands` paths.

```bash
rm ~/.cursor/skills ~/.cursor/prompts ~/.cursor/commands
cd ~/.dotfiles
LINK_CONFLICT_POLICY=backup script/bootstrap
```

- [ ] **Step 4: Write `cursor/README.md`**

```markdown
# cursor

Cursor configuration, linked into `~/.cursor` by `script/bootstrap`.

`~/.cursor` stays a real directory because Cursor writes `plugins/`,
`projects/`, and `extensions/` there. Only the entries below are managed.

| Repo path | Target | Rule |
| --- | --- | --- |
| `cursor.symlink/hooks.json` | `~/.cursor/hooks.json` | leaf link |
| `cursor.symlink/prompts.symlink` | `~/.cursor/prompts` | whole dir, repo |
| `cursor.symlink/commands.symlink` | `~/.cursor/commands` | whole dir, repo |
| `cursor.symlink/skills.link` | `~/.cursor/skills` | whole dir, `~/.agents` |

`skills` points at the `$HOME` runtime directory rather than the repo because
Cursor's skill installer writes into it. Prompts and commands point into the
repo, because nothing but you writes there.

`mcp.json` is intentionally not managed: it holds credentials, and Cursor
rewrites it in place, which would replace the symlink with a regular file.

`script/bootstrap` reports any managed path that has stopped being a symlink,
which is how in-place rewrites become visible.
```

- [ ] **Step 5: Verify**

Run: `ls -la ~/.cursor`

Expected: `plugins`, `projects`, `extensions`, `skills-cursor` are real
directories; `skills`, `prompts`, `commands`, and `hooks.json` are symlinks;
`mcp.json` is still a plain untracked file.

Run: `readlink ~/.cursor/skills`

Expected: `/Users/<you>/.agents/skills`

Run: `ls ~/.cursor/skills | head -5`

Expected: skill names resolve through to `~/.agents/skills`.

- [ ] **Step 6: Commit**

```bash
git add cursor
git commit -m "feat: track cursor config as a topic

hooks.json was untracked. skills points at the shared ~/.agents/skills runtime
rather than the repo, so Cursor's installer writes outside git. mcp.json stays
unmanaged: it holds credentials and Cursor rewrites it in place."
```

---

## Task 9: Migrate the claude topic

**Files:**

- Create: `claude/claude.symlink/CLAUDE.md` (moved from `claude/CLAUDE.md`)
- Create: `claude/claude.symlink/skills.link`
- Modify: `agents/agents.symlink/prompts/CLAUDE.md` (repoint the symlink)
- Delete: `claude/sync.sh`

**Interfaces:**

- Consumes: `$HOME/.agents/skills` from Task 7.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Move `CLAUDE.md` into the linked tree**

```bash
cd ~/.dotfiles
mkdir -p claude/claude.symlink
git mv claude/CLAUDE.md claude/claude.symlink/CLAUDE.md
```

- [ ] **Step 2: Repoint the agents prompt symlink**

Task 7 left it at `../../../claude/CLAUDE.md`, which is now one level short.

```bash
cd ~/.dotfiles/agents/agents.symlink/prompts
rm CLAUDE.md
ln -s ../../../claude/claude.symlink/CLAUDE.md CLAUDE.md
cd ~/.dotfiles
git add agents/agents.symlink/prompts/CLAUDE.md
cat agents/agents.symlink/prompts/CLAUDE.md > /dev/null && echo "resolves"
```

Expected: `resolves`.

- [ ] **Step 3: Declare the shared skills runtime**

```bash
cd ~/.dotfiles/claude/claude.symlink
printf '$HOME/.agents/skills\n' > skills.link
```

- [ ] **Step 4: Inspect the existing `~/.claude/skills` before replacing it**

It is a real directory of 38 relative symlinks into `~/.agents/skills`, so
nothing of substance is lost — but confirm there is no real content first.

```bash
find ~/.claude/skills -maxdepth 1 -type d -not -path ~/.claude/skills
```

Expected: no output. If any real directory is listed, move it into
`~/.agents/skills` before continuing, then re-run and expect no output.

```bash
rm -rf ~/.claude/skills
rm ~/.claude/CLAUDE.md
```

- [ ] **Step 5: Delete the unwired sync script and bootstrap**

`claude/sync.sh` was never called by `script/install` or `script/bootstrap`,
which is why `~/.claude/CLAUDE.md` was a stale copy rather than a link.

```bash
cd ~/.dotfiles
git rm claude/sync.sh
LINK_CONFLICT_POLICY=backup script/bootstrap
```

- [ ] **Step 6: Verify**

Run: `ls -la ~/.claude/CLAUDE.md ~/.claude/skills`

Expected: `CLAUDE.md` is a symlink into `claude/claude.symlink/CLAUDE.md`;
`skills` is a symlink to `~/.agents/skills`.

Run: `readlink ~/.claude/skills && ls ~/.claude/skills | wc -l`

Expected: `/Users/<you>/.agents/skills` and a count of 44.

- [ ] **Step 7: Commit**

```bash
git add -A claude agents
git commit -m "fix: link CLAUDE.md instead of leaving a stale copy

claude/sync.sh was never wired into bootstrap, so ~/.claude/CLAUDE.md had
drifted into a plain copy. Replaced by the *.symlink convention."
```

---

## Task 10: Migrate the pi topic

**Files:**

- Create: `pi/pi.symlink/agent/**` (moved from `pi/agent/**`)
- Create: `pi/pi.symlink/agent/skills/.link-children`
- Create: `pi/config.symlink/mcp/mcp.json.link`
- Modify: `script/bootstrap` (delete `install_pi_dir` and its call site)

**Interfaces:**

- Consumes: `install_dotfiles` from Task 6.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Move the tracked pi content**

```bash
cd ~/.dotfiles
mkdir -p pi/pi.symlink
git mv pi/agent pi/pi.symlink/agent
git mv pi/pi.symlink/agent/prompts pi/pi.symlink/agent/prompts.symlink
git mv pi/pi.symlink/agent/themes pi/pi.symlink/agent/themes.symlink
touch pi/pi.symlink/agent/skills/.link-children
git add pi/pi.symlink/agent/skills/.link-children
```

`prompts` and `themes` become whole-directory links (Rule 3) because pi does
not write into them. `skills` gets the sentinel because pi's skill installer
does.

Note that `pi/pi.symlink/agent/mcp.local.json` moved along with the rest and is
still ignored by the `*.local.json` rule in `.gitignore`.

- [ ] **Step 2: Declare the renamed MCP config**

`~/.config/mcp/mcp.json` is sourced from `mcp.local.json`, so the basenames
differ and no name-based rule can express it.

```bash
cd ~/.dotfiles
mkdir -p pi/config.symlink/mcp
printf '$DOTFILES/pi/pi.symlink/agent/mcp.local.json\n' \
  > pi/config.symlink/mcp/mcp.json.link
```

- [ ] **Step 3: Drop the dead `rtk.ts` reference**

`install_pi_dir` linked `pi/agent/extensions/rtk.ts`, which does not exist in
the repo. Nothing to move; the reference disappears with the function.

Delete `install_pi_dir` entirely from `script/bootstrap`, and delete its call
site:

```bash
install_pi_dir
```

The bottom of `script/bootstrap` should now read:

```bash
setup_gitconfig
install_dotfiles

# If we're on a Mac, let's install and setup homebrew.
if [ "$(uname -s)" == "Darwin" ]
then
  info "installing dependencies"
  if source bin/dot | while read -r data; do info "$data"; done
  then
    success "dependencies installed"
  else
    fail "error installing dependencies"
  fi
fi
```

- [ ] **Step 4: Clear the old pi links and bootstrap**

```bash
rm -rf ~/.pi/agent/prompts ~/.pi/agent/themes ~/.pi/agent/extensions
rm -f ~/.pi/agent/settings.json ~/.pi/agent/mcp.json ~/.config/mcp/mcp.json
cd ~/.dotfiles
LINK_CONFLICT_POLICY=backup script/bootstrap
```

`~/.pi/agent/skills` holds symlinks into `~/.agents/skills` that pi created
itself; leave them, they are foreign and pruning will not touch them.

- [ ] **Step 5: Verify**

Run: `ls -la ~/.pi/agent`

Expected: `settings.json` and `mcp.json` are symlinks into the repo; `prompts`
and `themes` are single symlinks; `skills` is a real directory.

Run: `readlink ~/.config/mcp/mcp.json`

Expected: a path ending in `pi/pi.symlink/agent/mcp.local.json`.

Run: `ls -la ~/.pi/agent/skills | head`

Expected: 4 symlinks into `pi/pi.symlink/agent/skills/*` alongside pi's own
links into `~/.agents/skills`.

- [ ] **Step 6: Commit**

```bash
git add -A pi script/bootstrap
git commit -m "refactor: move pi to the *.symlink directory convention

Drops install_pi_dir, including its link to the nonexistent
pi/agent/extensions/rtk.ts."
```

---

## Task 11: Migrate the opencode topic

**Files:**

- Create: `opencode/config.symlink/opencode/opencode.json` (moved)
- Create: `opencode/config.symlink/opencode/oh-my-opencode.json` (moved)
- Delete: `opencode/scripts/link-config.sh`
- Modify: `opencode/README.md`

**Interfaces:**

- Consumes: `install_dotfiles` from Task 6.
- Produces: nothing.

- [ ] **Step 1: Move the configs under a link root**

```bash
cd ~/.dotfiles
mkdir -p opencode/config.symlink/opencode
git mv opencode/opencode.json opencode/config.symlink/opencode/opencode.json
git mv opencode/oh-my-opencode.json \
  opencode/config.symlink/opencode/oh-my-opencode.json
```

- [ ] **Step 2: Delete the unwired script**

`opencode/scripts/link-config.sh` is not called by `script/install` (which only
runs `install.sh` files) or by `script/bootstrap`. The live links were made by
hand.

```bash
cd ~/.dotfiles
git rm opencode/scripts/link-config.sh
rmdir opencode/scripts 2>/dev/null || true
```

- [ ] **Step 3: Replace the hand-made links**

```bash
rm -f ~/.config/opencode/opencode.json ~/.config/opencode/oh-my-opencode.json
cd ~/.dotfiles
LINK_CONFLICT_POLICY=backup script/bootstrap
```

- [ ] **Step 4: Fix the README's install instruction**

`opencode/README.md` currently claims the configuration is installed by
`dot --install`, which never ran `link-config.sh`. Replace this block:

````markdown
```bash
# Install configuration (symlinks to ~/.config/opencode/)
dot --install
```
````

with:

````markdown
Configuration is linked into `~/.config/opencode/` by `script/bootstrap`:

```bash
dot --sync
```

| Repo path | Target |
| --- | --- |
| `config.symlink/opencode/opencode.json` | `~/.config/opencode/opencode.json` |
| `config.symlink/opencode/oh-my-opencode.json` | `~/.config/opencode/oh-my-opencode.json` |
````

- [ ] **Step 5: Verify**

Run: `ls -la ~/.config/opencode`

Expected: both JSON files are symlinks into
`opencode/config.symlink/opencode/`, and `~/.config/opencode` is a real
directory.

Run: `test/links_test.sh`

Expected: PASS, 26 tests ok.

- [ ] **Step 6: Commit**

```bash
git add -A opencode
git commit -m "refactor: link opencode config via bootstrap

Replaces opencode/scripts/link-config.sh, which was never wired into any
entry point."
```

---

## Task 12: Documentation

**Files:**

- Modify: `README.md` (the `*.symlink` paragraph)
- Modify: `AGENTS.md` (directory structure, "Managing Agent Skills", command
  list)
- Modify: `agents/README.md` (rewrite for the new layout)
- Create: `test/README.md`

**Interfaces:**

- Consumes: the finished convention from Tasks 1-11.
- Produces: nothing.

- [ ] **Step 1: Update `README.md`**

Replace the sentence "Anything with an extension of `.symlink` will get
symlinked without extension into `$HOME` when you run `script/bootstrap`" with:

```markdown
Anything named `*.symlink` is linked into `$HOME` without the extension and
with a leading dot when you run `script/bootstrap`.

- A **file** named `gitconfig.symlink` becomes `~/.gitconfig`.
- A **directory** named `cursor.symlink` targets `~/.cursor`, and bootstrap
  recurses into it: intermediate directories are created as real directories
  and leaf files are linked individually. This keeps directories that a tool
  also writes to — `~/.cursor/plugins`, `~/.config` — out of the repo.
- Inside such a tree, a nested entry ending in `.symlink` is linked whole
  without recursion, and a file named `X.link` creates a symlink at `X`
  pointing to the path on its first line (`$HOME` and `$DOTFILES` are
  expanded).
- A `.link-children` file in a directory links each of that directory's
  children whole, leaving the directory itself real.

Only the link root gains a leading dot; nested paths map verbatim, so
`config.symlink/opencode/opencode.json` becomes
`~/.config/opencode/opencode.json`.
```

- [ ] **Step 2: Update `AGENTS.md`**

Three edits.

Replace the `agents/` block in the directory structure section with:

```text
agents/                  # Shared agent content library
  agents.symlink/        # Linked into ~/.agents
    prompts/             # Leaf-linked into ~/.agents/prompts
    commands/            # Leaf-linked into ~/.agents/commands
    skills/              # Authored skills; .link-children makes
                         # ~/.agents/skills a real dir
cursor/                  # Cursor adapter -> ~/.cursor
claude/                  # Claude adapter -> ~/.claude
pi/                      # pi adapter -> ~/.pi/agent
opencode/                # opencode adapter -> ~/.config/opencode
test/                    # Tests for the symlink engine
```

Replace the "Special File Types" bullets for agents with:

```markdown
- `*.symlink` - Files and directories linked into `$HOME` (extension removed,
  leading dot added). Directories are recursed into; see `README.md`.
- `*.link` - A file whose first line is the symlink target. Used for targets
  outside the repo and for renames.
- `.link-children` - Sentinel; links each child of its directory whole.
- `agents/agents.symlink/skills/` - Authored skills, tracked in git
- `~/.agents/skills/` - The shared skills runtime directory. Real directory in
  `$HOME`; authored skills are symlinks into the repo, external installs are
  real directories. Nothing external is stored in the repo.
```

Replace the "Managing Agent Skills" section with:

````markdown
Authored skills live in `agents/agents.symlink/skills/` and are tracked in git.
The runtime directory is `~/.agents/skills`, a real directory in `$HOME` that
Cursor, Claude, and pi all point at. External installs land there, not in the
repo; only `.skill-lock.json` is committed.

```bash
# Author a new skill
mkdir agents/agents.symlink/skills/my-skill
# write agents/agents.symlink/skills/my-skill/SKILL.md
dot --sync                      # links it into ~/.agents/skills/

# Install an external skill (recorded in .skill-lock.json)
skills install <source>/<name>

# Restore all external skills on a new machine
skills experimental_install
```
````

Finally, fix the command list: every `dot --bootstrap` in `AGENTS.md` should be
`dot --sync`. `bin/dot` accepts `-s` and `--sync`; `--bootstrap` has never been
a valid flag and exits with "Invalid option".

- [ ] **Step 3: Rewrite `agents/README.md`**

````markdown
# agents

Shared agent content: prompts, commands, and authored skills. Cursor, Claude,
and pi all consume this directory, each through its own topic.

## Layout

| Path | Tracked | Target |
| --- | --- | --- |
| `agents.symlink/prompts/` | yes | `~/.agents/prompts/*` (leaf links) |
| `agents.symlink/commands/` | yes | `~/.agents/commands/*` (leaf links) |
| `agents.symlink/skills/` | yes | one whole-dir link per skill |
| `agents.symlink/skills/.link-children` | yes | makes `~/.agents/skills` real |
| `agents.symlink/.skill-lock.json` | yes | `~/.agents/.skill-lock.json` |
| `README.md` | yes | not linked (outside the tree) |

## The runtime directory is not in this repo

`~/.agents/skills` is a real directory in `$HOME`. Skills you author are
symlinks from it into `agents.symlink/skills/`; skills installed by any tool
are real directories in `$HOME`. Nothing external is stored in the repo, so
`git status` stays quiet.

`.skill-lock.json` is linked rather than copied, so the skills CLI's writes
land in git and external skills can be restored on a new machine with
`skills experimental_install`.

## Adding a skill

```bash
mkdir agents/agents.symlink/skills/my-skill
# write SKILL.md
dot --sync
```

## Who consumes this

| Consumer | Mechanism |
| --- | --- |
| `~/.agents` | this topic |
| `~/.cursor` | `cursor/cursor.symlink/` — `skills.link`, `prompts.symlink` |
| `~/.claude` | `claude/claude.symlink/` — `skills.link` |
| `~/.pi/agent` | `pi/pi.symlink/agent/` — its own skills, plus pi's own links |
````

- [ ] **Step 4: Write `test/README.md`**

````markdown
# test

Tests for the symlink engine in `script/lib/links.sh`.

```bash
test/links_test.sh
```

Each test builds a throwaway `DOTFILES_ROOT` and `HOME` under `mktemp -d`, runs
`install_dotfiles` against them, and asserts on the resulting links. Nothing
touches the real machine.

Tests set `LINK_CONFLICT_POLICY=skip` so `link_file` never prompts. The other
values are `prompt` (the default, used by `script/bootstrap`), `overwrite`, and
`backup`.

Add a test by defining a function named `test_*`; the runner discovers them
with `declare -F`.
````

- [ ] **Step 5: Verify the docs match reality**

Run: `test/links_test.sh`

Expected: PASS, 26 tests ok.

Run: `rg -n 'dot --bootstrap' AGENTS.md README.md agents/README.md`

Expected: no matches.

Run: `rg -n 'my-skills|agents/skills' AGENTS.md agents/README.md README.md`

Expected: no matches except the `~/.agents/skills` runtime references.

- [ ] **Step 6: Commit**

```bash
git add README.md AGENTS.md agents/README.md test/README.md
git commit -m "docs: document the config-directory symlink convention"
```

---

## Rollback

Every task commits separately and the repo is small, so `git revert` of a single
task commit plus one `script/bootstrap` run restores the previous state. The one
step that is not purely git-reversible is Task 7 Step 5, which deletes the
in-repo `agents/skills`; that content is copied to `/tmp/skills-rescue` in Step
1 and is not removed until Step 8 verifies the new layout.
