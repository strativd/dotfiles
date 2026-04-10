# enable-ollama-in-cursor — reference

## Mapping to [the DEV article](https://dev.to/0xkoji/use-local-llm-with-cursor-2h4i)

| Article step                                    | Skill (new)                                         |
| ----------------------------------------------- | --------------------------------------------------- |
| Requirements (Cursor, Ollama, model)           | `enable-ollama` skill — health-check.sh             |
| Step 1-3 — Install, start, pull model           | `enable-ollama` skill — check-install/daemon/pull   |
| Step 4 — CORS (`OLLAMA_ORIGINS`)                | `enable-ollama` skill — check-cors.sh               |
| Step 5 — CORS + ngrok                           | `enable-ollama-in-cursor` — start-ngrok.sh           |
| Step 6 — Cursor API key + base URL + `/v1`      | `enable-ollama-in-cursor` — get-url.sh + GUI steps   |
| Step 7 — Verify (only local model selected)     | Manual GUI step (documented in SKILL.md §3)         |
| Step 8 — Chat, pick model                       | Manual GUI step                                     |

## State file: `~/.cursor/ollama-models`

Written by `start-ngrok.sh`, read by `get-url.sh --ngrok` and `verify-connection.sh --ngrok`.

```
BASE_URL=https://abcd-123.ngrok-free.app/v1
MODEL=gemma4
STARTED=2026-04-10T18:30:00Z
```

- For localhost: state file is not needed. `get-url.sh` returns
  `http://127.0.0.1:11434/v1` directly.
- State file is co-located with other Cursor config in `~/.cursor/`.

## Why `/v1`

Ollama's OpenAI-compatible API lives under `…/v1` (e.g. `/v1/models`,
`/v1/chat/completions`). All scripts append `/v1` automatically.

## Why a fake API key

Clients send `Authorization: Bearer …`. Use any non-empty string; `ollama`
matches the DEV article convention.

## Why GUI-only for Cursor config

Cursor stores model configuration in `state.vscdb` (SQLite), not
`settings.json`. This is an internal implementation detail, not a public API.
Direct SQLite manipulation would be fragile and break with Cursor updates.

## Gemma model names

- **`gemma4`** / **`gemma4:latest`** — [Ollama library `gemma4`](https://ollama.com/library/gemma4).
- **`gemma3:4b`**, **`gemma3:12b`**, etc. — [Ollama library `gemma3`](https://ollama.com/library/gemma3).

Always match the **exact** `id` from `ollama list` / `GET …/v1/models` in
Cursor's model field.