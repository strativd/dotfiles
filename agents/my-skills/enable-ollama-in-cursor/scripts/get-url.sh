#!/usr/bin/env bash
# Outputs the current Ollama base URL (with /v1) for Cursor configuration.
# For localhost: always returns http://127.0.0.1:11434/v1
# For ngrok: reads from ~/.cursor/ollama-models state file
set -euo pipefail

STATE_FILE="$HOME/.cursor/ollama-models"
LOCALHOST_URL="http://127.0.0.1:11434/v1"

if [[ "${1:-}" == "--ngrok" ]] || [[ -f "$STATE_FILE" ]]; then
  if [[ ! -f "$STATE_FILE" ]]; then
    printf 'FAIL: no ngrok state file at %s\n' "$STATE_FILE" >&2
    printf 'Run start-ngrok.sh first, or use get-url.sh (no args) for localhost\n' >&2
    exit 1
  fi
  BASE_URL=$(grep '^BASE_URL=' "$STATE_FILE" | cut -d= -f2)
  if [[ -z "$BASE_URL" ]]; then
    printf 'FAIL: state file missing BASE_URL\n' >&2
    exit 1
  fi
  printf '%s\n' "$BASE_URL"
else
  printf '%s\n' "$LOCALHOST_URL"
fi