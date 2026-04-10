#!/usr/bin/env bash
# Checks Ollama daemon is responding. Attempts auto-start on macOS if missing.
set -euo pipefail

BASE="${OLLAMA_HOST:-http://127.0.0.1:11434}"

if curl -sS --max-time 3 "${BASE}/api/tags" >/dev/null 2>&1; then
  printf 'OK: Ollama daemon responding at %s\n' "$BASE"
  exit 0
fi

# Not responding — attempt auto-start on macOS
if [[ "$(uname -s)" == "Darwin" ]] && [[ -d "/Applications/Ollama.app" ]]; then
  printf 'Ollama not responding — starting Ollama.app...\n'
  open -a Ollama
  # Wait up to 15 seconds for daemon
  for i in $(seq 1 15); do
    sleep 1
    if curl -sS --max-time 2 "${BASE}/api/tags" >/dev/null 2>&1; then
      printf 'OK: Ollama daemon started (took %ds)\n' "$i"
      exit 0
    fi
  done
  printf 'FAIL: Ollama started but not responding after 15s\n' >&2
  exit 1
fi

printf 'FAIL: Ollama not responding at %s\n' "$BASE" >&2
printf 'Start the Ollama app or run: ollama serve\n' >&2
exit 1