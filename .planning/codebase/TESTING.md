# Testing Patterns

**Analysis Date:** 2026-04-22

This is a personal dotfiles / shell-configuration repository. There is **no automated test suite**, no test runner, no CI. Validation is performed manually by running the bootstrap/install scripts and observing a working shell.

> Note: the `jest/` directory contains `jest/jester.zsh`, which is a convenience **wrapper function** for running Jest in *other* JavaScript projects. It is not a test suite for this repository — it is shell sugar (`jester`, `jester -c`, `jester -o`) that Yarn-invokes `jest` wherever the user happens to be.

## Test Framework

**Runner:** None.

**Assertion Library:** None.

**Run Commands:** Not applicable. The equivalent of "run the tests" is:

```bash
dot --reload                  # Re-source the shell to pick up config changes
script/bootstrap              # Re-link *.symlink files; verify "All installed!" at the end
dot --install                 # Re-run every topic's install.sh
```

Any of these either completes cleanly or surfaces an error. That is the verification.

## Validation Workflow

The manual validation loop used when modifying the repo (from `AGENTS.md` "Making Changes" and "Testing and Validation"):

1. Edit files in the relevant topic directory (`zsh/`, `git/`, `node/`, etc.).
2. Re-source the shell to apply `.zsh` changes: `dot --reload` (which just runs `exec $SHELL`, see `bin/dot:40-42`).
3. For new `*.symlink` files: run `dot --bootstrap` (or `script/bootstrap`) to create the symlink into `$HOME`.
4. For new `install.sh` dependencies: run `dot --install` (or `script/install`) to execute all installers.
5. Verify in a new terminal session that nothing regressed.

## Verification Commands

These are the hand-run "assertions" the codebase relies on:

**Symlink verification:**
```bash
ls -la ~/.gitconfig           # Should point at ~/.dotfiles/git/gitconfig.symlink
ls -la ~/.vimrc               # Should point at ~/.dotfiles/vim/vimrc.symlink
ls -la ~/.tmux.conf           # Should point at ~/.dotfiles/tmux/tmux.conf.symlink
ls -la ~/.zshrc               # Should point at ~/.dotfiles/zsh/zshrc.symlink
ls -la ~/.agents              # Should point at ~/.dotfiles/agents
```

All `*.symlink` files in the repo have a matching expected `~/.<basename>` target. See `script/bootstrap:128-155` for the linking logic and `install_agents_dir` for the agents-specific links.

**PATH verification:**
```bash
echo $PATH                    # Expect ~/.dotfiles/bin in the PATH (added by system/_path.zsh)
which dot                     # Should resolve to ~/.dotfiles/bin/dot
which g                       # Should resolve to ~/.dotfiles/bin/g
```

**Command availability:**
```bash
which git
which brew                    # macOS
which nvm                     # sourced, not in PATH as a binary — see `type nvm` instead
which uv
```

**Agent skill linking:**
```bash
ls -la ~/.dotfiles/agents/skills/<skill-name>   # Should be a symlink into agents/my-skills/
```
(see `link_my_skills` in `script/bootstrap:157-170`)

## Bootstrap Verification

Running `script/bootstrap` (or `dot --bootstrap`) is the primary integration test:

```bash
script/bootstrap
```

**Expected output markers:**
- `[ .. ]` (blue) info lines for each step: `installing dotfiles`, `linking agents directory`, etc.
- `[ OK ]` (green) success lines for every linked file: `linked .../git/gitconfig.symlink to /Users/.../.gitconfig`.
- `[ ?? ]` (yellow) interactive prompts when a target already exists (skip/overwrite/backup).
- Final line: `✅ All installed!`

**Failure modes to watch for:**
- `[FAIL]` (red) lines — the script exits immediately; re-read the message.
- Missing `~/.gitconfig.local` after first run — `setup_gitconfig` prompts for name/email and writes it; if you Ctrl-C'd, delete the partial file and rerun.
- Stale symlinks — if a symlink points at an old path, choose `[O]verwrite all` when prompted.

## Install Script Verification

`script/install` walks the tree and runs every `install.sh`:

```bash
script/install
# finds: homebrew/install.sh, macos/install.sh, ruby/install.sh (as of 2026-04-22)
```

Each `install.sh` is expected to be idempotent — safe to run repeatedly. Patterns used:

```sh
# homebrew/install.sh — guard on existing binary
if test ! $(which brew); then
  # install
fi
exit 0
```

```sh
# ruby/install.sh — guard on each dependency
if ! [ -x "$(command -v frum)" ]; then
  brew install frum
fi
```

When writing a new `install.sh`, follow this pattern: check first, install only if missing, `exit 0` on success.

## Shell-Level Sanity Checks

Functional checks you can run to verify the shell is correctly configured:

```zsh
# Zsh loader wired up:
echo $ZSH                     # → /Users/<you>/.dotfiles
echo $DOTFILES                # → same
echo $PROJECTS                # → ~/Code

# Aliases loaded:
alias g                       # → 'g () { "$ZSH/bin/g" "$@"; }'
alias l                       # → 'ls -lF ...'
alias ..                      # → 'cd ..'

# Functions autoloaded from functions/:
type mkd                      # → mkd is a shell function
type extract
type c

# Completions loaded:
# Tab after `c ` should list $PROJECTS subdirectories (see functions/_c)
# Tab after `brew ` should list brew subcommands (see functions/_brew)

# Prompt renders with git awareness:
# cd into any git repo — prompt should show "on <branch>" in green/red
```

## Test File Organization

**Not applicable.** This repo contains no `*.test.*`, `*.spec.*`, or `__tests__/` files. Its only test-adjacent asset is the Jester wrapper (`jest/jester.zsh`) intended for invoking Jest in other projects.

## Mocking / Fixtures / Coverage

**Not applicable.**

- No mocking framework.
- Only "fixture" is `git/gitconfig.local.symlink.example` (template from which `setup_gitconfig` in `script/bootstrap:30-50` generates the user's real `gitconfig.local.symlink` via `sed` substitution).
- No coverage tooling. Coverage is implicit in the fact that every sourced file runs on every `exec $SHELL`.

## CI

**None.** There is no `.github/workflows/`, no `.circleci/`, no `.travis.yml`. Changes are committed manually after the author verifies locally.

## Common Validation Patterns

**Pattern 1: "Does my new `.zsh` file load cleanly?"**
```bash
# Start a brand-new shell (tests the whole load chain)
exec $SHELL -l

# Or scope it down to just your file
zsh -c 'source ~/.dotfiles/mytopic/myfile.zsh && echo OK'
```

**Pattern 2: "Does my new `*.symlink` land where I expect?"**
```bash
script/bootstrap              # answer 's' (skip) or 'O' (overwrite all) when prompted
ls -la ~/.<basename>          # verify target
readlink ~/.<basename>        # verify it points at the repo file
```

**Pattern 3: "Does my new function behave correctly?"**
Invoke it with its expected args, then with missing/wrong args; confirm the usage hint / `return 1` branch fires. Example from `zsh/aliases.zsh:78-84` (`killit`) — supplying no arg should print `Not killin' it... No argument supplied`.

**Pattern 4: "Did I break the prompt?"**
The prompt is rendered by `zsh/prompt.zsh`. `cd` into a git repo — you should see `in <dir>` + `on <branch>` (green if clean, red if dirty) + optional `with N unpushed`. If the prompt collapses or errors, check `git_branch`, `git_dirty`, `git_prompt_info`, `need_push`, `directory_name`, `battery_status`.

## When to Add Automated Tests

Given the nature of this repo (personal shell config, macOS-specific, interactively installed), automated testing is deliberately absent. If future work demands it, consider:

- **`bats-core`** (Bash Automated Testing System) for `script/bootstrap`, `bin/dot`, `bin/g`, and the installers.
- **`shellcheck`** for static lint of every `*.sh` and `*.zsh` file (would catch unquoted expansions, undeclared vars, etc.).
- **GitHub Actions** matrix on `macos-latest` running `script/bootstrap` in a dry-run mode against `$HOME=/tmp/fakehome`.

Until then, the verification loop is: **edit → `dot --reload` → visually confirm → commit**.

---

*Testing analysis: 2026-04-22*
