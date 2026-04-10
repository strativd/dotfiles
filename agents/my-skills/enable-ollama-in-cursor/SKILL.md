---
name: enable-ollama-in-cursor
description: Verifies and fixes local Ollama for Cursor using OpenAI-compatible mode (default model gemma4). Follows the DEV guide path with ngrok plus OLLAMA_ORIGINS, or direct localhost when appropriate. Runs health checks, optional ngrok tunnel, pulls the model, probes /v1, and aligns Cursor Models UI (Verify, single local model). Use when the user wants Ollama in Cursor, local LLM, Gemma, ngrok, or cites the DEV Ollama+Cursor article.
---

# Enable Ollama in Cursor

Primary reference: [Use Local LLM with Cursor and Ollama](https://dev.to/0xkoji/use-local-llm-with-cursor-2h4i)
— that post assumes **ngrok** so Cursor talks to Ollama through an HTTPS tunnel
(not raw `localhost`). This skill implements **both** that flow and a **direct
localhost** shortcut when Cursor and Ollama run on the same machine and
tunneling is unnecessary.

## Defaults

| Item                         | Default                       | Notes                                                                                      |
| ---------------------------- | ----------------------------- | ------------------------------------------------------------------------------------------ |
| `OLLAMA_CURSOR_MODEL`        | `gemma4` (or `gemma4:latest`) | [Ollama library](https://ollama.com/library/gemma4). Override with any `ollama list` name. |
| OpenAI-compat base (local)   | `http://127.0.0.1:11434/v1`   | Trailing **`/v1`** required.                                                               |
| OpenAI-compat base (article) | `https://<ngrok-host>/v1`     | From `ngrok http 11434` forwarding URL + `/v1`.                                            |
| API key in Cursor            | `ollama`                      | Placeholder; Ollama ignores it locally.                                                    |

## Requirements (match the article)

- Cursor installed
- Ollama installed and a model pulled
- **For the DEV article path:** [ngrok](https://ngrok.com/) installed and account
  configured (`ngrok config add-authtoken` or equivalent)

## Choose path

| Path                     | When to use                                                                                                             |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------- |
| **A — Article (ngrok)**  | You want parity with the post, or `localhost` fails from Cursor (some setups).                                          |
| **B — Direct localhost** | Cursor and Ollama on the same Mac/PC; `curl` to `127.0.0.1:11434` works from the shell and chat works without a tunnel. |

---

## Agent workflow (run in order)

### 1. Confirm Ollama CLI

```bash
command -v ollama && ollama --version
```

If missing: [ollama.com](https://ollama.com/) — stop until installed.

### 2. Check Ollama daemon

```bash
curl -sS --max-time 3 http://127.0.0.1:11434/api/tags | head -c 400
```

- **Success**: continue.
- **Failure**: start **Ollama.app** (macOS) or run `ollama serve` (long-running;
  background only if appropriate). Re-run `curl`.

### 3. Pull / confirm model

```bash
MODEL="${OLLAMA_CURSOR_MODEL:-gemma4}"
ollama list | grep -F "${MODEL%%:*}" || true
ollama pull "$MODEL"
```

Use the **exact** name Cursor will send (often `gemma4:latest`); match `ollama list`.

### 4. CORS (`OLLAMA_ORIGINS`) — required for the article; often needed for Cursor generally

The DEV article sets this **before** ngrok:

```bash
# macOS / Linux
export OLLAMA_ORIGINS='*'

# Windows (cmd)
# set OLLAMA_ORIGINS=*
```

If Ollama was started by the GUI app, persist this for the Ollama process
(see [Ollama FAQ / environment](https://github.com/ollama/ollama/blob/main/docs/faq.md))
or restart Ollama after exporting in the shell used to launch it.

### 5a. Path A — ngrok (DEV article steps 5–6)

1. **Verify ngrok** (when following the article):

   ```bash
   command -v ngrok && ngrok version
   ```

   If missing: install from [ngrok.com](https://ngrok.com/) and complete setup (authtoken).

2. **Start tunnel** (same terminal session should already have `OLLAMA_ORIGINS='*'`
   if you restarted Ollama from it; otherwise set env and ensure Ollama sees it):

   ```bash
   ngrok http 11434 --host-header="localhost:11434"
   ```

3. Copy the **HTTPS** forwarding URL (e.g. `https://abcd-123.ngrok-free.app`).
   **Base URL for Cursor:** that URL with **`/v1`** appended — e.g. `https://abcd-123.ngrok-free.app/v1`.

4. **Probe the tunneled API** (replace with real host):

   ```bash
   curl -sS --max-time 10 "https://<ngrok-host>/v1/models" | head -c 600
   ```

   Expect JSON with your model `id`. If this fails, fix ngrok/Ollama before
   editing Cursor.

### 5b. Path B — direct localhost (no ngrok)

```bash
curl -sS --max-time 5 http://127.0.0.1:11434/v1/models | head -c 600
```

**Cursor base URL:** `http://127.0.0.1:11434/v1`

### 6. Cursor configuration (article steps 6–8)

1. **Cursor Settings** → **Models** → add OpenAI-compatible / custom model.
2. **Model name:** exact string from `ollama list` (e.g. `gemma4:latest`).
3. **API key:** `ollama` (article says “Ollama”; any non-empty string is fine).
4. **Base URL:** Path A → `https://<ngrok-host>/v1` · Path B → `http://127.0.0.1:11434/v1`
5. Save.

**Verify (article step 7):** Before **Verify**, **turn off / unselect other models**
so only the local model is active, then click **Verify**.

**Chat (article step 8):** Cmd/Ctrl+L, select the added model, send a prompt.

**Optional `settings.json`:** Only merge `openai.baseUrl` / `openai.apiKey` if
they match the user’s Cursor version and the user wants global JSON; prefer the
Models UI. macOS path: `~/Library/Application Support/Cursor/User/settings.json`.

### 7. Bundled check script (localhost only)

Does **not** start ngrok; it validates local Ollama + optional pull:

```bash
bash ~/.cursor/skills/enable-ollama-in-cursor/scripts/verify_local_setup.sh
```

### 8. Plan / subscription caveats

If `curl /v1/models` works but Cursor errors (“does not work with your current
plan or api key”), treat as **Cursor plan/product** behavior — see comments on
the [same DEV post](https://dev.to/0xkoji/use-local-llm-with-cursor-2h4i).

## Quick checklist

- [ ] `ollama --version` works; daemon responds on `:11434`
- [ ] Model pulled; name matches Cursor
- [ ] `OLLAMA_ORIGINS='*'` applied to the Ollama process when using ngrok orif Cursor hits CORS issues
- [ ] **Path A:** `ngrok` installed; tunnel running; `curl https://<ngrok>/v1/models` OK; Cursor base = that URL + `/v1`
- [ ] **Path B:** `curl http://127.0.0.1:11434/v1/models` OK; Cursor base = `http://127.0.0.1:11434/v1`
- [ ] Cursor **Verify** with only the local model selected

## Additional resources

- [reference.md](reference.md) — ngrok host header, article step mapping
