# External Integrations

**Analysis Date:** 2026-04-22

## APIs & External Services

**Package & Runtime Managers:**
- Homebrew - macOS package manager, installed by `homebrew/install.sh` via `curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh`; Linuxbrew fallback for Linux
  - PATH: `homebrew/path.zsh` exports `/opt/homebrew/bin`
  - Package list: `homebrew/brew.sh`
  - Managed by `bin/dot --brew` and `dot --start`
- `mise` (jdx/mise) - Polyglot runtime manager; installed via Homebrew, configured at `mise.toml` and `mise/dev.config.json`
  - Activation aliases: `mise/aliases.zsh` (`miseon=mise activate zsh`, `miseoff=mise deactivate`)
- `nvm` (nvm-sh/nvm) - Node.js version manager loaded from `$HOME/.nvm` in `node/nvm.zsh`
- `uv` (astral-sh/uv) - Python package/project manager; completion sourced in `python/uv.zsh`
- `frum` (TaKO8Ki/frum) - Rust-based Ruby version manager; `ruby/frum.zsh` runs `eval "$(frum init)"`
- `pnpm` - Node package manager; PATH wired in `node/pnpm.zsh` with `PNPM_HOME=$HOME/Library/pnpm`
- `yarn` - Node package manager; stub directory `yarn/path.zsh`, consumed by `jest/jester.zsh`

**AI Coding Assistants (multi-provider):**
- OpenCode (opencode.ai) - Local/cloud AI coding CLI
  - Config: `opencode/opencode.json` (default model `opencode/claude-sonnet-4-6`, small `opencode/kimi-k2.5`)
  - Alt configs: `opencode/opencode.omo.json`, `opencode/opencode.ollama.json`
  - Schema reference: `https://opencode.ai/config.json`
  - Config install: `opencode/scripts/link-config.sh`
- oh-my-opencode (code-yeongyu/oh-my-opencode) - Opencode plugin referenced as `plugin: ["oh-my-opencode@3.11.1"]` in `opencode/opencode.omo.json`
  - Token-tier model routing profiles: `opencode/oh-my-opencode.token-high.json`, `.token-mid.json`, `.token-low.json`
  - Profile switcher: `omod` function in `opencode/aliases.zsh`
- Ollama (ollama/ollama) - Local LLM runtime
  - Endpoint: `http://127.0.0.1:11434` (OpenAI-compatible)
  - Env config: `opencode/ollama.zsh` (`OLLAMA_ORIGINS=*`, `OLLAMA_HOST=0.0.0.0:11434`, `OLLAMA_NUM_PARALLEL=1`, `OLLAMA_MAX_LOADED_MODELS=1`, `OLLAMA_NUM_GPU=1`)
  - Start script: `opencode/scripts/ollama-start.sh` (background + warm flags, warmup models `kimi-k2.5:cloud`, `glm-4.7-flash:latest`, `glm-ocr:latest`)
  - Support scripts: `opencode/scripts/ollama-update.sh`, `opencode/scripts/ollama-perf.sh`
  - Aliases (`opencode/aliases.zsh`): `ol`, `olstart`, `olstop`, `olupdate`, `olperf`, `loc`
  - Setup skill: `agents/my-skills/enable-ollama/SKILL.md` (with `reference.md` and `scripts/check-cors.sh`)
- Cloud model providers (referenced by name in opencode configs):
  - Anthropic Claude (via opencode `claude-sonnet-4-6`)
  - Moonshot AI Kimi (`moonshotai/kimi-k2.5`, `kimi-k2.5:cloud`)
  - OpenAI GPT (`opencode/gpt-5-nano`)
  - Z.AI GLM (`glm-4.7:cloud`, `glm-4.7-flash:latest`, `glm-ocr:latest`)
- Claude Code + claude-mem plugin - `claude-mem` alias in `zsh/zshrc.symlink` line 59 and `claude/alias.zsh` runs cached worker at `/Users/stratbarrett/.claude/plugins/cache/thedotmack/claude-mem/12.1.6/scripts/worker-service.cjs` via `bun`
- Cursor IDE (cursor.com) - Primary GUI editor
  - Installed as Homebrew cask
  - `EDITOR=cursor` in `system/env.zsh`
  - Git editor: `editor = cursor -n -w --new-window` in `git/gitconfig.symlink`
  - `script/bootstrap` symlinks `agents/skills` → `~/.cursor/skills`, `agents/prompts` → `~/.cursor/prompts`, `agents/commands` → `~/.cursor/commands`
- GitHub CLI (`gh`) - Used as git credential helper
  - `git/gitconfig.symlink`: `[credential "https://github.com"] helper = !/opt/homebrew/bin/gh auth git-credential` (also for `https://gist.github.com`)
- Graphite CLI (`gt`, withgraphite/tap/graphite)
  - Installed via `homebrew/brew.sh`
  - Invoked through `bin/g` smart wrapper (routes `g` between `gt` and `git` aliases)

## Data Storage

**Databases:**
- None - No database clients or connection strings present

**File Storage:**
- Local filesystem only (`~/.dotfiles`, `~/.agents`, `~/.cursor/*`, `$HOME` symlinks)
- `$HOME/Library/pnpm` - pnpm global install directory
- `$HOME/.nvm` - Node versions
- `/tmp/ollama-serve.log` - Ollama background server log (`opencode/scripts/ollama-start.sh`)

**Caching:**
- Ollama model cache (managed by Ollama daemon, keep-alive controlled via `OLLAMA_KEEP_ALIVE`)
- Homebrew cellar (`/opt/homebrew/Cellar`)

## Authentication & Identity

**Auth Provider:**
- GitHub via `gh auth git-credential` - Configured in `git/gitconfig.symlink` for `github.com` and `gist.github.com`
- macOS Keychain - `script/bootstrap` sets `git_credential='osxkeychain'` on Darwin when generating `git/gitconfig.local.symlink`
- Linux cache helper - Used on non-Darwin systems in `script/bootstrap`

## Monitoring & Observability

**Error Tracking:**
- None

**Logs:**
- Ollama background logs: `/tmp/ollama-serve.log` (created by `opencode/scripts/ollama-start.sh`)
- Zsh history: `~/.zsh_history` (10,000 entries, shared across sessions per `zsh/config.zsh`)

## CI/CD & Deployment

**Hosting:**
- Not applicable - Personal configuration repo; deployment is `script/bootstrap` on a local machine

**CI Pipeline:**
- None detected (no `.github/workflows/`, `.gitlab-ci.yml`, or equivalent)

## Environment Configuration

**Required env vars:**
- `DOTFILES` / `ZSH` - Dotfiles root (set automatically by `zsh/zshrc.symlink`)
- `PROJECTS` - Project directory (default `~/Code`)
- `EDITOR` - Preferred editor (default `cursor` from `system/env.zsh`)
- `NVM_DIR` - Node version manager dir
- `PNPM_HOME` - pnpm dir
- `OLLAMA_HOST`, `OLLAMA_CONTEXT_LENGTH`, `OLLAMA_KEEP_ALIVE`, `OLLAMA_WARMUP_MODELS`, `OLLAMA_ORIGINS`, `OLLAMA_NUM_PARALLEL`, `OLLAMA_MAX_LOADED_MODELS`, `OLLAMA_NUM_GPU`, `OLLAMA_CURSOR_MODEL` - Ollama runtime

**Secrets location:**
- `~/.localrc` - User-specific env vars and secrets, sourced by `zsh/zshrc.symlink` if present (not tracked)
- `git/gitconfig.local.symlink` - Author name / email / credential helper (gitignored via `*.local.symlink` pattern)
- `*.env`, `*.venv` - Gitignored per repo `.gitignore`
- No `.env`, `.npmrc`, or credential files exist in the repo

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- Homebrew install script download: `https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh` (`homebrew/install.sh`)
- Linuxbrew install download: `https://raw.githubusercontent.com/Linuxbrew/install/HEAD/install.sh`
- Ollama HTTP calls: `curl http://127.0.0.1:11434/api/version` (`opencode/scripts/ollama-start.sh`)
- Git URL shortcuts (`git/gitconfig.symlink`): `gh:` → `git@github.com:`, `github:` → `git://github.com/`, `gst:` → `git@gist.github.com:`, `gist:` → `git://gist.github.com/`
- `mise/dev.config.json` fetches config from `https://gist.githubusercontent.com/bai/d5a4a92350e67af8aba1b9db33d5f077/raw/config.json`
- GitHub PR / repo openers - `pr` and `hub` aliases in `git/gitconfig.symlink` invoke `open` on `https://github.com/...` URLs

## Agent & Skill Integrations

**Cursor IDE agent assets** (linked by `script/bootstrap`):
- `~/.cursor/skills` → `agents/skills`
- `~/.cursor/prompts` → `agents/prompts`
- `~/.cursor/commands` → `agents/commands`
- `~/.agents` → `agents/`

**Agent commands** (`agents/commands/`):
- `code-reviewer.md`, `plan-create-prd.md`, `plan-create-tasks.md`

**Own skills** (`agents/my-skills/`, tracked in git, symlinked into `agents/skills/`):
- `add-agents-file`
- `enable-ollama`
- `prompt-optimizer`
- `refactor-with-a-kiss`

**Externally installed skills** (tracked only in `agents/.skill-lock.json`, actual files gitignored; restored via `skills experimental_install`):
- `test-coverage` from `luongnv89/skills`
- `find-skills` from `vercel-labs/skills`
- `playwright-cli` from `microsoft/playwright-cli`
- `deslop` from `cursor/plugins` (cursor-team-kit)
- `react-useeffect` from `softaworks/agent-toolkit`
- `tailwind-theme-builder` from `jezweb/claude-skills`

**Recognized agents** (`lastSelectedAgents` in `agents/.skill-lock.json`):
- amp, cline, codex, cursor, gemini-cli, github-copilot, kimi-cli, opencode, claude-code

---

*Integration audit: 2026-04-22*
