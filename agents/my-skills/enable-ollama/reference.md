# enable-ollama — reference

## Environment variables

| Variable              | Default                  | Purpose                                                    |
| --------------------- | ------------------------ | ---------------------------------------------------------- |
| `OLLAMA_CURSOR_MODEL` | `gemma4:26b`             | Model name for `ollama pull`. Match `ollama list` exactly. |
| `OLLAMA_HOST`         | `http://127.0.0.1:11434` | Base URL where Ollama listens.                             |
| `OLLAMA_ORIGINS`      | `*`                      | CORS allowed origins. Required for browser/ngrok clients.  |

## macOS-specific notes

- `check-daemon.sh` uses `open -a Ollama` to auto-start the app if the daemon
  isn't responding. This only works on macOS.
- On macOS, `OLLAMA_ORIGINS` can be persisted via `launchctl setenv` for
  GUI-started Ollama processes.
- Ollama.app must be installed in `/Applications/Ollama.app` for auto-start.

## CORS setup persistence

Setting `OLLAMA_ORIGINS='*'` in the shell only affects processes started from
that shell. For Ollama started by the macOS app:

```bash
launchctl setenv OLLAMA_ORIGINS "*"
```

Then restart Ollama.app. This persists across reboots until removed.

## Model name considerations

- Use the **exact** name from `ollama list` in downstream clients.
