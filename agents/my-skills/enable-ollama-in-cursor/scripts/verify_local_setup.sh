#!/usr/bin/env bash
# Verifies Ollama is reachable and OpenAI /v1 works. Optional: pull default model.
set -euo pipefail

MODEL="${OLLAMA_CURSOR_MODEL:-gemma4}"
BASE="${OLLAMA_HOST:-http://127.0.0.1:11434}"
PULL="${OLLAMA_CURSOR_PULL:-1}"

OLLAMA_ORIGINS='*'
export OLLAMA_ORIGINS
# TODO: auto-setup ngrok tunnel and get the base URL

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

command -v ollama >/dev/null 2>&1 || die "ollama not found in PATH; install from https://ollama.com/"

if ! curl -sS --max-time 5 "${BASE}/api/tags" >/dev/null; then
  die "Ollama not responding at ${BASE}. Start the Ollama app or run: ollama serve"
fi

if [[ "$PULL" == "1" ]]; then
  printf 'Pulling model %s (set OLLAMA_CURSOR_PULL=0 to skip)...\n' "$MODEL"
  ollama pull "$MODEL"
fi

printf 'Checking OpenAI-compatible /v1/models at %s...\n' "$BASE"
if ! curl -sS --max-time 10 "${BASE}/v1/models" | head -c 800; then
  die "GET ${BASE}/v1/models failed"
fi

printf '\nOK: Ollama reachable; use base URL %s/v1 in Cursor with model %s\n' "$BASE" "$MODEL"
