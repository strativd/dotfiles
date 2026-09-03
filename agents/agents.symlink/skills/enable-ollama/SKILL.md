---
name: enable-ollama
description: Verifies and sets up local Ollama — checks install, starts daemon, pulls model, verifies CORS and OpenAI-compatible endpoint. Client-agnostic; use before any skill that needs a working Ollama (e.g. enable-ollama-in-cursor). Use when the user wants Ollama running locally, needs to troubleshoot Ollama, or before configuring any client to use Ollama.
---

# Enable Ollama

Ensures Ollama is installed, running, has the requested model pulled, CORS
is configured, and the OpenAI-compatible `/v1` endpoint responds.
This skill is **client-agnostic** — it knows nothing about Cursor, VS Code,
or any other consumer.

## Defaults

| Item                  | Default                  | Notes                                 |
| --------------------- | ------------------------ | ------------------------------------- |
| `OLLAMA_CURSOR_MODEL` | `gemma4:26b`             | Override with any `ollama list` name. |
| `OLLAMA_HOST`         | `http://127.0.0.1:11434` | Override if Ollama binds elsewhere.   |
| `OLLAMA_ORIGINS`      | `*`                      | Required for browser/ngrok clients.   |

## Agent workflow (run in order)

### 1. Quick health check (recommended first)

Runs all checks in sequence:

```bash
bash ~/.agents/skills/enable-ollama/scripts/health-check.sh
```

If this passes, Ollama is ready. Skip to step 5 for endpoint URL.

### 2. Individual checks (if health check fails)

Each script exits 0 on success, non-zero on failure:

```bash
# Check ollama CLI installed
bash ~/.agents/skills/enable-ollama/scripts/check-install.sh

# Check daemon responding
bash ~/.agents/skills/enable-ollama/scripts/check-daemon.sh

# Pull/verify model
bash ~/.agents/skills/enable-ollama/scripts/pull-model.sh

# Check CORS configuration
bash ~/.agents/skills/enable-ollama/scripts/check-cors.sh
```

### 3. Fix CORS (if check-cors.sh warns)

```bash
export OLLAMA_ORIGINS='*'
# Then restart Ollama from this shell, or on macOS:
launchctl setenv OLLAMA_ORIGINS "*"
```

### 4. Re-run health check after fixes

```bash
bash ~/.agents/skills/enable-ollama/scripts/health-check.sh
```

### 5. Result: endpoint URL

After health check passes, the Ollama OpenAI-compatible endpoint is:

```bash
${OLLAMA_HOST:-http://127.0.0.1:11434}/v1
```

Use this URL in any OpenAI-compatible client (Cursor, Continue, etc.).

## Script reference

| Script             | Purpose                                      | Destructive?      |
| ------------------ | -------------------------------------------- | ----------------- |
| `check-install.sh` | Verify `ollama` CLI exists                   | No                |
| `check-daemon.sh`  | Verify `:11434` responding, auto-start macOS | Yes (start)       |
| `pull-model.sh`    | Pull model if missing                        | Yes (pull)        |
| `check-cors.sh`    | Check `OLLAMA_ORIGINS=*`                     | No                |
| `health-check.sh`  | End-to-end check (calls all above)           | Yes (daemon+pull) |

All scripts are **idempotent** — safe to run repeatedly.
