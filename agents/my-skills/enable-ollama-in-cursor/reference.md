# Ollama + Cursor — reference

## Mapping to [the DEV article](https://dev.to/0xkoji/use-local-llm-with-cursor-2h4i)

| Article step                                    | Skill                               |
| ----------------------------------------------- | ----------------------------------- |
| Requirements (Cursor, Ollama, model, **ngrok**) | § Requirements + Path A ngrok check |
| Step 5 — CORS + **ngrok**                       | § 4 `OLLAMA_ORIGINS` + § 5a tunnel  |
| Step 6 — Cursor API key + **ngrok URL + `/v1`** | § 6 (Path A base URL)               |
| Step 7 — **Verify**, only local model selected  | § 6 end                             |
| Step 8 — Chat, pick model                       | § 6 end                             |

The article does **not** use raw `localhost` in Cursor; it uses the **HTTPS forwarding URL** from ngrok. **Path B** (direct `127.0.0.1:11434/v1`) is a common shortcut when both apps are local and it works.

## ngrok command (from the article)

```bash
export OLLAMA_ORIGINS='*'
ngrok http 11434 --host-header="localhost:11434"
```

- `--host-header="localhost:11434"` matches the article so the tunnel preserves host routing Ollama expects.
- Cursor **Base URL** = printed `https://….ngrok…` URL + **`/v1`** (not only `/`).

## Why `/v1`

Ollama’s OpenAI-compatible API lives under `…/v1` (e.g. `/v1/models`, `/v1/chat/completions`).

## Why a fake API key

Clients send `Authorization: Bearer …`. Use any non-empty string; `ollama` matches the article.

## Gemma model names

- **`gemma4`** / **`gemma4:latest`** — [Ollama library `gemma4`](https://ollama.com/library/gemma4).
- **`gemma3:4b`**, **`gemma3:12b`**, etc. — [Ollama library `gemma3`](https://ollama.com/library/gemma3).

Always match the **exact** `id` from `ollama list` / `GET …/v1/models` in Cursor’s model field.
