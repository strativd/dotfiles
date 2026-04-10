---
name: enable-ollama-in-cursor
description: Connects a working Ollama instance to Cursor IDE — manages ngrok tunnel lifecycle (start/stop/capture URL) and provides deterministic Cursor GUI configuration instructions. Requires enable-ollama skill run first. Use when Ollama is already running and you need to configure Cursor to use it.
---

# Enable Ollama in Cursor

Connects a running Ollama instance to Cursor IDE. Manages the ngrok tunnel
lifecycle (if needed) and provides exact configuration values for Cursor's
Models UI.

**Prerequisite:** Run the `enable-ollama` skill first to ensure Ollama is
installed, running, and has your model pulled.

## Defaults

| Item                         | Default                       | Notes                                                                 |
| ---------------------------- | ----------------------------- | --------------------------------------------------------------------- |
| `OLLAMA_CURSOR_MODEL`        | `gemma4` (or `gemma4:latest`) | Override with any `ollama list` name.                                |
| Localhost base URL           | `http://127.0.0.1:11434/v1`  | Used when Cursor and Ollama are on the same machine.                  |
| API key in Cursor            | `ollama`                      | Placeholder; any non-empty string works.                              |

## Choose path

| Path                     | When to use                                                                 |
| ------------------------ | --------------------------------------------------------------------------- |
| **A — ngrok tunnel**     | Cursor cannot reach localhost (remote, WSL, Docker) or per the DEV article. |
| **B — Direct localhost** | Cursor and Ollama on the same Mac/PC; `curl :11434` works from shell.      |

---

## Agent workflow

### 0. Prerequisite: ensure Ollama is running

```bash
bash ~/.agents/skills/enable-ollama/scripts/health-check.sh
```

If this fails, run the `enable-ollama` skill first. Do not proceed until
Ollama passes health check.

### 1. Path A — ngrok tunnel

#### 1a. Start tunnel and capture URL

```bash
bash ~/.agents/skills/enable-ollama-in-cursor/scripts/start-ngrok.sh
```

This starts ngrok, captures the HTTPS URL from its local API,
and writes it to `~/.cursor/ollama-models`.

#### 1b. Verify tunneled endpoint

```bash
bash ~/.agents/skills/enable-ollama-in-cursor/scripts/verify-connection.sh --ngrok
```

#### 1c. Get base URL for Cursor

```bash
bash ~/.agents/skills/enable-ollama-in-cursor/scripts/get-url.sh --ngrok
```

### 2. Path B — direct localhost

#### 2a. Verify local endpoint

```bash
bash ~/.agents/skills/enable-ollama-in-cursor/scripts/verify-connection.sh
```

#### 2b. Get base URL for Cursor

```bash
bash ~/.agents/skills/enable-ollama-in-cursor/scripts/get-url.sh
```

Outputs: `http://127.0.0.1:11434/v1`

### 3. Cursor configuration (manual GUI steps)

These steps must be done in Cursor's UI — model config is stored in an
internal SQLite database, not in `settings.json`.

1. Open **Cursor Settings** → **Models**
2. Click **+ Add model** (or equivalent for OpenAI-compatible models)
3. **Model name:** exact string from `ollama list` (e.g. `gemma4` or `gemma4:latest`)
4. **API key:** `ollama` (any non-empty string works)
5. **Base URL:** output of `get-url.sh` from step 1c or 2b
6. Save

**Important:** Before clicking **Verify**, unselect all other models so
only the local Ollama model is active. Then click Verify.

### 4. Cleanup (Path A only)

When done with the ngrok tunnel:

```bash
bash ~/.agents/skills/enable-ollama-in-cursor/scripts/stop-ngrok.sh
```

This kills ngrok and removes `~/.cursor/ollama-models`.

## Script reference

| Script                 | Purpose                                    | Destructive?          |
| ---------------------- | ------------------------------------------ | --------------------- |
| `start-ngrok.sh`      | Start tunnel, capture URL, write state     | Yes (starts ngrok)    |
| `stop-ngrok.sh`       | Kill ngrok, remove state file             | Yes (kills process)   |
| `get-url.sh [--ngrok]`| Output base URL with `/v1`                | No                    |
| `verify-connection.sh`| Probe endpoint, return model list          | No                    |

## Caveats

- If `curl /v1/models` works but Cursor errors ("does not work with your
  current plan or api key"), this is a **Cursor plan/product** limitation —
  see comments on the [DEV post](https://dev.to/0xkoji/use-local-llm-with-cursor-2h4i).
- The ngrok URL changes every time ngrok restarts. Re-run `start-ngrok.sh`
  and update Cursor's base URL after restart.