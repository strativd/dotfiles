# Coding Conventions

**Analysis Date:** 2026-04-22

This is a personal dotfiles repository (forked from `holman/dotfiles`). The codebase is 100% shell — primarily Zsh configuration, Bash/POSIX scripts, and git config. Conventions derive from `AGENTS.md`, `editor/editorconfig.symlink`, and observed patterns across existing topic directories.

## File Organization

**Topical structure:**
- Each subject (git, node, python, ruby, homebrew, macos, tmux, vim, etc.) lives in its own top-level directory.
- Files inside a topic directory are discovered by file extension (`*.zsh`, `*.symlink`, `install.sh`), not by being listed anywhere explicitly.

**Special file extensions:**
- `*.zsh` — auto-sourced into every Zsh session (see `zsh/zshrc.symlink` for loader logic).
- `*.symlink` — symlinked into `$HOME` with the extension stripped (e.g., `git/gitconfig.symlink` → `~/.gitconfig`). Handled by `script/bootstrap`.
- `install.sh` — invoked by `script/install`; deliberately `.sh` (not `.zsh`) so it is NOT auto-sourced.
- `*.local.symlink`, `*.local.zsh`, `*.env`, `*.venv` — gitignored; used for machine-specific/secret config.

**Special filenames:**
- `path.zsh` — sourced FIRST in the load order; should only touch `$PATH` and `$MANPATH`. Example: `system/_path.zsh` (note the `_` prefix is used here despite the filename rule — see `homebrew/path.zsh` for the canonical form).
- `completion.zsh` — sourced LAST in the load order, AFTER `compinit`. Used for topic-specific tab completion (e.g., `git/completion.zsh`, `node/completion.zsh`, `ruby/completion.zsh`, `zsh/completion.zsh`).
- `README.md` — per-topic documentation (e.g., `functions/README.md`, `mise/README.md`, `opencode/README.md`, `python/README.md`).

## Naming Patterns

**Files:**
- Lowercase, short, category-descriptive: `aliases.zsh`, `config.zsh`, `prompt.zsh`, `completion.zsh`, `path.zsh`, `install.sh`.
- `*.symlink` files are named after their destination without the leading dot: `vimrc.symlink` → `~/.vimrc`, `gitconfig.symlink` → `~/.gitconfig`, `tmux.conf.symlink` → `~/.tmux.conf`.
- Zsh completion files in `functions/` follow the autoload convention: leading underscore + command name (`_c`, `_boom`, `_brew`) with `#compdef <cmd>` on line 1.
- Standalone `bin/` scripts use kebab-case: `bin/git-promote`, `bin/git-cob`, `bin/battery-status`, `bin/set-defaults`. Single-letter names are also used: `bin/g`, `bin/e`.

**Aliases** (hierarchical — see `zsh/aliases.zsh` and the `[alias]` section of `git/gitconfig.symlink`):
1. **Single letters** for the most frequent commands — `g` (git wrapper), `l` (ls), `c` (cd to project), `s` (status), `b` (branch), `d` (diff).
2. **Compound short aliases** mirror command + flag order — `aa = add --all`, `cm = commit --message`, `cb = checkout -b`, `can = commit --amend --no-edit`. Rule from `git/gitconfig.symlink`: "the alias should be in the same order as the command name followed by its options" (right: `fb = foo --bar`; wrong: `bf = foo --bar`).
3. **Descriptive / workflow aliases** — `pushon`, `pullon`, `push-f`, `cleanest`, `reincarnate`, `snapshot`, `panic`.
4. **"Friendly" synonyms** — `uncommit`, `unadd`, `unstage`, `discard`, `restart`, `branches`, `stashes`.

**Functions:**
- lowercase with underscores: `link_file`, `install_dotfiles`, `setup_gitconfig`, `git_branch`, `git_prompt_info`, `need_push`, `directory_name`, `battery_status` (all in `script/bootstrap` and `zsh/prompt.zsh`).
- Internal/helper functions conventionally start with `_`: `_tree-branch_parse_ref`, `_git_checkout_worktree_row`, `_brew_all_formulae`, `_brew_installed_formulae` (see `git/worktree.zsh`, `functions/_brew`).
- Short user-facing helpers can be lowercase single words: `mkd`, `extract`, `gf`, `killit`, `jester`, `gwork`.

**Variables:**
- **Uppercase for exports / globals**: `ZSH`, `DOTFILES`, `DOTFILES_ROOT`, `PROJECTS`, `EDITOR`, `HISTFILE`, `HISTSIZE`, `NVM_DIR`, `NPM_CONFIG_GLOBALCONFIG`, `LSCOLORS`, `CLICOLOR`.
- **lowercase for locals / script-internal**: `src`, `dst`, `overwrite`, `backup`, `skip`, `action`, `git_credential`, `wt_path`, `branch_label`, `remote`, `branch`, `worktree_path`, `parsed`.
- In `script/bootstrap`: `local overwrite_all=false backup_all=false skip_all=false` — always declare block-scoped mutable state with `local`.

## Code Style

**Formatting (`editor/editorconfig.symlink`):**
- `charset = utf-8`
- `end_of_line = lf`
- `insert_final_newline = true`
- `trim_trailing_whitespace = true`
- `indent_style = space`
- `indent_size = 2`
- `quote_type = double`

**Indentation exceptions:**
- `git/gitconfig.symlink` uses TABS for alias definitions (standard git config style). This is the only major file that intentionally uses tabs.
- `functions/mkd` also uses a tab inside its body — acceptable for ad-hoc scripts, but new code should prefer 2-space indentation.

**Shebangs:**
- `#!/usr/bin/env bash` — preferred for Bash scripts (`script/bootstrap`, `homebrew/brew.sh`).
- `#!/bin/sh` — used for POSIX-simple scripts (`script/install`, `bin/dot`, `homebrew/install.sh`, `functions/extract`, `functions/mkd`).
- `#!/bin/zsh` — used when Zsh-specific features are required (`functions/c`).
- Files meant for sourcing (`*.zsh`, `*.symlink` config files) have NO shebang.

**Leading docblock comment:**
Most scripts open with a brief purpose comment in the `holman/dotfiles` style:

```bash
#!/usr/bin/env bash
#
# bootstrap installs things.
```

or

```zsh
#!/bin/zsh
#
# This lets you quickly jump into a project directory.
#
# Type:
#
#   c <tab>
```

See `script/bootstrap`, `bin/dot`, `functions/c`, `functions/extract`, `functions/mkd` for canonical examples.

## Error Handling

**Fail-fast in scripts:**
- Every installer/bootstrap starts with `set -e` to exit on first error. Examples: `script/bootstrap:8`, `script/install:5`, `bin/dot:8`, `bin/g:8`.
- Config files sourced into the shell (`*.zsh`) do NOT use `set -e` — that would kill the user's shell on any failure.

**Command existence checks:**
Two idiomatic forms are used:

```zsh
# Zsh-native form (preferred in *.zsh config files)
if (( $+commands[git] )); then
  git="$commands[git]"
fi
```

```sh
# POSIX form (preferred in portable install scripts)
if ! [ -x "$(command -v frum)" ]; then
  brew install frum
fi

# Or the older "test" form
if test ! $(which brew); then
  echo "Installing Homebrew for you."
fi
```

Canonical examples: `zsh/prompt.zsh:5`, `python/uv.zsh:5`, `git/worktree.zsh:25`, `ruby/install.sh:1`, `homebrew/install.sh:9`.

**Colored output helpers (`script/bootstrap:12-28`):**
The bootstrap script defines four leveled output helpers — reuse this pattern for any new interactive installer:

```bash
info () {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

user () {
  printf "\r  [ \033[0;33m??\033[0m ] $1\n"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit
}
```

- **Blue `[ .. ]`** — `info` — progress/status messages.
- **Yellow `[ ?? ]`** — `user` — interactive prompts.
- **Green `[ OK ]`** — `success` — completed steps (uses `\033[2K` to clear the current line first, so it overwrites the preceding `info` line).
- **Red `[FAIL]`** — `fail` — fatal errors; `exit` terminates the script.

**User-argument validation** (`zsh/aliases.zsh:78-84`, `AGENTS.md` template):

```zsh
killit() {
  if [ -z "$1" ]; then
    echo "Not killin' it... No argument supplied"
  else
    kill -9 $(lsof -i tcp:$1 -t)
  fi
}
```

For new functions with required args, echo a usage hint and `return 1`:

```zsh
custom_function() {
  if [[ -z "$1" ]]; then
    echo "Usage: custom_function <argument>"
    return 1
  fi
  # ...
}
```

See `git/worktree.zsh:114-117` (`tree-branch`) for a fuller example using `print -u2` (stderr).

## Import Organization (Zsh Load Order)

Loading is driven entirely by `zsh/zshrc.symlink` (sourced from `~/.zshrc` after bootstrap):

1. `$DOTFILES` and `$ZSH` exported; `~/.localrc` sourced if present (machine-local overrides).
2. All `*.zsh` files under `$ZSH/**/` collected into `config_files`.
3. **All `*/path.zsh` files** sourced first — PATH setup only.
4. **All other `*.zsh` files** sourced next — config, aliases, functions, completions that don't belong in a `completion.zsh`.
5. `autoload -U compinit; compinit` — Zsh completion system initialized.
6. **All `*/completion.zsh` files** sourced last — topic-specific completion now that `compinit` is ready.
7. `up-line-or-beginning-search` / `down-line-or-beginning-search` ZLE widgets bound.

**Implication:** Files CANNOT rely on load order within step 4. Write `.zsh` files idempotently.

## Shell Function Patterns

**Template (`functions/README.md`):**

```sh
function() {
  # function args can be accessed using
  # $1, $2, $3, etc. or $@ (for all)
  for arg in "$@"
  do
    "print $arg"
  done
}
```

**Zsh autoload functions** — dropped into `functions/` as files WITHOUT a `function_name()` wrapper; the filename IS the function name. `zsh/config.zsh:4-6` wires this up:

```zsh
fpath=($ZSH/functions $fpath)
autoload -U $ZSH/functions/*(:t)
```

Examples: `functions/c`, `functions/mkd`, `functions/extract`, `functions/gf`. Completion stubs for these go in the same directory with a leading underscore: `functions/_c`, `functions/_boom`, `functions/_brew`.

## Git Config Conventions (`git/gitconfig.symlink`)

- Group aliases under section-comment banners: `### add ###`, `### branch ###`, `### commit ###`, etc.
- Star the most-used aliases with `# 🌟` immediately above their definition.
- Alias order mirrors command-then-flags: `aa = add --all`, not `ta = add --all`.
- Shell scripts inside aliases use the `!"f() { ...; }; f"` wrapper to get proper `$@` behavior.
- Machine-specific / private overrides go in `~/.gitconfig.local` (symlinked from `git/gitconfig.local.symlink`, which is gitignored and generated interactively by `script/bootstrap:30-50`).

## Comments

**When to comment:**
- Opening docblock explaining what the script does and how to invoke it (see `functions/extract:1-7`, `functions/c:1-15`).
- Section banners for long files: `### CATEGORY #######################` in `zsh/aliases.zsh`, or `### add ###` in `git/gitconfig.symlink`.
- External attribution: `# credit: http://nparikh.org/notes/zshrc.txt` (`functions/extract:7`), `# Thanks to http://durdn.com/blog/...` (`git/gitconfig.symlink:695`).
- Non-obvious intent or platform caveats: `# Note: .dmg/hdiutil is macOS-specific.` (`functions/extract:4`), `# Uses a subshell to avoid GNU-specific xargs -r flag so it works on macOS BSD xargs.` (`git/gitconfig.symlink:440`).
- `# TODO`, `# 🌟`, and emoji markers are accepted for emphasis.

**Avoid:** narrating obvious behavior, restating the command name, or translating Zsh syntax into English.

## Module / Topic Design

**Adding a new topic** (`AGENTS.md:127-136`):

1. `mkdir newtopic/`
2. Add files as needed:
   - `newtopic/path.zsh` — PATH additions (sourced first).
   - `newtopic/config.zsh` or `newtopic/aliases.zsh` — main config (sourced in middle wave).
   - `newtopic/completion.zsh` — autocomplete (sourced last).
   - `newtopic/install.sh` — one-shot installer run by `dot --install`.
   - `newtopic/*.symlink` — files that must land in `$HOME`.
3. Add a `newtopic/README.md` documenting purpose and any manual steps.

**Existing exemplars:** `git/`, `node/`, `python/`, `ruby/`, `homebrew/`, `system/`.

## Platform-Conditional Code

Guard macOS-only code with `uname` checks:

```bash
if [ "$(uname -s)" == "Darwin" ]; then
  git_credential='osxkeychain'
fi
```

See `script/bootstrap:36-39`, `script/bootstrap:178`, `zsh/prompt.zsh:58-60` (`battery_status`), `homebrew/install.sh:14-20`.

---

*Convention analysis: 2026-04-22*
