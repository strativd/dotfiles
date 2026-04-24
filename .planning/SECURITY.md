# Repository Security Audit — `~/.dotfiles`

**Audit date:** 2026-04-21
**Scope:** Full repository at `/Users/stratbarrett/.dotfiles` (tracked + untracked files, all documentation, shell scripts, agent configs, opencode/ollama configs, and git history).
**Audit type:** Unconstrained threat scan (no pre-existing PLAN.md threat model). Threat dimensions considered: secret leakage, unsafe shell patterns, symlink/bootstrap hazards, supply chain, AI-agent risks, permissions, network exposure, and git hygiene.
**Auditor stance:** Personal dotfiles repo, public-ish by convention. Single-user macOS. No production workload. Severities are calibrated accordingly.

---

## Summary

| Severity  | Count  |
| --------- | ------ |
| CRITICAL  | 0      |
| HIGH      | 4      |
| MEDIUM    | 9      |
| LOW       | 10     |
| INFO      | 6      |
| **Total** | **29** |

No active secret exposure was found anywhere in the tracked files, untracked files, or git history. The most material risks cluster around **network exposure of local AI services** (Ollama bound to all interfaces with wildcard CORS), **unconstrained AI-agent bash permissions combined with auto-updating remote plugins**, and a **remote-gist-driven tool installer**. Everything else is defense-in-depth or hygiene.

---

## HIGH

### H1. Ollama bound to `0.0.0.0` with wildcard CORS, globally and persistently

- **Severity:** HIGH
- **Location:** `opencode/ollama.zsh` lines `4-5`, `agents/my-skills/enable-ollama/SKILL.md` lines `17-19`, `agents/my-skills/enable-ollama/reference.md` lines `13-15,29-31`, `agents/my-skills/enable-ollama/scripts/check-cors.sh` lines `24`
- **Description:** `opencode/ollama.zsh` unconditionally exports `OLLAMA_HOST=0.0.0.0:11434` and `OLLAMA_ORIGINS='*'` on every zsh startup (loaded via the autoload glob in `zsh/zshrc.symlink:22-36`). Ollama has no authentication layer, so binding to `0.0.0.0` exposes model execution, prompt ingestion, and the full `/v1` OpenAI-compatible endpoint to anyone on the local Wi-Fi/LAN. The `enable-ollama` skill further recommends persisting this via `launchctl setenv OLLAMA_ORIGINS "*"` so the macOS Ollama.app also inherits it.
- **Evidence:**

```1:11:opencode/ollama.zsh
export OLLAMA_CURSOR_MODEL="gemma4:26b"

# Set environment variables for configuration
export OLLAMA_ORIGINS='*'
export OLLAMA_HOST=0.0.0.0:11434
export OLLAMA_NUM_PARALLEL=1
export OLLAMA_MAX_LOADED_MODELS=1
```

The `opencode/scripts/ollama-start.sh:55` default of `127.0.0.1:11434` is overridden by this env export, so merely starting Ollama via `olstart` inherits the wide binding.

- **Impact:** Any device on the same network can read/write prompts, exfiltrate context, and consume GPU budget. Combined with `OLLAMA_ORIGINS='*'` a malicious web page visited from any browser can call the local model (classic CSRF against localhost services).
- **Recommendation:**
  1. Default `OLLAMA_HOST=127.0.0.1:11434` in `opencode/ollama.zsh`. Keep a comment noting how to widen it for specific use cases.
  2. Replace `OLLAMA_ORIGINS='*'` with a narrow allowlist (e.g. `http://localhost,http://127.0.0.1,vscode-webview://*,cursor://*`). Document that browser/ngrok/remote use requires explicit opt-in.
  3. Update `agents/my-skills/enable-ollama/*` to stop recommending the wildcard as the default fix; gate the `launchctl setenv` step behind an explicit "I am exposing this intentionally" confirmation.
- **Effort:** 15 min.

### H2. AI agent configs grant full `bash` + `write` + `autoupdate` to auto-pulled remote plugins

- **Severity:** HIGH
- **Location:** `opencode/opencode.json` lines `5-15`, `opencode/opencode.omo.json` lines `3,5-19`, `opencode/opencode.ollama.json` lines `3,26-31`
- **Description:** Every tracked opencode config sets `"autoupdate": true` and enables `read`, `edit`, `write`, **and** `bash` tools without any command allowlist. `opencode.omo.json` additionally declares `"plugin": ["oh-my-opencode@3.11.1"]` — an auto-updating third-party plugin hosted at `code-yeongyu/oh-my-opencode`. A compromised plugin version (or a supply-chain attack against the upstream) would execute arbitrary shell commands with the user's privileges on next launch.
- **Evidence:**

```1:16:opencode/opencode.json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "opencode/claude-sonnet-4-6",
  "small_model": "opencode/kimi-k2.5",
  "autoupdate": true,
  "compaction": {
    "auto": true,
    "prune": true
  },
  "tools": {
    "read": true,
    "edit": true,
    "write": true,
    "bash": true
  },
```

`opencode/opencode.omo.json:3` — `"plugin": ["oh-my-opencode@3.11.1"]`.

- **Impact:** A malicious model routing prompt, a compromised plugin update, or an LLM provider injecting a crafted tool call can trigger arbitrary shell execution, modification of tracked files, and exfiltration via `bash` calls. `autoupdate: true` means the user cannot review changes before they run.
- **Recommendation:**
  1. Pin plugin versions and disable `autoupdate` (`"autoupdate": false`) until you explicitly update.
  2. Scope `bash` to a command allowlist if opencode supports it (or disable `bash` for default agents that don't need it, e.g. `librarian`, `explore`).
  3. Consider a sandbox wrapper: run opencode under a restricted directory scope (its existing `permission.external_directory` block is a partial step; widen that model to cover `bash`).
- **Effort:** 30 min (pinning + disabling autoupdate); 1-2 hours for a thorough allowlist review.

### H3. `homebrew/install.sh` does `curl | bash` from an unpinned `HEAD` ref

- **Severity:** HIGH
- **Location:** `homebrew/install.sh` lines `16-19`
- **Description:** The Homebrew install fetches the install script from `https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh` (and Linuxbrew equivalent). `HEAD` resolves to the latest commit at download time. There is no SHA pinning, checksum verification, or even reading the output before piping it into a subshell. Homebrew itself is trustworthy, but the pattern establishes a precedent and a dependency on GitHub + DNS + TLS chain being uncompromised at install time.
- **Evidence:**

```13:21:homebrew/install.sh
  if test "$(uname)" = "Darwin"
  then
    $(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)
  elif test "$(expr substr $(uname -s) 1 5)" = "Linux"
  then
    $(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/HEAD/install.sh)
  fi
```

Note the `$( ... )` wrapping: the fetched script body is **substituted as a command**, which is a subtle extra layer beyond the canonical `curl | bash`. If the server ever returns HTML or anything with embedded shell quoting, the failure mode is unpredictable.

- **Impact:** Full shell execution at new-machine bootstrap. Low likelihood (Homebrew is reputable), but a single compromise of the Homebrew install repo on the day you bootstrap a new laptop is unrecoverable.
- **Recommendation:**
  1. Follow Homebrew's documented idiom: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`. The current `$(curl ...)` form is non-standard.
  2. Optionally pin to a specific commit SHA and include a SHA-256 check (Homebrew's install script SHA is tracked and reproducible).
- **Effort:** 10 min for the idiom fix; 20 min for pinning + hash.

### H4. `mise/dev.config.json` fetches config from an external single-user GitHub gist

- **Severity:** HIGH
- **Location:** `mise/dev.config.json` line `2`
- **Description:** The `configUrl` points at `https://gist.githubusercontent.com/bai/d5a4a92350e67af8aba1b9db33d5f077/raw/config.json`. This gist belongs to a single GitHub user (`bai`); it is unversioned (the `raw` URL always serves `HEAD`); and the resulting config drives `mise`, which installs toolchains (`sops`, `age`, `aws-cli`, `terraform`, `gcloud`, etc.) and sets `trusted_config_paths` that bypass `mise` sandboxing. If that account is ever compromised or the gist is rewritten, the next tool install can substitute arbitrary versions or add hostile packages.
- **Evidence:**

```1:12:mise/dev.config.json
{
  "configUrl": "https://gist.githubusercontent.com/bai/d5a4a92350e67af8aba1b9db33d5f077/raw/config.json",
  "defaultOrg": "flywheelsoftware",
  "logLevel": "debug",
  "defaultProvider": "github",
  "baseSearchPath": "~/src",
  "orgToProvider": {
    "flywheelsoftware": "gitlab"
  },
```

- **Impact:** Supply-chain compromise surface: an external party controls the effective `mise` config, the toolchain list, and the trusted-paths allowlist (which grants automatic execution of `mise.toml` files in those directories).
- **Recommendation:**
  1. Pin `configUrl` to a specific gist revision (`/raw/<revision-sha>/config.json`), not `/raw/config.json`.
  2. Better: copy the config contents into this repo (`mise/dev.config.json` itself) and drop the remote fetch entirely.
  3. Audit `trusted_config_paths` — `~/.dev`, `~/src/gitlab.com/bai`, and the two orgs — to confirm each directory is under your explicit control.
- **Effort:** 15 min (inline the config) to 1 hour (full audit + pinning).

---

## MEDIUM

### M1. `./bin` placed **first** in `PATH` — working-directory hijack risk

- **Severity:** MEDIUM
- **Location:** `system/_path.zsh` line `1`
- **Description:** `export PATH="./bin:/usr/local/bin:/usr/local/sbin:$ZSH/bin:$PATH"`. The relative `./bin` appears at the front of `$PATH` in every interactive shell. Any directory you `cd` into that contains a `./bin/git`, `./bin/ls`, `./bin/brew`, etc., will override the system binary. Cloning a hostile repo that ships a `bin/` directory and then running any dev command in it executes attacker code silently.
- **Evidence:**

```1:2:system/_path.zsh
export PATH="./bin:/usr/local/bin:/usr/local/sbin:$ZSH/bin:$PATH"
export MANPATH="/usr/local/man:/usr/local/mysql/man:/usr/local/git/man:$MANPATH"
```

- **Impact:** Silent command hijack when entering any untrusted directory.
- **Recommendation:** Drop `./bin` from `$PATH`, or move it to the end. If a convenience is desired, use a `direnv`-style tool that requires explicit opt-in per directory. Keep `$ZSH/bin` (absolute) at the front — that's fine.
- **Effort:** 5 min.

### M2. `zsh/zshrc.symlink` sources `~/.localrc` with no existence/ownership check

- **Severity:** MEDIUM
- **Location:** `zsh/zshrc.symlink` lines `17-20`
- **Description:** `[[ -a ~/.localrc ]] && source ~/.localrc`. The check `-a` includes symlinks (even broken ones). There is no verification of ownership, permissions, or that the file is a regular file. On a misconfigured multi-user system, any user able to write `~/.localrc` gains full command execution in every shell startup. On a single-user macOS this is academic, but worth noting given the file is documented as the "secrets location" where API keys live.
- **Evidence:**

```14:20:zsh/zshrc.symlink
# Stash your environment variables in ~/.localrc. This means they'll stay out
# of your main dotfiles repository (which may be public, like this one), but
# you'll have access to them in your scripts.
if [[ -a ~/.localrc ]]
then
  source ~/.localrc
fi
```

- **Impact:** Privilege-escalation vector if `$HOME` is ever shared or mis-permissioned. Also: if `~/.localrc` becomes a symlink to an attacker-controlled file, it's sourced without warning.
- **Recommendation:** Add a `[[ -f ~/.localrc && ! -L ~/.localrc && "$(stat -f %u ~/.localrc)" == "$(id -u)" ]]` guard, or at minimum warn if mode is group/other-writable.
- **Effort:** 10 min.

### M3. Unquoted command substitutions in user-facing scripts enable filename-based command injection

- **Severity:** MEDIUM
- **Location:** `functions/extract` lines `9-26`, `bin/mustacheme` lines `38,45`, `bin/movieme` line `27`, `bin/yt` line `9`, `bin/gitio` line `27`, `zsh/aliases.zsh` (`killit`) lines `92-97`
- **Description:** These scripts pass user arguments directly to external tools without quoting or escaping. A filename/URL containing spaces, shell metacharacters, or command substitutions (`$( )`, backticks) can break the tool's argv or inject shell commands. `bin/gitio` specifically interpolates `ARGV[1]` (the `code` arg) into a Ruby backtick string — fully arbitrary command execution by the invoker.
- **Evidence:**

```8:26:functions/extract
extract () {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)  tar -jxvf $1                        ;;
            ...
            *.zip)      unzip $1                            ;;
```

```27:30:bin/gitio
output = `curl -i https://git.io -F 'url=#{url}' #{code} 2> /dev/null`
if output =~ /Location: (.+)\n?/
  puts $1
  `echo #$1 | pbcopy`
```

- **Impact:** Self-inflicted command injection via crafted filenames. Realistic only if you `extract` a file you didn't name yourself (e.g. a download keeping the server-chosen name).
- **Recommendation:** Quote all variable expansions (`"$1"`), use `--` argument separators before file paths, and use Ruby's `Shellwords.escape`/`system()` with an array in `bin/gitio` instead of backticks with interpolation.
- **Effort:** 30 min for the shell scripts; 10 min for `gitio`.

### M4. `bin/cloudapp` stores plaintext email/password in `~/.cloudapp`

- **Severity:** MEDIUM
- **Location:** `bin/cloudapp` lines `17-20,33-41`
- **Description:** The script's documented workflow is to write the CloudApp email and password (newline-separated) to `~/.cloudapp` in plaintext. No Keychain integration, no file-mode enforcement.
- **Evidence:**

```16:41:bin/cloudapp
# Requires you set your CloudApp credentials in ~/.cloudapp as a simple file of:
#
#   email
#   password
...
email,password = File.read(config_file).split("\n")
```

- **Impact:** Credentials readable by any process running as the user, indexed by Spotlight, backed up by Time Machine without encryption unless the disk is encrypted.
- **Recommendation:** Deprecate the script (CloudApp itself is largely defunct); or if still used, migrate to `security` (macOS Keychain) lookups. At minimum, `chmod 600 ~/.cloudapp` on read and verify the mode before using.
- **Effort:** 30 min (Keychain migration), or 1 min (delete the script).

### M5. Predictable `/tmp` paths without `mktemp` — symlink race on shared systems

- **Severity:** MEDIUM
- **Location:** `bin/mustacheme` lines `32-34`, `bin/movieme` lines `21-24`, `opencode/scripts/ollama-start.sh` line `130`, `bin/g` line `11`
- **Description:** Multiple scripts write to fixed `/tmp` paths (`/tmp/mustacheme`, `/tmp/movieme`, `/tmp/ollama-serve.log`, `/tmp/mustache-download.gif`). `bin/g` uses `/tmp/gt_commands_cache_$$` which includes PID so it's harder to predict, but still not atomic. `rm -rf /tmp/movieme && mkdir /tmp/movieme` run in sequence is a classic symlink-attack target if another local user pre-creates `/tmp/movieme` as a symlink to a directory the victim controls.
- **Evidence:**

```20:24:bin/movieme
# cleanup
rm -rf /tmp/movieme

# create tmp dir
mkdir -p /tmp/movieme
```

- **Impact:** Local-user attack only (macOS single-user laptop makes this largely theoretical). On a shared build host it becomes real.
- **Recommendation:** Use `mktemp -d` (or `mktemp -t mustacheme.XXXXXX`) and clean up via `trap`.
- **Effort:** 15 min across all files.

### M6. `homebrew/brew.sh` sudo keep-alive loop outlives expected lifetime

- **Severity:** MEDIUM
- **Location:** `homebrew/brew.sh` lines `6-9`, `macos/set-defaults.sh` lines `14-16`
- **Description:** Both scripts launch a detached `while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done &` to keep sudo validated. The loop exits when the parent dies, but there is a 0-60s window between a `sudo -k` or script crash and the next `kill -0` check. Also, the script never calls `sudo -k` on exit, so the user's sudo cache remains warm long after `brew.sh` finishes.
- **Evidence:**

```5:9:homebrew/brew.sh
# Ask for the administrator password upfront.
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
```

- **Impact:** Window of passive privilege after script exit. Any program that runs during that window gets unprompted sudo.
- **Recommendation:** `trap 'sudo -k' EXIT` at the top of the script. Consider gating the keep-alive loop behind an explicit flag since modern Homebrew doesn't need persistent sudo.
- **Effort:** 5 min.

### M7. `script/bootstrap` interactive prompt silently falls through on unknown input

- **Severity:** MEDIUM
- **Location:** `script/bootstrap` lines `74-93,115-125`
- **Description:** `read -n 1 action` reads a single character. The `case` statement has a wildcard `*) ;;` fall-through with no default action. When the user hits Enter or any unmapped key, `overwrite`/`backup`/`skip` remain unset, so the final branch executes `ln -s "$1" "$2"` unconditionally on top of an existing file. The `ln -s` then fails with `File exists`, but the original file is neither backed up nor confirmed-kept — the user's intent was ambiguous and the script chose the silent-skip path without telling them.
- **Evidence:**

```78:93:script/bootstrap
        case "$action" in
          o ) overwrite=true;;
          O ) overwrite_all=true;;
          b ) backup=true;;
          B ) backup_all=true;;
          s ) skip=true;;
          S ) skip_all=true;;
          * )
            ;;
        esac
```

- **Impact:** On re-run against a pre-populated `$HOME`, an accidental Enter keystroke produces a confusing `File exists` error with no clear path forward. Not a breach vector, but a correctness/usability failure that could be exploited socially.
- **Recommendation:** Replace `*) ;;` with a loop that re-prompts until a valid key is pressed, or default to `skip`.
- **Effort:** 10 min.

### M8. Bootstrap's `link_file` uses unquoted `readlink`

- **Severity:** MEDIUM
- **Location:** `script/bootstrap` line `65`
- **Description:** `local currentSrc="$(readlink $dst)"` — `$dst` is unquoted. If `$HOME` contains whitespace (or if someone ever runs bootstrap against an attacker-chosen home path), `readlink` receives split arguments and the idempotency check breaks.
- **Recommendation:** Quote it: `"$(readlink "$dst")"`.
- **Effort:** 1 min.

### M9. `agents/skills/` contains a broken symlink the agents themselves enumerate

- **Severity:** MEDIUM
- **Location:** `agents/skills/enable-ollama-in-cursor` (symlink), deleted target `agents/my-skills/enable-ollama-in-cursor/`
- **Description:** The symlink still exists and points at a deleted directory. Any agent (Cursor, Claude Code, opencode) that enumerates `~/.cursor/skills/` or `~/.agents/skills/` via the bootstrap symlinks gets a broken entry. Worse, **future agents that tab-complete or fuzzy-match skill names** may route through this broken link. Low severity because the current file deletion is contained, but this is a recurring pattern: `script/bootstrap:link_my_skills()` never removes stale symlinks.
- **Evidence:**

```
lrwxr-xr-x@ agents/skills/enable-ollama-in-cursor -> /Users/stratbarrett/.dotfiles/agents/my-skills/enable-ollama-in-cursor/
(target directory deleted in git working tree)
```

- **Impact:** Agent confusion; also a future surface: if another skill later happens to share the name, the old symlink points to a now-deleted path but the name collision could mask a legitimate replacement.
- **Recommendation:** `rm agents/skills/enable-ollama-in-cursor`, commit the deletion. Add a cleanup step to `link_my_skills()` that prunes symlinks under `agents/skills/` whose targets no longer exist.
- **Effort:** 5 min cleanup; 20 min for the generic prune logic.

---

## LOW

### L1. `.gitignore` is minimal; common secret patterns missing

- **Location:** `.gitignore` lines `1-13`
- **Description:** Only covers `*.local.symlink`, `*.local.zsh`, `*.env`, `*.venv`, `.DS_Store`, `Desktop.ini`, `agents/skills/*`. Nothing for `*.pem`, `*.key`, `*.crt`, `*.p12`, `*.pfx`, `id_rsa*`, `.npmrc`, `credentials*`, `*secret*`, `*.token`. A future `cp ~/.aws/credentials .` would be staged with `git add -A`.
- **Recommendation:** Add at least:

  ```
  *.pem
  *.key
  *.crt
  *.p12
  *.pfx
  id_rsa*
  .npmrc
  credentials*
  *secret*
  *.token
  ```

- **Effort:** 2 min.

### L2. `opencode/*.backup.*` files accumulate untracked in a tracked directory

- **Location:** `opencode/aliases.zsh` lines `37-39`, `opencode/oh-my-opencode.json.backup.20260411_140707`
- **Description:** The new `omod()` function copies `oh-my-opencode.json` to `oh-my-opencode.json.backup.<timestamp>` inside `$DOTFILES/opencode/` on every profile switch. One stranded backup is already present in the working tree. Eventually someone `git add -A`s and commits one, potentially containing a profile the user meant to discard.
- **Recommendation:** Add `opencode/*.backup.*` to `.gitignore`, or redirect backups to `$XDG_STATE_HOME/opencode/backups/`.
- **Effort:** 2 min.

### L3. Hardcoded absolute user paths in tracked config

- **Location:** `zsh/zshrc.symlink` line `59` (via recent diff), `claude/alias.zsh` line `1`
- **Description:** Both files contain `/Users/stratbarrett/.claude/plugins/.../worker-service.cjs` paths. The two locations define conflicting `claude-mem` aliases (one points at the `cache/` hierarchy with an embedded version, the other at `marketplaces/`). Load order determines which wins.
- **Recommendation:** Use `$HOME/.claude/plugins/...`, remove the version from the path, and deduplicate between the two files.
- **Effort:** 10 min.

### L4. `ruby/install.sh` missing shebang and `set -e`

- **Location:** `ruby/install.sh`
- **Description:** No `#!` line, no error handling. Relies on `script/install` forcing `sh -c` execution. Any `brew install` failure is silently ignored.
- **Recommendation:** Add `#!/usr/bin/env bash` and `set -euo pipefail`.
- **Effort:** 2 min.

### L5. `bin/dot` `-n` flag is macOS-specific with no OS guard

- **Location:** `bin/dot` line `45` — `open -a iterm .`
- **Description:** Silently broken on Linux despite the script being marketed as cross-platform.
- **Recommendation:** Wrap in `if [ "$(uname -s)" == "Darwin" ]; then ... else echo "dot -n is macOS-only" >&2; fi`.
- **Effort:** 5 min.

### L6. `bin/dot --start` is broken (calls `--dotfiles` which doesn't exist)

- **Location:** `bin/dot` line `74`
- **Description:** Already documented in `.planning/codebase/CONCERNS.md`. Not a security issue per se but the feature advertised for "new laptop setup" exits with `Invalid option: --dotfiles` before running `--install`/`--brew`/`--macos`. A user following the AGENTS.md recipe for a fresh machine gets a half-setup state that includes only `--sync` via bootstrap.
- **Recommendation:** Replace `"$0" --dotfiles` with `"$0" --sync`.
- **Effort:** 1 min.

### L7. `homebrew/brew.sh` hardcodes Intel `/usr/local` paths

- **Location:** `homebrew/brew.sh` line `20` — `sudo ln -s /usr/local/bin/gsha256sum /usr/local/bin/sha256sum`
- **Description:** On Apple Silicon (`/opt/homebrew`), this `ln` either fails or creates a dangling link. No `set -e`, so the failure is swallowed.
- **Recommendation:** Use `"$(brew --prefix)/bin/gsha256sum"` as source, guard with `[ -f ... ]`.
- **Effort:** 5 min.

### L8. `zsh/aliases.zsh` `alias sudo='sudo '` and `alias update!=...`

- **Location:** `zsh/aliases.zsh` lines `73,68`
- **Description:** `alias sudo='sudo '` is a well-known convenience that also enables alias expansion after `sudo`. Minor: it broadens the alias-attack surface — any alias becomes sudo-runnable. `update!` is functionally broken in zsh (history expansion eats the `!`) but the command it aliases (`sudo softwareupdate -i -a; brew ...`) is safe.
- **Recommendation:** Keep `sudo=sudo ` if the convenience is desired; audit the alias list for anything you wouldn't want to run as root. Rename `update!` to `upgrade` or quote the bang.
- **Effort:** 5 min.

### L9. `bin/g` temp file uses predictable path

- **Location:** `bin/g` line `11` — `CACHE_FILE="/tmp/gt_commands_cache_$$"`
- **Description:** `$$` is the current PID so collisions are unlikely, but `/tmp` is world-writable and a local attacker can pre-create the file as a symlink. The content is only `gt` subcommand names so impact is limited.
- **Recommendation:** `CACHE_FILE="$(mktemp -t gt_commands_cache)"` and `trap 'rm -f "$CACHE_FILE"' EXIT`.
- **Effort:** 5 min.

### L10. `system/keys.zsh` `pubkey` alias uses `more ~/.ssh/id_rsa.pub`

- **Location:** `system/keys.zsh` line `2`
- **Description:** The alias copies the **public** key — safe — but the idiom `more ~/.ssh/id_rsa.pub | pbcopy` is brittle: a typo changing `.pub` to nothing would leak the private key to the clipboard. Modern systems also default to `id_ed25519` rather than `id_rsa`.
- **Recommendation:** Use `pbcopy < ~/.ssh/id_ed25519.pub`, or parameterize the filename. Document that private keys must never be interpolated here.
- **Effort:** 3 min.

---

## INFO

### I1. No pre-commit hook, no automated secret scanning

- **Observation:** No `.pre-commit-config.yaml`, no `.github/workflows/`, no `gitleaks`/`ggshield` integration. Nothing prevents a user from committing a `.env` with a wrong filename or an `install.sh` with an inline API key.
- **Recommendation:** Add a pre-commit hook that runs `gitleaks detect --staged`. Ten minutes of setup, protects indefinitely.

### I2. No SHA pinning of external skills

- **Observation:** `agents/.skill-lock.json` records upstream commit hashes (`skillFolderHash`). Good. However, skills are installed by running an external CLI that trusts the upstream repo at restore time; if upstream is force-pushed or deleted between lock and restore, the hash mismatch is silently skipped.
- **Recommendation:** Already partially handled; a `skills verify` step in `script/bootstrap` would close the loop. (Mirror of M9 but for installed skills, not own skills.)

### I3. `mise` trusted_config_paths grants execution rights to several organizational directories

- **Observation:** `mise/dev.config.json:34-41` lists `~/.dev`, `~/src/gitlab.com/bai`, `~/src/gitlab.com/flywheelsoftware`, and two GitHub org directories as trusted. `mise.toml` files in those directories execute automatically with no prompt. Fine if those directories are under your control; risky if you ever `git clone` a third-party repo into them.
- **Recommendation:** Periodically audit those paths, or narrow them to specific known-good repos.

### I4. CLAUDE.md / AGENTS.md / SKILL.md files are authoritative inputs to AI agents

- **Observation:** These files are documentation for humans AND ingested directly by Claude Code, Cursor, and opencode as system prompts. They currently contain benign guidance, but this repo is also where an attacker would aim a prompt-injection payload: any contributor who can modify these files can instruct every agent on the user's machine to e.g. exfiltrate a file on next invocation. On a single-user repo this is equivalent to "write access to my dotfiles == full takeover" which is already true.
- **Recommendation:** Treat `.md` files under `claude/`, `AGENTS.md`, `agents/commands/`, `agents/prompts/`, and `agents/my-skills/*/SKILL.md` as trusted code. Code-review changes the same way you review `install.sh`.

### I5. `zsh/config.zsh` enables `SHARE_HISTORY` — commands leak across sessions

- **Observation:** `setopt SHARE_HISTORY` means every command you run in one terminal is visible via up-arrow/fc in every other session, including sessions running under `sudo su - <user>` on the same host. Not a confidentiality breach in single-user use; worth noting because `system/aliases.zsh:copy-output` does `eval "$(fc -ln -1)"` which may replay an unexpected command from a different session.
- **Recommendation:** Disable `SHARE_HISTORY` if you don't explicitly need it, or accept the tradeoff.

### I6. Docs may quickly age; some already reference deleted files

- **Observation:** `.planning/codebase/INTEGRATIONS.md:41` references `/Users/stratbarrett/.claude/plugins/cache/thedotmack/claude-mem/12.1.6/scripts/worker-service.cjs` but `claude/alias.zsh:1` points at `.../marketplaces/thedotmack/plugin/scripts/worker-service.cjs`. Documentation already drifted. Not a security issue, but future audits depend on trustworthy docs.

---

## Clean bill of health (areas checked that look good)

- **No real secrets in tracked or untracked files.** Grep swept for API-key formats (`sk-`, `ghp_`, `xox?-`, `AKIA`, AWS access tokens, BEGIN PRIVATE KEY) across the working tree. Only matches were documentation references (e.g., `AGENTS.md`, `claude/CLAUDE.md`) discussing secrets conventionally.
- **No secrets in git history.** `git log --all -p` search for the same patterns returned only documentation about where secrets should go and test values like `"password123"` in skill examples.
- **No URLs with embedded credentials** (`https://user:pass@...` pattern check returned zero hits).
- **No world-writable or suid/sgid files** in the repo.
- **`.git/hooks/` contains no custom hooks** — only the default `.sample` files, so no local hook-injection surface.
- **Git credential helper configuration is sound** — delegates to `gh auth git-credential` + `osxkeychain`, which are the recommended patterns. No stored credentials in tracked config.
- **`git/gitconfig.local.symlink.example`** is a template with `AUTHORNAME`/`AUTHOREMAIL` placeholders — correctly designed to be interpolated at bootstrap into a gitignored file.
- **`.gitignore` correctly excludes** `*.local.*`, `*.env`, `*.venv`, and `agents/skills/*` (installed skills are gitignored so they never leak).
- **Symlink bootstrap is interactive and non-destructive** — `script/bootstrap` prompts before overwriting and backs up to `*.backup` on user confirmation. No silent clobber.
- **Own skill scripts are defensive** — `agents/my-skills/enable-ollama/scripts/*.sh` use `set -euo pipefail`, quote variables, and check for required tools before invoking them.
- **The macOS defaults script (`macos/set-defaults.sh`)** uses `defaults write` + `osascript` against explicit domain/key pairs; no arbitrary code execution path from inputs.
- **AGENTS.md** prohibits committing sensitive data and points users to `~/.localrc`; the convention is at least documented.

---

## Recommended next actions (in priority order)

1. **Fix H1 (Ollama binding).** Change `opencode/ollama.zsh` to default `OLLAMA_HOST=127.0.0.1:11434` and tighten `OLLAMA_ORIGINS`. Highest-impact, 15-minute change.
2. **Fix H2 (opencode autoupdate + unrestricted bash).** Set `"autoupdate": false` in all three opencode configs and pin the `oh-my-opencode` plugin version. Revisit whether every agent needs `bash`.
3. **Fix H4 (remote gist as mise config).** Inline `mise/dev.config.json` contents or pin the gist revision SHA.
4. **Clean up L1 (.gitignore) and L2 (`opencode/*.backup.*`).** Two-minute hygiene wins that prevent future accidents.
5. **Fix M1 (`./bin` in PATH).** Remove the relative entry from `system/_path.zsh`.
6. **Remove the broken symlink (M9)** — `rm agents/skills/enable-ollama-in-cursor` and stage the deletion of `opencode/oh-my-opencode.w-claude.json` that is already pending in git status.
7. **Add a `gitleaks`/`gitleaks-precommit` hook (I1).** Ten-minute setup for durable protection.
8. **Harden H3 (Homebrew install)** by following the upstream canonical `/bin/bash -c "$(curl ...)"` idiom.
9. **Sweep M3 (unquoted arguments).** One-pass quoting audit of `bin/*` and `functions/*`.
10. **Track or delete untracked `opencode/*.json` files.** Either commit the token-tier profiles (they're referenced by `omod()`) or move archived variants to `opencode/profiles/` per CONCERNS.md.

---

_Security audit: 2026-04-21_
