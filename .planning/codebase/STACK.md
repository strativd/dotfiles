# Technology Stack

**Analysis Date:** 2026-04-22

## Languages

**Primary:**
- Shell (Zsh) - All runtime configuration, aliases, functions, and prompt logic across `zsh/`, `system/`, and every `*/*.zsh` topic file
- Shell (Bash/POSIX sh) - Installer and management scripts (`script/bootstrap`, `script/install`, `bin/dot`, `homebrew/install.sh`, `homebrew/brew.sh`, `opencode/scripts/ollama-start.sh`)

**Secondary:**
- Ruby - Present as a supported topic (`ruby/`, `ruby/frum.zsh`, `ruby/install.sh`) with `irbrc.symlink` and `gemrc.symlink` linked into `$HOME`
- Python - Declared in `mise.toml` (`python = "latest"`) and managed via `uv` in `python/uv.zsh`
- Vimscript - `vim/vimrc.symlink` and color schemes under `vim/colors/`
- JSON / JSONC - Agent and opencode configuration (`opencode/opencode.json`, `opencode/oh-my-opencode*.json`, `mise/dev.config.json`, `agents/.skill-lock.json`)
- TOML - `mise.toml` at repo root
- Markdown - Documentation (`README.md`, `AGENTS.md`, topical `README.md` files, agent skills under `agents/my-skills/*/SKILL.md`, agent commands under `agents/commands/*.md`)
- Git config - `git/gitconfig.symlink`, `git/gitignore.symlink`

## Runtime

**Environment:**
- macOS (primary target; checked via `uname -s == "Darwin"` in `script/bootstrap`, `homebrew/brew.sh`, `macos/install.sh`)
- Linux (secondary; Linuxbrew branch in `homebrew/install.sh`)
- Zsh (interactive shell; bootstrap entry point is `zsh/zshrc.symlink` linked to `~/.zshrc`)

**Shell loader:**
- `zsh/zshrc.symlink` auto-sources every `**/*.zsh` file in `$ZSH` (`$DOTFILES`)
- Load order: `*/path.zsh` first, then all other `*.zsh`, then `compinit`, then `*/completion.zsh`

**Package / version managers:**
- Homebrew (macOS package manager) - PATH exported in `homebrew/path.zsh` as `/opt/homebrew/bin`
- `mise` - Polyglot runtime manager, installed via Homebrew, configured at repo root `mise.toml` and `mise/dev.config.json`; activation helpers in `mise/aliases.zsh` (`miseon` / `miseoff`)
- `nvm` - Node version manager; bootstrapped from `$HOME/.nvm` in `node/nvm.zsh`
- `uv` - Python / project manager (Astral); completion wired in `python/uv.zsh`
- `frum` - Ruby version manager; init in `ruby/frum.zsh`, installed in `ruby/install.sh`
- `pnpm` - Node package manager; PATH setup in `node/pnpm.zsh` (`$HOME/Library/pnpm`)
- Yarn - Referenced in `yarn/path.zsh` and used by `jest/jester.zsh`

## Frameworks

**Core:**
- No application framework - This is a dotfiles / shell configuration repo

**Testing:**
- Jest (indirect) - Shell wrapper `jest/jester.zsh` invokes `yarn jest [...]` with coverage flags; no tests exist inside this repo

**Build/Dev:**
- Custom `bin/dot` script - Primary orchestrator for bootstrap, install, brew, macos, reload, edit flows
- `script/bootstrap` - Symlinks every `*.symlink` file into `$HOME/.*` and links `agents/` → `~/.agents` and `~/.cursor/{skills,prompts,commands}`
- `script/install` - Runs every `*/install.sh` across topic directories
- `editor/editorconfig.symlink` - UTF-8, LF, 2-space indent, trim trailing whitespace, final newline

## Key Dependencies

**Critical CLI tools (installed via `homebrew/brew.sh`):**
- `git` - VCS; extensively customized in `git/gitconfig.symlink`
- `git-completion` - Zsh completion for git
- `withgraphite/tap/graphite` - Graphite CLI (`gt`); the `bin/g` wrapper routes between `gt` and `git`
- `gh` - GitHub CLI; used as git credential helper in `git/gitconfig.symlink` (`!/opt/homebrew/bin/gh auth git-credential`)
- `mise` - Version manager
- `pnpm`, `yarn`, `uv` - Package managers for Node and Python
- `opencode` - Local AI coding assistant CLI
- `ollama` - Local LLM runtime
- `ast-grep` - Structural code search
- `fzf` - Fuzzy finder (used by `git/worktree.zsh`)
- `bat`, `tree`, `dark-mode` - Terminal utilities
- `coreutils`, `moreutils`, `findutils`, `gnu-sed`, `bash`, `bash-completion2` - GNU tool replacements

**Installed via `mise` (from `mise/dev.config.json` `miseGlobalConfig.tools`):**
- `sops`, `age`, `bun`, `rust`, `aws-cli`, `fd`, `fzf`, `gcloud`, `go`, `golangci-lint`, `jq`, `node` (latest + lts), `python` (3.12 + latest), `ruby`, `terraform`, `terragrunt`, `uv`

**Cask apps (macOS GUI) - installed via `homebrew/brew.sh`:**
- `raycast`, `iterm2`, `cursor`, `visual-studio-code`, `google-chrome`, `brave-browser`, `slack`, `spotify`, `readdle-spark`, `notion`, `notion-calendar`, `google-drive`

**Bundled shell utilities (`bin/`, 34 executables):**
- `dot` - Main management script
- `g` - Smart git/graphite wrapper invoked by `zsh/aliases.zsh`
- Git helpers: `git-amend`, `git-checkout-main-branch`, `git-cob`, `git-copy-branch-name`, `git-cow`, `git-credit`, `git-delete-local-merged`, `git-edit-new`, `git-nuke`, `git-promote`, `git-rank-contributors`, `git-track`, `git-undo`, `git-unpushed`, `git-unpushed-stat`, `git-up`, `git-wtf`, `git-all`
- System helpers: `battery-status`, `cloudapp`, `dns-flush`, `headers`, `movieme`, `mustacheme`, `res`, `search`, `set-defaults`, `todo`, `yt`, `gitio`

**Infrastructure:**
- `bun` - Referenced by `zsh/zshrc.symlink` line 59 to run `claude-mem` worker script at `/Users/stratbarrett/.claude/plugins/cache/thedotmack/claude-mem/12.1.6/scripts/worker-service.cjs` (also aliased in `claude/alias.zsh`)

## Configuration

**Environment:**
- `DOTFILES` / `ZSH` - Dotfiles root; set in `zsh/zshrc.symlink` to `$HOME/.dotfiles` (or `$HOME/src/github.com/strativd/dotfiles` when present)
- `PROJECTS=~/Code` - Project folder for `c` completion (`zsh/zshrc.symlink`)
- `EDITOR=cursor` - Set in `system/env.zsh`
- `NVM_DIR=$HOME/.nvm` - `node/nvm.zsh`
- `PNPM_HOME=$HOME/Library/pnpm` - `node/pnpm.zsh`
- `HISTFILE=~/.zsh_history`, `HISTSIZE=10000`, `SAVEHIST=10000` - `zsh/config.zsh`
- `LSCOLORS`, `CLICOLOR=true` - `zsh/config.zsh`
- Ollama env: `OLLAMA_ORIGINS=*`, `OLLAMA_HOST=0.0.0.0:11434`, `OLLAMA_NUM_PARALLEL=1`, `OLLAMA_MAX_LOADED_MODELS=1`, `OLLAMA_NUM_GPU=1` - `opencode/ollama.zsh`
- `OLLAMA_CURSOR_MODEL="gemma4:26b"` - `opencode/ollama.zsh`

**Local / secret config (gitignored via `.gitignore`):**
- `*.local.symlink`, `*.local.zsh` - Machine-specific overrides
- `*.env`, `*.venv` - Environment / virtualenv files
- `~/.localrc` - Sourced by `zsh/zshrc.symlink` if present (not tracked)
- `git/gitconfig.local.symlink` - Generated interactively by `script/bootstrap` from `git/gitconfig.local.symlink.example`
- `agents/skills/*` - Externally installed skills are gitignored; only `agents/.skill-lock.json` and `agents/skills/README.md` are tracked

**Build / shell config files:**
- `mise.toml` (repo root) - Declares `python = "latest"`
- `mise/dev.config.json` - Bai dev CLI config with `miseGlobalConfig` tool list
- `editor/editorconfig.symlink` → `~/.editorconfig`
- `zsh/inputrc.symlink` → `~/.inputrc`
- `zsh/zshrc.symlink` → `~/.zshrc`
- `vim/vimrc.symlink` → `~/.vimrc`
- `tmux/tmux.conf.symlink` → `~/.tmux.conf`
- `git/gitconfig.symlink` → `~/.gitconfig`
- `git/gitignore.symlink` → `~/.gitignore`
- `node/nvmrc.symlink` → `~/.nvmrc` (contents: `24`)
- `ruby/irbrc.symlink`, `ruby/gemrc.symlink`

**AI / agent configuration:**
- `opencode/opencode.json` - Main opencode config (model `opencode/claude-sonnet-4-6`, small model `opencode/kimi-k2.5`, tools read/edit/write/bash enabled)
- `opencode/opencode.omo.json` - oh-my-opencode variant (model `moonshotai/kimi-k2.5`, plugin `oh-my-opencode@3.11.1`)
- `opencode/opencode.ollama.json` - Ollama-backed variant
- `opencode/oh-my-opencode.json` + `.token-high.json` / `.token-mid.json` / `.token-low.json` - Token-tier agent routing profiles; switched via `omod` function in `opencode/aliases.zsh`
- `claude/CLAUDE.md` - Claude behavioural instructions (not a symlink)
- `claude/alias.zsh` - `claude-mem` alias pointing at cached plugin worker
- `agents/.skill-lock.json` - Tracked lockfile listing externally installed skills (test-coverage, find-skills, playwright-cli, deslop, react-useeffect, tailwind-theme-builder)
- `agents/my-skills/` - Own authored skills: `add-agents-file`, `enable-ollama`, `prompt-optimizer`, `refactor-with-a-kiss`

## Platform Requirements

**Development:**
- macOS (Apple Silicon targeted; `homebrew/path.zsh` hardcodes `/opt/homebrew/bin`)
- Zsh 5+ with `compinit` available
- Network access for Homebrew, `nvm`, `uv`, and AI model downloads
- 32GB+ RAM recommended for local Ollama models (per `opencode/README.md`)

**Production:**
- Not applicable - This repo configures a developer workstation, not a deployed service

---

*Stack analysis: 2026-04-22*
