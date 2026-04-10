#!/usr/bin/env bash
# Pulls or verifies an Ollama model. Idempotent — skips if already present.
set -euo pipefail

MODEL="${OLLAMA_CURSOR_MODEL:-gemma4:latest}"

# Check if model already exists locally
if ollama list 2>/dev/null | grep -qF "${MODEL%%:*}"; then
  printf 'OK: model %s already pulled\n' "$MODEL"
  exit 0
fi

printf 'Pulling model %s (set OLLAMA_CURSOR_MODEL to override)...\n' "$MODEL"
if ollama pull "$MODEL"; then
  printf 'OK: model %s pulled successfully\n' "$MODEL"
else
  printf 'FAIL: could not pull model %s\n' "$MODEL" >&2
  exit 1
fi
