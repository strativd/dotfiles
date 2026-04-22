# Codebase Structure

**Analysis Date:** 2026-04-22

## Directory Layout

```
.dotfiles/
├── AGENTS.md                     # Top-level repo guide / agent context
├── README.md                     # User-facing overview
├── LICENSE.md                    # License
├── .gitignore                    # Excludes *.local.*, *.env, agents/skills/*
├── mise.toml                     # Mise runtime/tool versions pinned at repo root
├── .planning/                    # GSD planning artifacts (codebase maps, etc.)
│   └── codebase/                 # Structured codebase analysis docs
├── .vscode/                      # Editor workspace settings
│
├── bin/                          # Executables on $PATH (added by system/_path.zsh)
│   ├── dot                       # Primary CLI entry point
│   ├── g                         # Smart git wrapper (used by `g` alias)
│   ├── e                         # Editor launcher
│   ├── git-*                     # Git subcommand helpers (git-cow, git-cob, ...)
│   ├── search, todo, yt, ...     # Misc utilities
│   └── set-defaults              # Thin wrapper around macos/set-defaults.sh
│
├── script/                       # Repo-level installation / sync scripts
│   ├── bootstrap                 # Create symlinks, setup gitconfig, link agents
│   └── install                   # Discover and run every topic's install.sh
│
├── agents/                       # Agent content (symlinked to ~/.agents, ~/.cursor/*)
│   ├── README.md
│   ├── commands/                 # → ~/.cursor/commands (markdown command defs)
│   ├── prompts/                  # → ~/.cursor/prompts
│   ├── my-skills/                # Own-authored skills (tracked in git)
│   │   ├── add-agents-file/
│   │   ├── enable-ollama/
│   │   ├── prompt-optimizer/
│   │   └── refactor-with-a-kiss/
│   └── skills/                   # Runtime skills dir → ~/.cursor/skills (gitignored)
│       ├── .skill-lock.json      # Tracked — manifest of installed external skills
│       └── README.md             # Tracked
│
├── zsh/                          # Core zsh runtime configuration
│   ├── zshrc.symlink             # → ~/.zshrc — the loader
│   ├── inputrc.symlink           # → ~/.inputrc
│   ├── config.zsh                # Options, history, keybindings, fpath setup
│   ├── fpath.zsh                 # Add every topic folder to fpath
│   ├── aliases.zsh               # Core aliases (`g`, `l`, navigation, cleanup, ...)
│   ├── prompt.zsh                # Custom prompt (git_branch, git_dirty)
│   ├── completion.zsh            # zstyle tweaks for completion
│   └── window.zsh                # Terminal title helpers
│
├── system/                       # Cross-topic shell basics (loads early)
│   ├── _path.zsh                 # Base PATH export (includes ./bin, $ZSH/bin)
│   ├── aliases.zsh               # General-purpose system aliases
│   ├── env.zsh                   # EDITOR, LANG, ...
│   ├── grc.zsh                   # Generic colourizer integration
│   └── keys.zsh                  # Key bindings
│
├── functions/                    # Autoloaded zsh functions (name = filename)
│   ├── README.md
│   ├── c                         # cd into $PROJECTS
│   ├── mkd                       # mkdir && cd
│   ├── extract                   # Archive extractor
│   ├── gf                        # git helper
│   └── _boom, _brew, _c          # Completion helpers
│
├── git/                          # Git config and helpers
│   ├── gitconfig.symlink         # → ~/.gitconfig
│   ├── gitconfig.local.symlink   # → ~/.gitconfig.local (machine-local, gitignored)
│   ├── gitconfig.local.symlink.example
│   ├── gitignore.symlink         # → ~/.gitignore
│   ├── completion.zsh            # git completion
│   └── worktree.zsh              # worktree helpers
│
├── homebrew/                     # Homebrew provisioning
│   ├── install.sh                # Install Homebrew if missing
│   ├── brew.sh                   # Run Brewfile / brew bundle
│   └── path.zsh                  # export /opt/homebrew/bin on PATH
│
├── macos/                        # macOS system configuration
│   ├── install.sh                # softwareupdate -i -a (Darwin only)
│   └── set-defaults.sh           # `defaults write ...` settings
│
├── node/                         # Node.js / nvm / pnpm
│   ├── aliases.zsh
│   ├── completion.zsh
│   ├── nvm.zsh
│   ├── pnpm.zsh
│   └── nvmrc.symlink             # → ~/.nvmrc
│
├── python/                       # Python / uv
│   ├── README.md
│   ├── aliases.zsh
│   └── uv.zsh
│
├── ruby/                         # Ruby / frum
│   ├── aliases.zsh
│   ├── completion.zsh
│   ├── frum.zsh
│   ├── install.sh                # brew install frum, openssl
│   ├── gemrc.symlink             # → ~/.gemrc
│   └── irbrc.symlink             # → ~/.irbrc
│
├── mise/                         # mise (asdf replacement)
│   ├── README.md
│   ├── aliases.zsh
│   ├── dev.zsh
│   └── dev.config.json
│
├── jest/
│   └── jester.zsh                # jest test aliases
│
├── tmux/
│   └── tmux.conf.symlink         # → ~/.tmux.conf
│
├── vim/
│   ├── vimrc.symlink             # → ~/.vimrc
│   └── colors/
│       └── solarized.vim
│
├── editor/
│   └── editorconfig.symlink      # → ~/.editorconfig
│
├── xcode/
│   └── aliases.zsh
│
├── yarn/
│   └── path.zsh                  # Add yarn to PATH
│
├── claude/                       # Claude Code integration
│   ├── CLAUDE.md
│   └── alias.zsh
│
└── opencode/                     # opencode / ollama integration
    ├── README.md
    ├── aliases.zsh
    ├── ollama.zsh
    ├── opencode.json
    ├── opencode.ollama.json
    ├── opencode.omo.json
    ├── oh-my-opencode.json
    ├── oh-my-opencode.token-{low,mid,high}.json
    ├── oh-my-opencode.w-ollama.jsonc
    └── scripts/
        ├── link-config.sh
        ├── ollama-start.sh
        ├── ollama-perf.sh
        └── ollama-update.sh
```

## Directory Purposes

**`bin/`:**
- Purpose: Personal executables placed on `$PATH` so they are reachable from any shell.
- Contains: The primary `dot` CLI, a smart git wrapper (`g`), an editor launcher (`e`), many `git-*` subcommand helpers, and one-off utilities (`todo`, `search`, `yt`, `set-defaults`, ...).
- Key files: `bin/dot`, `bin/g`, `bin/e`, `bin/set-defaults`.

**`script/`:**
- Purpose: Repo-level orchestration scripts that operate across topics.
- Contains: Exactly two scripts — one for symlink-driven sync, one for running per-topic installers.
- Key files: `script/bootstrap`, `script/install`.

**`agents/`:**
- Purpose: Configuration shared across AI CLIs (Cursor, Claude). The whole directory is symlinked to `~/.agents`; three subdirectories are additionally symlinked into `~/.cursor/`.
- Contains:
  - `agents/commands/` → `~/.cursor/commands` (tracked markdown command definitions)
  - `agents/prompts/` → `~/.cursor/prompts` (tracked prompt library)
  - `agents/my-skills/<skill>/` (tracked) — where the user authors skills
  - `agents/skills/` → `~/.cursor/skills` (runtime dir; gitignored contents)
- Key files: `agents/README.md`, `agents/skills/.skill-lock.json`, `agents/skills/README.md`.

**`zsh/`:**
- Purpose: Core zsh experience — the loader, options, aliases, prompt, base completion behavior.
- Contains: The `zshrc.symlink` loader, `inputrc.symlink`, and a handful of `*.zsh` files that run early in the generic stage.
- Key files: `zsh/zshrc.symlink`, `zsh/config.zsh`, `zsh/fpath.zsh`, `zsh/aliases.zsh`, `zsh/prompt.zsh`, `zsh/completion.zsh`.

**`system/`:**
- Purpose: Cross-topic shell fundamentals that belong to no single tool — base PATH, environment variables, system-level aliases.
- Contains: `_path.zsh` (seeds PATH), `env.zsh`, `aliases.zsh`, `grc.zsh`, `keys.zsh`.
- Key files: `system/_path.zsh`, `system/env.zsh`.

**`functions/`:**
- Purpose: Autoloaded zsh functions. Every file here becomes a shell function named after the filename, via `autoload -U $ZSH/functions/*(:t)` in `zsh/config.zsh`.
- Contains: `c`, `mkd`, `extract`, `gf`, and completion helpers (`_boom`, `_brew`, `_c`).
- Key files: `functions/c`, `functions/mkd`, `functions/extract`.

**Language / tool topics (`node/`, `python/`, `ruby/`, `mise/`, `homebrew/`, `yarn/`, `jest/`, `xcode/`, `vim/`, `tmux/`, `editor/`, `git/`, `macos/`, `claude/`, `opencode/`):**
- Purpose: One folder per tool/runtime/editor; each folder is self-contained and contributes some combination of `path.zsh`, other `*.zsh`, `completion.zsh`, `install.sh`, `*.symlink`, and an optional `README.md`.
- Contains: Only files relevant to that tool — no cross-contamination.

**`.planning/`:**
- Purpose: GSD (Getting Shit Done) planning workflow artifacts.
- Contains: `.planning/codebase/` with structured analysis docs (this file lives here).

## Key File Locations

**Entry Points:**
- `bin/dot`: Primary CLI — dispatches to all lifecycle operations.
- `script/bootstrap`: Symlink + gitconfig bootstrap.
- `script/install`: Runs all topic `install.sh` scripts.
- `zsh/zshrc.symlink` → `~/.zshrc`: Runtime entry point for every interactive shell.

**Configuration:**
- `zsh/config.zsh`: Zsh options, history, keybindings, `fpath` + function autoloading.
- `zsh/fpath.zsh`: Adds every topic folder to `fpath`.
- `system/_path.zsh`: Seed PATH (`./bin`, `/usr/local/bin`, `/usr/local/sbin`, `$ZSH/bin`, `$PATH`).
- `homebrew/path.zsh`: Prepend `/opt/homebrew/bin`.
- `mise.toml`: Tool version pins at repo root.
- `.gitignore`: Excludes `*.local.symlink`, `*.local.zsh`, `*.env`, `*.venv`, `.DS_Store`, `Desktop.ini`, `agents/skills/*`.

**Core Logic:**
- `script/bootstrap`: `link_file`, `install_dotfiles`, `install_agents_dir`, `link_my_skills`, `setup_gitconfig`.
- `bin/dot`: Flag parser dispatching to `bootstrap`, `install`, `brew`, `macos`, etc.
- `zsh/zshrc.symlink`: Three-stage loader (`path.zsh` → `*.zsh` → `completion.zsh`).

**Testing:**
- No automated tests. Manual verification per AGENTS.md (check symlinks, `which`, `echo $PATH`).

## Naming Conventions

**Files:**
- `*.symlink` — Deployed into `$HOME` as `~/.<basename-without-ext>`. Example: `vim/vimrc.symlink` → `~/.vimrc`.
- `path.zsh` — PATH-manipulating exports only. Loaded in stage 1 of the zsh loader.
- `completion.zsh` — Completion registrations. Loaded in stage 3, after `compinit`.
- Other `*.zsh` — Aliases, functions, tool init. Loaded in stage 2.
- `install.sh` — Idempotent topic installer, discovered by `script/install`.
- `*.local.symlink`, `*.local.zsh` — Machine-local overlays; gitignored.
- `_<name>.zsh` — Leading underscore used for files that should sort/load first within a folder (e.g. `system/_path.zsh`).
- `<name>.example` — Template that gets rendered into a `*.local.*` file by `script/bootstrap` (e.g. `git/gitconfig.local.symlink.example`).
- `SKILL.md` / `README.md` — Documentation; `README.md` is allowed per major directory.

**Directories:**
- Lowercase, singular-noun, tool-named topics at the repo root (`node/`, not `nodejs/` or `NodeModules/`).
- Subdirectories under `agents/` are kebab-case (`my-skills/`, not `mySkills/`).

**Shell identifiers (from AGENTS.md, reinforced by code):**
- Single-letter aliases for ubiquitous commands: `g` → git wrapper, `l`/`la`/`lsd` → ls variants.
- Compound aliases read like natural flags: `cm` for `commit --message`, `co` for `checkout`, `pushon` for `push origin $(git branch-name)`.
- Functions: clear action-oriented names (`git_branch`, `git_dirty`, `mkd`, `extract`).
- Variables: uppercase exports (`ZSH`, `DOTFILES`, `PROJECTS`, `EDITOR`), lowercase for locals.

## Where to Add New Code

**New alias:**
- Core / cross-topic: append to the right `### CATEGORY ###` section of `zsh/aliases.zsh` or `system/aliases.zsh`.
- Tool-specific: append to `<topic>/aliases.zsh` (e.g. `node/aliases.zsh`, `git` aliases belong in `git/gitconfig.symlink` or dedicated helpers in `bin/git-*`).

**New autoloaded function:**
- Create `functions/<name>` (no extension). The function name will be `<name>` automatically.
- For tool-specific helpers, prefer a new `*.zsh` in the relevant topic instead.

**New `$HOME` dotfile:**
- Drop a file under the appropriate topic named `<basename>.symlink`. Example: to deliver `~/.foorc`, create `foo/foorc.symlink`.
- Run `dot --sync` (a.k.a. `script/bootstrap`) to create the symlink.

**New executable on `$PATH`:**
- Drop an executable file in `bin/`. Make sure it has a shebang and `chmod +x`. It is immediately on `$PATH` because of `system/_path.zsh`.

**New topic (an entirely new tool/concern):**
1. `mkdir <topic>/` at the repo root.
2. Add any of: `path.zsh` (if it needs PATH), `<name>.zsh` (aliases/init), `completion.zsh` (after-compinit hooks), `install.sh` (idempotent installer), `*.symlink` files, `README.md`.
3. No central registration needed — zsh loader, `script/bootstrap`, and `script/install` discover it automatically.
4. If installable, make `install.sh` idempotent and platform-aware (guard with `uname` / `command -v`).

**New skill (own-authored):**
- `mkdir agents/my-skills/<skill-name>` and add `SKILL.md` (plus any `scripts/`, `reference.md`).
- Run `dot --sync` to symlink it into `agents/skills/<skill-name>`.

**New external skill:**
- `skills install <source>/<name>` — the install is recorded in `agents/skills/.skill-lock.json` (tracked) but the files themselves are gitignored.

**New topic installer:**
- Create `<topic>/install.sh`; `chmod +x`; check dependencies exist before installing; `exit 0` on non-applicable platforms. Example: `ruby/install.sh`, `homebrew/install.sh`, `macos/install.sh`.

## Special Directories

**`agents/skills/`:**
- Purpose: Runtime skills directory consumed by AI CLIs (symlinked to `~/.cursor/skills` by `script/bootstrap`).
- Generated: Yes — populated by `link_my_skills` (symlinks own skills from `../my-skills/`) and by `skills install` (external skills).
- Committed: Only `.skill-lock.json` and `README.md`; everything else is gitignored via `agents/skills/*` in `.gitignore`.

**`agents/my-skills/`:**
- Purpose: Source of truth for skills the user authors. `script/bootstrap` mirrors each subdirectory into `agents/skills/` as a symlink.
- Generated: No — manually authored.
- Committed: Yes, fully tracked.

**`.planning/`:**
- Purpose: GSD workflow artifacts. Not consumed by the shell, the `dot` CLI, or bootstrap.
- Generated: Partly — populated by GSD commands and codebase-mapping skills.
- Committed: Tracked.

**Repo-level `*.symlink` discovery:**
- `script/bootstrap` searches `find -H "$DOTFILES_ROOT" -maxdepth 2 -name '*.symlink'`. That means symlink files must live at depth 1 or 2 (i.e. `<topic>/<name>.symlink`), never deeper.

**`bin/`:**
- Purpose: Everything here is automatically on `$PATH` via `system/_path.zsh` (`$ZSH/bin`) — no registration required.
- Generated: No.
- Committed: Yes (executables tracked directly).

**`.vscode/`:**
- Purpose: Workspace editor settings.
- Generated: No.
- Committed: Tracked.

---

*Structure analysis: 2026-04-22*
