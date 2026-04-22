# Codebase Concerns

**Analysis Date:** 2026-04-22

## Tech Debt

**Broken `dot --start` flag:**
- Issue: `bin/dot` line 74 calls `"$0" --dotfiles`, which is not a valid option. The valid flag is `-s|--sync`. Running `dot --start` will hit the `*)` default case, print `Invalid option: --dotfiles`, and exit before install/brew/macos run.
- Files: `bin/dot`
- Impact: The advertised "complete new laptop setup" command (`dot --start` / `dot -S`) is broken. A fresh machine setup via `dot --start` aborts on the first sub-command. `AGENTS.md` still documents this command as the recommended new-laptop flow.
- Fix approach: Replace `"$0" --dotfiles` with `"$0" --sync` on `bin/dot:74`.

**Installer runner ignores shebangs:**
- Issue: `script/install` runs every `install.sh` via `sh -c "${installer}"`, forcing POSIX `sh` regardless of the file's shebang. `homebrew/brew.sh` (not run by this entry point, but the project convention is shebang-based) uses `#!/usr/bin/env bash` while `homebrew/install.sh` uses `#!/bin/sh`. On macOS where `/bin/sh` is effectively dash-like bash in POSIX mode, any future bashism in an `install.sh` would silently misbehave.
- Files: `script/install`
- Impact: Future install scripts that rely on bash features ( `[[`, arrays, `local`, etc.) will fail confusingly.
- Fix approach: Change the loop to `find . -name install.sh -exec {} \;` so scripts execute with their own shebang.

**`homebrew/install.sh` and `homebrew/brew.sh` have no error handling:**
- Issue: Neither script sets `set -e` or checks command exit codes. Any single `brew install` failure (network blip, tap removal, renamed cask) is swallowed and the script continues, leaving a partially installed system.
- Files: `homebrew/install.sh`, `homebrew/brew.sh`
- Impact: Silent failure — user believes setup succeeded but packages are missing. Especially risky on first-run `dot --brew` / `dot --start`.
- Fix approach: Add `set -e` (or explicit status checks) and surface failures loudly.

**`homebrew/brew.sh` hardcodes Intel `/usr/local` paths:**
- Issue: Line 20 runs `sudo ln -s /usr/local/bin/gsha256sum /usr/local/bin/sha256sum`. On Apple Silicon Homebrew lives at `/opt/homebrew`, so this symlink either fails (no source file) or points at nothing useful. The `brew.sh` comment elsewhere also references `/usr/local/bin/bash` (`/etc/shells` note on line 29) which is similarly Intel-only.
- Files: `homebrew/brew.sh`
- Impact: New Apple Silicon machines will hit `ln: /usr/local/bin/gsha256sum: No such file or directory`, and because `set -e` is not set, this error is silently swallowed.
- Fix approach: Use `$(brew --prefix)/bin/gsha256sum` and `$(brew --prefix)/bin/bash`. Also guard with a check that the source file exists.

**`ruby/install.sh` has no shebang:**
- Issue: The file is two `if` blocks with no `#!` line.
- Files: `ruby/install.sh`
- Impact: Works because `script/install` force-runs everything under `sh -c`, but the file is not independently executable with its own interpreter. Any future feature requiring bash will break.
- Fix approach: Add `#!/usr/bin/env bash` (or `/bin/sh`) and `set -e`.

**Deleted `opencode/oh-my-opencode.w-claude.json` still referenced:**
- Issue: `git status` shows this file as deleted but not staged. If any tooling, documentation, or script references it, the reference is now dangling. `opencode/oh-my-opencode.w-ollama.jsonc` still exists as a peer and suggests there was a `w-<provider>` convention that has been partially abandoned.
- Files: Deletion pending for `opencode/oh-my-opencode.w-claude.json`; peer `opencode/oh-my-opencode.w-ollama.jsonc` still tracked.
- Impact: Inconsistent set of provider-specific variants; unclear which are canonical.
- Fix approach: Either restore the file, commit the deletion and drop `w-ollama.jsonc` too, or decide on a single naming scheme (see next item).

**Overlapping opencode config naming schemes:**
- Issue: `opencode/` now contains two parallel variant systems:
  - `oh-my-opencode.w-ollama.jsonc` / (deleted) `oh-my-opencode.w-claude.json` — per-provider variants
  - `oh-my-opencode.token-high.json` / `token-mid.json` / `token-low.json` — per-token-budget variants (untracked)
  - `opencode.ollama.json` (tracked), `opencode.omo.json` (untracked), `opencode.json` (tracked)
- Files: `opencode/oh-my-opencode.json`, `opencode/oh-my-opencode.w-ollama.jsonc`, `opencode/oh-my-opencode.token-{high,mid,low}.json`, `opencode/opencode.json`, `opencode/opencode.ollama.json`, `opencode/opencode.omo.json`
- Impact: Two naming conventions coexist without documentation. Only `opencode/scripts/link-config.sh` (which symlinks `opencode.json` and `oh-my-opencode.json`) knows the canonical pair. New readers cannot tell which variants are active, archived, or experimental.
- Fix approach: Pick one axis (provider OR token tier), delete the other, or move archived variants to a sub-folder like `opencode/profiles/`.

**`omod()` writes `.backup.<timestamp>` files into a tracked directory:**
- Issue: The new `omod` function in `opencode/aliases.zsh` (lines 37–39) copies the current `oh-my-opencode.json` to `oh-my-opencode.json.backup.$(date +%Y%m%d_%H%M%S)` inside `$DOTFILES/opencode/`. The working tree already has one stranded backup: `opencode/oh-my-opencode.json.backup.20260411_140707`.
- Files: `opencode/aliases.zsh`, `opencode/oh-my-opencode.json.backup.20260411_140707`
- Impact: Each profile switch adds another untracked backup file that clutters `git status` and leaks into `find` results. No cleanup mechanism exists. These will eventually be committed by accident.
- Fix approach: Add `opencode/*.backup.*` to `.gitignore`, write backups to `/tmp` or `$XDG_STATE_HOME`, or rotate (keep last N).

**`link-config.sh` is a no-op on re-run (not idempotent in a useful way):**
- Issue: `opencode/scripts/link-config.sh` skips symlink creation if a target `[ -e ] || [ -L ]` already exists, even when the existing link points somewhere else. Changing sources in this repo does not update `~/.config/opencode/`.
- Files: `opencode/scripts/link-config.sh`
- Impact: Silent divergence between dotfiles repo and live config directory after the first install.
- Fix approach: Check `readlink -f` matches `$src`; if not, warn or replace the link with a `-f` flag and user confirmation.

**`bin/dot` is a POSIX `sh` script that calls `bash`-oriented tooling:**
- Issue: Shebang is `#!/bin/sh` but the script is invoked from `script/bootstrap` (which uses bash-only constructs) and calls back into bash-shebanged sub-scripts. Mixed interpreter assumptions across the entry points.
- Files: `bin/dot`, `script/bootstrap`
- Impact: Works today, but any future `[[`, array, or `${var^^}` usage in `bin/dot` will silently fail on dash-like shells.
- Fix approach: Standardize on `#!/usr/bin/env bash` across `bin/dot`, `script/install`, and `script/bootstrap`.

## Known Bugs

**Stale/broken symlink for deleted skill:**
- Symptoms: `agents/skills/enable-ollama-in-cursor` is a symlink pointing at `/Users/stratbarrett/.dotfiles/agents/my-skills/enable-ollama-in-cursor/`, but that target directory is deleted (uncommitted deletion in git).
- Files: `agents/skills/enable-ollama-in-cursor` (symlink), `agents/my-skills/enable-ollama-in-cursor/` (deleted).
- Trigger: `ls -L agents/skills/enable-ollama-in-cursor` fails; any CLI enumerating `agents/skills/` (and therefore `~/.cursor/skills/` and `~/.agents/skills/` via the bootstrap symlinks) will see a broken entry.
- Workaround: `rm agents/skills/enable-ollama-in-cursor` and commit, then `dot --sync` to regenerate.

**`script/bootstrap` `link_file` prompts can produce unexpected actions:**
- Symptoms: In `script/bootstrap:74–93`, reading a single character for the prompt uses `read -n 1 action` with a `case` that has a wildcard `*) ;;` fall-through. If the user hits Enter or an unrecognized key, `overwrite/backup/skip` remain unset, and the final branch `if [ "$skip" != "true" ]` (line 121) proceeds to run `ln -s "$1" "$2"` on top of an existing file, which fails with `File exists`.
- Files: `script/bootstrap`
- Trigger: Any invalid keystroke at the conflict prompt on a second run.
- Workaround: Re-run with a clean `$HOME`, or answer exactly one of `sSoObB`.

**`bin/dot -n` is macOS-specific without OS check:**
- Symptoms: `bin/dot:45` runs `open -a iterm .`, which is Darwin-only (`open`) and iTerm-specific.
- Files: `bin/dot`
- Trigger: Running `dot -n` on Linux.
- Workaround: Don't use `-n` on non-mac systems.

**`script/bootstrap` `cd` without quotes:**
- Symptoms: `script/bootstrap:5` uses `cd "$(dirname "$0")/.."` which is fine, but inside `link_file` the `readlink $dst` on line 65 is unquoted. A `$HOME` with spaces will break pathing.
- Files: `script/bootstrap:65`
- Trigger: Bootstrap run under a username/home containing whitespace.
- Workaround: None needed on the current machine; keep usernames simple.

## Security Considerations

**Secrets convention relies on user discipline, not enforcement:**
- Risk: The project's secret-handling story is "stash env vars in `~/.localrc`" (documented in `zsh/zshrc.symlink:14-19`, `AGENTS.md`). Nothing in `script/bootstrap`, `script/install`, or the `.gitignore` prevents a user from dropping an `install.sh` or `.zsh` file with inlined secrets into a topic directory.
- Files: `.gitignore` (only ignores `*.local.symlink`, `*.local.zsh`, `*.env`, `*.venv`), `zsh/zshrc.symlink`
- Current mitigation: `.gitignore` excludes `*.env` and `*.local.*` patterns. `~/.localrc` is never tracked because it lives in `$HOME`, not in the repo.
- Recommendations:
  - Add a pre-commit hook (e.g., `gitleaks` or `ggshield`) to block secret pushes.
  - Expand `.gitignore` to include common secret filenames (`.npmrc`, `credentials.*`, `*.pem`, `*.key`).
  - Document the secrets policy explicitly in `README.md` (currently only in `AGENTS.md` and `zshrc.symlink` comment).

**`opencode/ollama.zsh` binds Ollama to `0.0.0.0:11434` with `OLLAMA_ORIGINS='*'`:**
- Risk: `opencode/ollama.zsh:4-5` exports `OLLAMA_HOST=0.0.0.0:11434` and `OLLAMA_ORIGINS='*'`. This makes the Ollama server reachable from any network interface, with CORS open to every origin.
- Files: `opencode/ollama.zsh`
- Current mitigation: None; these exports are loaded by every zsh shell via the topical `*.zsh` autoload in `zsh/zshrc.symlink`.
- Recommendations: Default to `127.0.0.1:11434` and scope `OLLAMA_ORIGINS` to specific hostnames (e.g., `http://localhost:*,https://*.ngrok.app`). The companion `opencode/scripts/ollama-start.sh:55` already defaults to `127.0.0.1:11434`, so the wider binding in `ollama.zsh` overrides it unintentionally.

**`homebrew/brew.sh` runs `sudo -v` plus a background sudo-keepalive loop:**
- Risk: Lines 6–9 of `homebrew/brew.sh` spawn an unkillable-looking background loop that re-validates sudo every 60 seconds. If the parent fails/crashes before `kill -0 "$$"` returns false, there's a short window where sudo is still cached.
- Files: `homebrew/brew.sh`
- Current mitigation: `kill -0 "$$" || exit` in the loop.
- Recommendations: Consider running Homebrew installs in a subshell and explicitly `sudo -k` on exit.

**Hardcoded absolute path to user's home in tracked files:**
- Risk: `zsh/zshrc.symlink:59` and `claude/alias.zsh:1` both contain hardcoded `/Users/stratbarrett/.claude/plugins/...` paths pointing at versioned plugin directories (`12.1.6` and `thedotmack/plugin` respectively). These paths differ between the two files — one points at `plugins/cache/thedotmack/claude-mem/12.1.6` and the other at `plugins/marketplaces/thedotmack/plugin`.
- Files: `zsh/zshrc.symlink:59`, `claude/alias.zsh:1`
- Current mitigation: None.
- Recommendations:
  - Replace `/Users/stratbarrett` with `$HOME`.
  - Two different paths define the same alias `claude-mem` — one will silently shadow the other depending on load order. Deduplicate.
  - Avoid hardcoding a specific plugin version (`12.1.6`) in checked-in config; use a version-agnostic shim.

## Performance Bottlenecks

**zsh startup loads every `*.zsh` recursively:**
- Problem: `zsh/zshrc.symlink:22-48` globs `$ZSH/**/*.zsh` (Zsh extended glob) and sources every file in three passes. With ~10+ topic directories each contributing multiple `.zsh` files, plus evaluations like `eval "$(uv generate-shell-completion zsh)"` in `python/uv.zsh:5` and completion files in `git/completion.zsh` (66 lines), each shell startup pays the full cost every time.
- Files: `zsh/zshrc.symlink`, `python/uv.zsh`, `git/completion.zsh`, `node/completion.zsh`, `node/nvm.zsh`, `mise/dev.zsh`
- Cause: No caching layer (`zcompdump` only caches completion metadata, not `eval` output). `nvm.sh` is particularly heavy.
- Improvement path: Cache `uv generate-shell-completion zsh` output to a file and source it. Lazy-load `nvm` (only load on first `nvm`/`node`/`npm` invocation). Consider `zinit turbo` or similar plugin manager if load time becomes problematic.

**`nvm` eagerly loaded on every shell:**
- Problem: `node/nvm.zsh:13` sources `$NVM_DIR/nvm.sh` unconditionally. Upstream `nvm` is notorious for adding 300–800ms to shell startup.
- Files: `node/nvm.zsh`
- Cause: No lazy-load wrapper.
- Improvement path: Replace with a lazy-load function that sources `nvm.sh` on first `nvm`/`node`/`npm`/`npx` call. Or migrate fully to `mise` (already in this repo, see next item) and delete `node/nvm.zsh`.

## Fragile Areas

**Two competing Node version managers (`nvm` and `mise`):**
- Files: `node/nvm.zsh`, `mise/dev.zsh`, `mise.toml`, `mise/dev.config.json`
- Why fragile: `homebrew/brew.sh` installs both `mise` and implicitly assumes `nvm` is already there. `node/nvm.zsh` sources nvm on every shell. `mise` is also activated (via `~/.dev/hack/zshrc.sh` which `mise/dev.zsh` sources). When both are active, the shim that wins for `node` is order-dependent and can flip between shells, causing confusing "wrong Node version" bugs.
- Safe modification: Decide on one manager. `mise` is newer and unified; `README.md` files suggest the project is migrating toward it.
- Test coverage: None — this is shell config; there's no automated verification.

**`agents/my-skills/` ↔ `agents/skills/` drift:**
- Files: `agents/my-skills/*`, `agents/skills/*` (symlinks), `script/bootstrap:157-170`
- Why fragile: `link_my_skills()` creates the symlinks but never removes stale ones. When a skill is deleted from `my-skills/` (as `enable-ollama-in-cursor` was), the symlink remains in `skills/` and becomes broken. The `.gitignore` rule `agents/skills/*` hides these broken symlinks from git but not from runtime consumers (`~/.cursor/skills/`, `~/.agents/skills/`).
- Safe modification: Add a cleanup step to `link_my_skills()` that removes symlinks under `agents/skills/` whose target no longer exists.
- Test coverage: None.

**`.skill-lock.json` is manually edited and tracked, but installed skills are not:**
- Files: `agents/.skill-lock.json`, `agents/skills/*`
- Why fragile: The lock file records externally-installed skills with a `skillFolderHash`, but the actual skill content is gitignored. Restoring a machine requires running `skills experimental_install`, which depends on the external CLI being installed and all upstream repos still hosting the exact hashed commit. If an upstream repo is deleted or the commit is force-pushed, restoration silently skips that skill.
- Safe modification: Document the restore path explicitly; add a `skills verify` step to `script/bootstrap` that flags missing skills.
- Test coverage: None.

**`script/bootstrap` has no dry-run mode:**
- Files: `script/bootstrap`
- Why fragile: The only way to know what the script will do is to run it and answer prompts interactively. There is no `--dry-run` / `--yes` flag. Combined with the wildcard prompt fall-through, a run on a pre-populated `$HOME` can produce unexpected symlink-creation failures.
- Safe modification: Add a `DRY_RUN=1` env var that logs intended actions without making filesystem changes.
- Test coverage: None.

## Scaling Limits

**`script/bootstrap` uses `find -H ... -maxdepth 2 -name '*.symlink'`:**
- Current capacity: Only files at depth 2 (e.g., `git/gitconfig.symlink`) are linked into `$HOME`. Depth 3+ (`git/templates/something.symlink`) is silently ignored.
- Limit: Any topic that needs nested `.symlink` files will not be linked.
- Scaling path: Increase `-maxdepth` or drop it, document the convention explicitly.

## Dependencies at Risk

**`withgraphite/tap/graphite` (`gt`) cask:**
- Risk: Third-party Homebrew tap. Taps can be removed/renamed; if `withgraphite` takes down the tap, `dot --brew` on a fresh machine fails silently (no `set -e`).
- Impact: Missing `gt` CLI; user-defined git workflow may depend on it.
- Migration plan: Pin to a specific formula source or fall back to `npm install -g @withgraphite/graphite-cli` if the brew tap is unavailable.

**`brew install --cask readdle-spark`:**
- Risk: Readdle discontinued the free/desktop version of Spark in favor of "Spark Mail — Spark+". The cask may be renamed, archived, or removed from `homebrew/cask`.
- Impact: `homebrew/brew.sh:66` fails if the cask is gone.
- Migration plan: Remove or replace with current cask name (verify via `brew search spark`).

**`brew install --cask notion-calendar`:**
- Risk: Cron → Notion Calendar → rebranded repeatedly. Cask names have churned.
- Impact: Same as above.
- Migration plan: Verify current cask name on each `brew.sh` run; consider pinning to a Brewfile with version constraints.

**`bash-completion2`, `dark-mode`, `git-completion` in `homebrew/brew.sh`:**
- Risk: These are legacy-ish formulae. `bash-completion2` has been partially superseded by `bash-completion@2`; `dark-mode` is a macOS CLI that has been deprecated several times.
- Impact: Installs may fail or install superseded packages silently.
- Migration plan: Audit `homebrew/brew.sh` against `brew info <formula>` to verify each package is still the canonical name.

## Missing Critical Features

**No automated verification that bootstrap succeeded:**
- Problem: Neither `script/bootstrap` nor `bin/dot --sync` verifies the resulting state. There is no `dot --doctor` or health-check command.
- Blocks: Confident detection of partial installs, drift after macOS updates, or stale symlinks.

**No changelog / migration notes for breaking dotfiles changes:**
- Problem: When a topic is removed (e.g., `enable-ollama-in-cursor`) or renamed, there is no record of the change for other machines syncing.
- Blocks: Multi-machine consistency; recovery after a partial sync.

**No Linux-equivalent install path despite `AGENTS.md` claiming Linux support:**
- Problem: `AGENTS.md` states "Primary macOS, Linux support", but `script/bootstrap:178` wraps ALL `bin/dot` invocations (i.e., `--install` and `--brew`) in `if [ "$(uname -s)" == "Darwin" ]`, meaning Linux users get symlinks only — no package installation. `homebrew/install.sh` does branch on Linux but then `brew.sh` uses `/usr/local` paths that don't match Linuxbrew's `/home/linuxbrew/.linuxbrew`.
- Blocks: Any claim of cross-platform support.

## Test Coverage Gaps

**Zero automated tests:**
- What's not tested: The entire repo. There are no shell-script tests (`bats`, `shunit2`), no CI workflow (no `.github/workflows/`), no linters configured (no `.shellcheckrc`).
- Files: Entire repo.
- Risk: Every change is verified only by running it on the author's machine. Regressions in `script/bootstrap`, `bin/dot`, or any `install.sh` can ship undetected until a new-laptop setup.
- Priority: Medium (personal dotfiles), but the bugs above (`dot --start` broken for months, stale symlinks, /usr/local hardcoding) would all have been caught by a minimal smoke test.

**No `shellcheck` in the workflow:**
- What's not tested: `script/bootstrap`, `bin/dot`, every `install.sh`, every `.zsh` file.
- Files: All shell files.
- Risk: Quoting bugs, unset-variable bugs, `set -e` inconsistencies all silently ship.
- Priority: Low–Medium. Adding `shellcheck` as a pre-commit hook is a 10-minute win.

**No integration check for bootstrap's symlink set:**
- What's not tested: Whether every `.symlink` file under `-maxdepth 2` actually ends up linked into `$HOME`, and whether the link target still resolves.
- Files: Output of `find -H $DOTFILES -maxdepth 2 -name '*.symlink'`.
- Risk: Silent partial installs.
- Priority: Medium. A simple `verify-links.sh` walking the same `find` and running `test -e` on each destination would close this gap.

## Uncommitted / Untracked File Inventory (2026-04-22 snapshot)

| Path | State | Concern |
|------|-------|---------|
| `agents/.skill-lock.json` | Modified | Adds `tailwind-theme-builder`, `claude-code`, `cline`. Safe to commit. |
| `agents/my-skills/enable-ollama-in-cursor/` | Deleted, uncommitted | Leaves broken symlink `agents/skills/enable-ollama-in-cursor`. Commit deletion and clean up symlink. |
| `claude/` (new) | Untracked | Contains `CLAUDE.md` (155 lines, agent behavioral profile) and `alias.zsh` (1 line, hardcoded path). Decide whether to track; fix hardcoded path first. |
| `opencode/aliases.zsh` | Modified | Adds `omod()` function that writes backup files into tracked directory. |
| `opencode/oh-my-opencode.json` | Modified | Switches default agents from `kimi-k2.5` to Claude / GPT / Gemini variants. |
| `opencode/oh-my-opencode.json.backup.20260411_140707` | Untracked | Stranded backup from `omod()`. Add to `.gitignore`. |
| `opencode/oh-my-opencode.token-{high,mid,low}.json` | Untracked | New per-token-budget profiles. Intended as source-of-truth for `omod()` — should be tracked. |
| `opencode/oh-my-opencode.w-claude.json` | Deleted, uncommitted | Part of old `w-<provider>` scheme. |
| `opencode/ollama.zsh` | Untracked | Sets `OLLAMA_HOST=0.0.0.0` globally; see Security note above. |
| `opencode/opencode.json` | Modified | Drops `oh-my-opencode@3.11.1` plugin reference and switches default model. |
| `opencode/opencode.omo.json` | Untracked | Companion to `opencode.ollama.json` (tracked) — track or delete for consistency. |
| `zsh/zshrc.symlink` | Modified | Appends `claude-mem` alias with hardcoded `/Users/stratbarrett/` path and specific plugin version. |

---

*Concerns audit: 2026-04-22*
