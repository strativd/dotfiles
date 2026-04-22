# Architecture

**Analysis Date:** 2026-04-22

## Pattern Overview

**Overall:** Topical (modular) dotfiles architecture — a fork of holman/dotfiles, organized by tool/concern ("topics") rather than by file type. Each top-level directory is a self-contained topic that contributes zsh configuration, install hooks, and/or `$HOME`-facing dotfiles via a convention-based auto-loading and symlinking system.

**Key Characteristics:**
- Topical folders at the repo root (`zsh/`, `git/`, `node/`, `python/`, `homebrew/`, `macos/`, `agents/`, etc.) — each encapsulates everything related to one tool or concern.
- Zero explicit registration: files are discovered by naming convention (`*.zsh`, `*.symlink`, `install.sh`).
- Three-phase zsh loading order (`path.zsh` → `*.zsh` → `completion.zsh`) enforced in `zsh/zshrc.symlink`.
- Symlink-based deployment: source of truth stays in the repo, `$HOME` gets symlinks, and machine-specific overrides live in `~/.localrc` (ignored).
- Single CLI entry point (`bin/dot`) wraps the underlying `script/bootstrap` and `script/install` workflows.
- macOS-first; Linux supported where reasonable.

## Layers

**Shell runtime (topic `.zsh` files):**
- Purpose: Configure the interactive zsh session (aliases, functions, PATH, prompt, completion, tool initialization).
- Location: Every topic folder, e.g. `zsh/`, `system/`, `git/`, `node/`, `python/`, `ruby/`, `mise/`, `homebrew/`, `jest/`, `xcode/`, `yarn/`, `claude/`, `opencode/`.
- Contains: `path.zsh` (PATH exports), generic `*.zsh` (aliases/functions/config), `completion.zsh` (autocomplete hooks).
- Depends on: `zsh/zshrc.symlink` (the loader), `$ZSH` env var pointing at `$DOTFILES`.
- Used by: The user's interactive shell.

**Bootstrap / symlink layer (`*.symlink` files):**
- Purpose: Deliver config files into `$HOME` as dotfiles (e.g. `~/.zshrc`, `~/.gitconfig`, `~/.vimrc`).
- Location: Scattered across topics, e.g. `zsh/zshrc.symlink`, `git/gitconfig.symlink`, `git/gitignore.symlink`, `vim/vimrc.symlink`, `tmux/tmux.conf.symlink`, `editor/editorconfig.symlink`, `ruby/gemrc.symlink`, `ruby/irbrc.symlink`, `node/nvmrc.symlink`, `zsh/inputrc.symlink`.
- Convention: `foo/bar.symlink` → `~/.bar` (extension stripped, dot prefixed).
- Deployed by: `script/bootstrap` (discovered via `find -maxdepth 2 -name '*.symlink'`).

**Install layer (`install.sh` per topic):**
- Purpose: One-time/idempotent system setup for a topic (install binaries, register defaults).
- Location: `homebrew/install.sh`, `macos/install.sh`, `ruby/install.sh`.
- Invoked by: `script/install` (which does `find . -name install.sh | while read installer ; do sh -c "${installer}" ; done`).
- Contract: Must be idempotent, must `exit 0` on non-applicable platforms (e.g. `macos/install.sh` bails on non-Darwin).

**CLI / orchestration layer:**
- Purpose: User-facing commands and glue scripts.
- Location: `bin/dot`, `script/bootstrap`, `script/install`.
- Contains: The `dot` front-end dispatcher plus bootstrap/install helpers.
- Used by: Humans running `dot --start` on a new machine, or `dot --bootstrap` after edits.

**Agents / AI tooling layer:**
- Purpose: Share skills, commands, and prompts across AI CLIs (Cursor, Claude).
- Location: `agents/` (symlinked to `~/.agents`), `agents/skills/` (→ `~/.cursor/skills`), `agents/prompts/` (→ `~/.cursor/prompts`), `agents/commands/` (→ `~/.cursor/commands`).
- Depends on: `script/bootstrap`'s `install_agents_dir` and `link_my_skills` helpers.

**Executables on PATH:**
- Purpose: Personal scripts reachable from any shell.
- Location: `bin/` (added to `$PATH` via `system/_path.zsh`).
- Contains: `dot`, `e`, `g` (smart git wrapper), `git-*` helpers, `todo`, `search`, `set-defaults`, assorted utilities.

## Data Flow

**Interactive shell startup (`zsh/zshrc.symlink`):**

1. Set `DOTFILES` and `ZSH` (falls back to `$HOME/.dotfiles`, else `~/src/github.com/strativd/dotfiles`).
2. Export `PROJECTS=~/Code`.
3. Source `~/.localrc` if present (machine-local secrets / overrides; gitignored).
4. Glob all `$ZSH/**/*.zsh` into `config_files`, deduplicated.
5. Source every `*/path.zsh` first (PATH must exist before anything else resolves commands).
6. Source every other `*.zsh` except `path.zsh` and `completion.zsh` (aliases, functions, prompt, env, tool init).
7. `autoload -U compinit && compinit` — initialize zsh completion system.
8. Source every `*/completion.zsh` (tool-specific completions registered *after* `compinit`).
9. History keybindings (`up-line-or-beginning-search`, etc.) and misc trailing aliases.

**Bootstrap (`script/bootstrap`, also invoked as `dot --sync`):**

1. `cd` to repo root; `set -e`.
2. `setup_gitconfig`: If `git/gitconfig.local.symlink` is missing, prompt for name/email and render from `git/gitconfig.local.symlink.example`, choosing `osxkeychain` vs `cache` based on `uname`.
3. `install_dotfiles`: `find -H -maxdepth 2 -name '*.symlink'` and `link_file` each to `$HOME/.<basename-without-ext>`. Conflicts trigger an interactive `[s]kip / [o]verwrite / [b]ackup` prompt (with `S`/`O`/`B` "all" variants).
4. `install_agents_dir`: Symlink `agents/` → `~/.agents`; if `~/.cursor/` exists, also link `agents/skills`, `agents/prompts`, `agents/commands` into it.
5. `link_my_skills`: For each subdir in `agents/my-skills/`, create a symlink in `agents/skills/` pointing back to it.
6. On Darwin only: `source bin/dot` (with no args → runs `--install` then `--brew`) to install dependencies.

**Install (`script/install`, also invoked as `dot --install`):**

1. `cd` to repo root; `set -e`.
2. `find . -name install.sh` and `sh -c` each one. Order is filesystem-dependent, so each `install.sh` must be independent and idempotent.

**New-laptop setup (`dot --start` / `dot -S`):**

1. `dot --dotfiles` (delegates to bootstrap-style linking).
2. `dot --install` → runs all `install.sh` scripts.
3. `dot --brew` → `homebrew/install.sh` + `brew update` + `homebrew/brew.sh`.
4. `dot --macos` → `macos/set-defaults.sh`.

**State Management:**
- No runtime state. All configuration is declarative (files in the repo).
- Machine-specific state lives outside the repo: `~/.localrc` for env/secrets, `git/gitconfig.local.symlink` for git identity (gitignored via `*.local.symlink`), `agents/skills/*` for installed skills (gitignored except `.skill-lock.json` and `README.md`).

## Key Abstractions

**Topic (top-level directory):**
- Purpose: Encapsulate everything related to one tool or concern — shell config, install scripts, and user-level dotfiles — in a single folder.
- Examples: `git/`, `node/`, `python/`, `ruby/`, `homebrew/`, `macos/`, `agents/`, `zsh/`, `system/`, `mise/`, `opencode/`, `claude/`, `jest/`, `tmux/`, `vim/`, `xcode/`, `yarn/`, `editor/`.
- Pattern: Add a directory; drop in any combination of `path.zsh`, `<name>.zsh`, `completion.zsh`, `install.sh`, `*.symlink`, `README.md`. No central registration needed — the loader and bootstrap scripts discover everything by convention.

**Symlink file (`*.symlink`):**
- Purpose: Declaratively describe a file that should appear in `$HOME` as a dotfile.
- Examples: `zsh/zshrc.symlink`, `git/gitconfig.symlink`, `vim/vimrc.symlink`, `tmux/tmux.conf.symlink`, `editor/editorconfig.symlink`.
- Pattern: `<topic>/<name>.symlink` → `$HOME/.<name>` (extension removed). Discovered by `find -maxdepth 2 -name '*.symlink'` in `script/bootstrap`.

**`*.local.*` machine-local overlay:**
- Purpose: Carry machine-specific values (git identity, secrets) without tracking them in git.
- Examples: `git/gitconfig.local.symlink` generated from `git/gitconfig.local.symlink.example`; `~/.localrc` sourced by `zsh/zshrc.symlink`.
- Pattern: `.gitignore` excludes `*.local.symlink`, `*.local.zsh`, `*.env`, `*.venv`.

**Zsh loader stages:**
- `path.zsh` (stage 1): PATH-manipulating exports. Run before anything else so later stages can `command -v` tools. Example: `homebrew/path.zsh` exports `/opt/homebrew/bin`; `system/_path.zsh` seeds the core PATH including `$ZSH/bin`; `yarn/path.zsh` adds yarn.
- Generic `*.zsh` (stage 2): Everything else — aliases, functions, tool init. Example: `git/worktree.zsh`, `node/nvm.zsh`, `system/aliases.zsh`.
- `completion.zsh` (stage 3): Registered *after* `compinit` runs, so tools like `git/completion.zsh`, `node/completion.zsh`, `ruby/completion.zsh`, `zsh/completion.zsh` plug into the active completion system.

**`install.sh` (per-topic bootstrap):**
- Purpose: Install binaries/system dependencies for a topic.
- Examples: `homebrew/install.sh`, `macos/install.sh`, `ruby/install.sh`.
- Pattern: Must be idempotent (guard with `command -v` or `uname` checks) and must `exit 0` when it has nothing to do.

**Agent skills (split authoring vs runtime):**
- `agents/my-skills/<skill>/` (tracked): where the user authors skills.
- `agents/skills/<skill>/` (symlinks, gitignored): the runtime directory CLIs consume.
- Bridge: `link_my_skills` in `script/bootstrap` creates `agents/skills/<name>` → `../my-skills/<name>` for each own-authored skill.
- `agents/skills/.skill-lock.json` (tracked): manifest of externally-installed skills, reproducible on new machines.

**Functions (`functions/`):**
- Purpose: Autoloaded zsh functions. `zsh/config.zsh` adds `$ZSH/functions` to `fpath` and `autoload -U $ZSH/functions/*(:t)`, so every file in `functions/` becomes a callable function named after the file (e.g. `c`, `mkd`, `extract`, `gf`, `_boom`, `_brew`, `_c`).

## Entry Points

**`bin/dot`:**
- Location: `bin/dot`
- Triggers: User invokes `dot [option]` from any shell (`bin/` is on `$PATH`).
- Responsibilities: Dispatch to the right workflow:
  - `-e / --edit` → `exec e "$dotfilesDirectory"` (open in editor)
  - `-r / --reload` → `exec $SHELL`
  - `-n / --new` → `open -a iterm .`
  - `-m / --macos` → run `macos/set-defaults.sh`
  - `-b / --brew` → `homebrew/install.sh` + `brew update` + `homebrew/brew.sh`
  - `-i / --install` → `script/install`
  - `-s / --sync` → `script/bootstrap`
  - `-S / --start` → chain `--dotfiles`, `--install`, `--brew`, `--macos` for new-laptop bootstrap
  - No args → `--install` then `--brew`
- Note: AGENTS.md documents `--bootstrap`, but the actual flag in `bin/dot` is `-s / --sync`. Aliases for `--help` (`-h`) and dispatching are defined in `bin/dot:13-86`.

**`script/bootstrap`:**
- Location: `script/bootstrap`
- Triggers: `dot --sync`, direct invocation on a fresh machine, or the tail of `script/bootstrap` itself invoking `bin/dot` when on macOS.
- Responsibilities: Interactive `setup_gitconfig`; create `$HOME/.<dotfile>` symlinks from `*.symlink`; link `agents/` into `~/.agents` and `~/.cursor/`; link `my-skills` into `agents/skills/`; finally trigger dependency install on Darwin.

**`script/install`:**
- Location: `script/install`
- Triggers: `dot --install`, or transitively from `script/bootstrap` → `bin/dot` → `--install`.
- Responsibilities: Discover every `install.sh` under the repo and execute it. Order is filesystem-dependent, so installers must be independent.

**`zsh/zshrc.symlink` (runtime entry point):**
- Location: `zsh/zshrc.symlink` → `~/.zshrc`
- Triggers: Every new interactive zsh shell.
- Responsibilities: Define `$DOTFILES`/`$ZSH`/`$PROJECTS`, source `~/.localrc`, then run the three-stage loader described in *Data Flow*.

**Subsidiary CLI scripts:**
- `homebrew/brew.sh` — Brewfile-based package install, invoked by `dot --brew`.
- `macos/set-defaults.sh` — applies `defaults write` settings, invoked by `dot --macos`.

## Error Handling

**Strategy:**
- All bash/sh scripts use `set -e` so any failing command aborts the script.
- `script/bootstrap` defines `info`/`user`/`success`/`fail` helpers (colored output); `fail` prints and `exit`s.
- Symlink conflicts in `link_file` are resolved interactively rather than blowing up — the user chooses skip / overwrite / backup, with "all" variants to batch-answer.
- Platform guards: `macos/install.sh` exits cleanly on non-Darwin; `homebrew/install.sh` branches on `uname` to pick the Homebrew vs Linuxbrew installer.
- Zsh loader uses `typeset -U` to dedupe the file list and `:#` pattern exclusion to filter out `path.zsh`/`completion.zsh` from the generic stage — no explicit error paths; a missing topic simply contributes nothing.

**Patterns:**
- Command existence guard: `if (( $+commands[git] )); then ... fi` (see `zsh/prompt.zsh`) or `if ! [ -x "$(command -v frum)" ]; then ... fi` (see `ruby/install.sh`).
- Idempotent installs: every `install.sh` checks before installing.
- Fallback config: `zsh/zshrc.symlink` falls back from `~/.dotfiles` to `~/src/github.com/strativd/dotfiles` if the default path is absent.

## Cross-Cutting Concerns

**Logging:** Human-readable colored output via `info`/`success`/`user`/`fail` in `script/bootstrap`; plain `echo "› ..."` in `bin/dot`. No structured logging — scripts are user-facing.

**Validation:** No automated test suite. Validation is manual: run `dot --reload`, check `ls -la ~/.zshrc` etc., verify `which` resolves expected commands. AGENTS.md lists the manual verification workflow.

**Authentication / secrets:**
- Never committed. `*.local.symlink`, `*.local.zsh`, `*.env`, `*.venv` are gitignored.
- Git credential helper selected at bootstrap time: `osxkeychain` on Darwin, `cache` elsewhere.
- Machine-local env vars live in `~/.localrc`, sourced by `zsh/zshrc.symlink` before any `*.zsh` files load.

**PATH management:** Centralized through the `path.zsh` stage so ordering is deterministic. `system/_path.zsh` provides the base PATH; `homebrew/path.zsh` prepends `/opt/homebrew/bin`; `yarn/path.zsh` adds yarn.

**Completion:** All completion registration deferred until after `compinit`. Topics that need autocompletion drop a `completion.zsh` (e.g. `git/completion.zsh`, `node/completion.zsh`, `ruby/completion.zsh`, `zsh/completion.zsh`).

**fpath / autoloaded functions:** `zsh/fpath.zsh` adds every top-level topic directory to `fpath`. `zsh/config.zsh` additionally adds `$ZSH/functions` and auto-loads every file in `functions/` as a zsh function (name taken from filename via `*(:t)`).

**Platform detection:** Handled per-script via `uname -s` (`script/bootstrap`, `homebrew/install.sh`, `macos/install.sh`). No central abstraction.

---

*Architecture analysis: 2026-04-22*
